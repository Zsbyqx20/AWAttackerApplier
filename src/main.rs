mod adb;
mod grpc_service;

use tonic::transport::Server;
use grpc_service::window_info::window_info_service_server::WindowInfoServiceServer;
use grpc_service::accessibility::accessibility_service_server::AccessibilityServiceServer;
use grpc_service::{WindowInfoServiceImpl, AccessibilityServiceImpl};
use std::net::SocketAddr;
use tokio::signal;
use std::sync::Arc;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 初始化日志
    tracing_subscriber::fmt::init();
    
    let addr: SocketAddr = "[::]:50051".parse()?;
    let window_info_service = Arc::new(WindowInfoServiceImpl::new());
    let accessibility_service = Arc::new(AccessibilityServiceImpl::new());
    let service_clone = window_info_service.clone();

    println!("AWAttacker Monitor Server listening on {}", addr);
    println!("Using ADB path: {}", window_info_service.get_adb_path());

    let server = Server::builder()
        .add_service(WindowInfoServiceServer::new(window_info_service))
        .add_service(AccessibilityServiceServer::new(accessibility_service))
        .serve(addr);

    tokio::select! {
        result = server => {
            if let Err(e) = result {
                eprintln!("Server error: {}", e);
            }
        }
        _ = signal::ctrl_c() => {
            println!("Received shutdown signal");
            service_clone.shutdown();
        }
    }

    println!("Server shutting down");
    Ok(())
}
