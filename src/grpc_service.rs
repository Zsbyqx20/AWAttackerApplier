use std::collections::HashMap;
use tokio::time::timeout;
use tonic::{Request, Response, Status};
use std::sync::Arc;
use tokio::sync::{oneshot, RwLock, broadcast, mpsc};
use std::time::Duration;
use tokio_stream::StreamExt;
use tokio_stream::wrappers::ReceiverStream;
use futures::Stream;
use std::pin::Pin;

use crate::adb::AdbCommand;

pub mod window_info {
    tonic::include_proto!("window_info");
}

pub mod accessibility {
    tonic::include_proto!("accessibility");
}

use window_info::window_info_service_server::WindowInfoService;
use window_info::{WindowInfoRequest, WindowInfoResponse, WindowInfoSource, ResponseType};

use accessibility::accessibility_service_server::AccessibilityService;
use accessibility::{GetAccessibilityTreeRequest, GetAccessibilityTreeResponse};
use accessibility::{UpdateAccessibilityDataRequest, UpdateAccessibilityDataResponse};
use accessibility::{ServerCommand, ClientResponse};

type AccessibilityStream = Pin<Box<dyn Stream<Item = Result<ServerCommand, Status>> + Send + 'static>>;

#[derive(Debug)]
struct StreamInfo {
    command_sender: mpsc::Sender<ServerCommand>,
    #[allow(dead_code)]
    device_id: String,
}

#[derive(Debug)]
pub struct AccessibilityServiceImpl {
    pending_requests: Arc<RwLock<HashMap<String, oneshot::Sender<Vec<u8>>>>>,
    streams: Arc<RwLock<HashMap<String, StreamInfo>>>,
    adb: AdbCommand,
}

impl AccessibilityServiceImpl {
    pub fn new() -> Self {
        Self {
            pending_requests: Arc::new(RwLock::new(HashMap::new())),
            streams: Arc::new(RwLock::new(HashMap::new())),
            adb: AdbCommand::default(),
        }
    }

    pub async fn handle_accessibility_data_update(&self, device_id: String, data: Vec<u8>) {
        println!("Updating accessibility data for device {}: {} bytes", device_id, data.len());
        
        // Get the sender from pending_requests
        let sender = {
            let mut requests = self.pending_requests.write().await;
            requests.remove(&device_id)
        };
        
        // If there's a pending request, send the data
        if let Some(tx) = sender {
            if tx.send(data).is_err() {
                println!("Failed to send data to receiver - receiver dropped");
            }
        } else {
            println!("No pending request found for device {}", device_id);
        }
    }

    async fn send_command(&self, device_id: String) -> Result<(), Status> {
        let streams = self.streams.read().await;
        if let Some(stream_info) = streams.get(&device_id) {
            let command = ServerCommand {
                device_id: device_id.clone(),
                command: accessibility::server_command::CommandType::GetAccessibilityTree as i32,
            };
            
            if let Err(e) = stream_info.command_sender.send(command).await {
                println!("Failed to send command: {}", e);
                return Err(Status::internal("Failed to send command"));
            }
        } else {
            println!("No stream found for device {}", device_id);
            return Err(Status::not_found("Device not connected"));
        }
        Ok(())
    }

    async fn get_single_device(&self) -> Result<String, Status> {
        match self.adb.get_connected_devices() {
            Ok(devices) => {
                if devices.is_empty() {
                    return Err(Status::failed_precondition("No devices connected"));
                }
                if devices.len() > 1 {
                    return Err(Status::failed_precondition("Multiple devices connected, please specify device ID"));
                }
                Ok(devices[0].clone())
            }
            Err(e) => Err(Status::internal(format!("Failed to get device list: {}", e))),
        }
    }
}

#[derive(Debug, Clone)]
pub struct WindowInfoServiceImpl {
    adb: AdbCommand,
    shutdown_tx: broadcast::Sender<()>,
}

impl WindowInfoServiceImpl {
    pub fn new() -> Self {
        let (shutdown_tx, _) = broadcast::channel(1);
        Self {
            adb: AdbCommand::default(),
            shutdown_tx,
        }
    }

    pub fn get_adb_path(&self) -> String {
        self.adb.get_path()
    }

    pub fn shutdown(&self) {
        let _ = self.shutdown_tx.send(());
    }
}

#[tonic::async_trait]
impl AccessibilityService for Arc<AccessibilityServiceImpl> {
    type StreamAccessibilityStream = AccessibilityStream;

    async fn stream_accessibility(
        &self,
        request: Request<tonic::Streaming<ClientResponse>>,
    ) -> Result<Response<Self::StreamAccessibilityStream>, Status> {
        println!("New streaming connection established");
        
        // 获取当前连接的设备
        let device_id = self.get_single_device().await?;
        println!("Using device: {}", device_id);
        
        let mut stream = request.into_inner();
        let (command_tx, command_rx) = mpsc::channel(32);
        let streams = self.streams.clone();
        
        // 立即保存流信息
        {
            let stream_info = StreamInfo {
                command_sender: command_tx.clone(),
                device_id: device_id.clone(),
            };
            let mut streams = streams.write().await;
            streams.insert(device_id.clone(), stream_info);
            println!("✅ 已保存设备 {} 的流信息", device_id);
        }
        
        // 启动一个任务来处理接收到的响应
        let service = self.clone();
        let device_id_clone = device_id.clone();
        tokio::spawn(async move {
            while let Some(result) = stream.next().await {
                match result {
                    Ok(response) => {
                        // 处理心跳消息
                        if response.device_id == "heartbeat" {
                            println!("💓 收到心跳");
                            continue;
                        }
     
                        if response.success {
                            service.handle_accessibility_data_update(
                                response.device_id,
                                response.raw_output,
                            ).await;
                        } else {
                            println!("Received error response: {}", response.error_message);
                        }
                    }
                    Err(e) => {
                        println!("Error receiving response: {}", e);
                        break;
                    }
                }
            }
            println!("Client stream ended");
            // 清理连接
            let mut streams = streams.write().await;
            streams.remove(&device_id_clone);
            println!("🗑️ 已清理设备 {} 的流信息", device_id_clone);
        });

        // 创建发送命令的流，将 ServerCommand 包装在 Result 中
        let output_stream = ReceiverStream::new(command_rx)
            .map(Ok::<_, Status>);
        Ok(Response::new(Box::pin(output_stream) as Self::StreamAccessibilityStream))
    }

    async fn get_accessibility_tree(
        &self,
        request: Request<GetAccessibilityTreeRequest>,
    ) -> Result<Response<GetAccessibilityTreeResponse>, Status> {
        let request = request.into_inner();
        let device_id = request.device_id.clone();
        
        println!("Getting accessibility tree for device: {}", device_id);
        
        // Create a oneshot channel for receiving the response
        let (tx, rx) = oneshot::channel();
        
        // Store the sender in pending_requests
        {
            let mut requests = self.pending_requests.write().await;
            requests.insert(device_id.clone(), tx);
        }

        // Send command through stream
        if let Err(e) = self.send_command(device_id.clone()).await {
            println!("Failed to send command: {}", e);
            return Ok(Response::new(GetAccessibilityTreeResponse {
                success: false,
                error_message: e.to_string(),
                raw_output: Vec::new(),
                tree: None,
            }));
        }
        
        // Wait for response with timeout
        match timeout(Duration::from_secs(5), rx).await {
            Ok(Ok(raw_output)) => {
                println!("Successfully received accessibility data: {} bytes", raw_output.len());
                Ok(Response::new(GetAccessibilityTreeResponse {
                    success: true,
                    error_message: String::new(),
                    raw_output,
                    tree: None,
                }))
            }
            Ok(Err(_)) => {
                println!("Channel closed before receiving response");
                Ok(Response::new(GetAccessibilityTreeResponse {
                    success: false,
                    error_message: "Failed to get response from Flutter client".to_string(),
                    raw_output: Vec::new(),
                    tree: None,
                }))
            }
            Err(_) => {
                println!("Timeout waiting for Flutter client response");
                // Clean up the pending request
                let mut requests = self.pending_requests.write().await;
                requests.remove(&device_id);
                
                Ok(Response::new(GetAccessibilityTreeResponse {
                    success: false,
                    error_message: "Timeout waiting for Flutter client response".to_string(),
                    raw_output: Vec::new(),
                    tree: None,
                }))
            }
        }
    }

    async fn update_accessibility_data(
        &self,
        request: Request<UpdateAccessibilityDataRequest>,
    ) -> Result<Response<UpdateAccessibilityDataResponse>, Status> {
        let request = request.into_inner();
        println!("Received update_accessibility_data request for device: {}", request.device_id);
        
        self.handle_accessibility_data_update(request.device_id, request.raw_output).await;
        
        Ok(Response::new(UpdateAccessibilityDataResponse {
            success: true,
            error_message: String::new(),
        }))
    }
}

#[tonic::async_trait]
impl WindowInfoService for Arc<WindowInfoServiceImpl> {
    async fn get_current_window_info(
        &self,
        request: Request<WindowInfoRequest>,
    ) -> Result<Response<WindowInfoResponse>, Status> {
        println!("Received get_current_window_info request: {:?}", request);
        
        let device_id = request.into_inner().device_id;
        println!("Processing request for device: {}", device_id);

        match self.adb.get_current_activity(&device_id) {
            Ok((package_name, activity_name)) => {
                println!("Successfully got activity info: {}/{}", package_name, activity_name);
                Ok(Response::new(WindowInfoResponse {
                    package_name,
                    activity_name,
                    timestamp: chrono::Utc::now().timestamp_millis(),
                    source: WindowInfoSource::PcAdb as i32,
                    success: true,
                    error_message: String::new(),
                    r#type: ResponseType::WindowInfo as i32,
                }))
            }
            Err(e) => {
                println!("Failed to get activity info: {}", e);
                Ok(Response::new(WindowInfoResponse {
                    package_name: String::new(),
                    activity_name: String::new(),
                    timestamp: chrono::Utc::now().timestamp_millis(),
                    source: WindowInfoSource::PcAdb as i32,
                    success: false,
                    error_message: e.to_string(),
                    r#type: ResponseType::WindowInfo as i32,
                }))
            }
        }
    }
} 