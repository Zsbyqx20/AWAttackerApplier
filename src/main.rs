mod adb;
mod grpc_service;

use clap::Parser;
use grpc_service::accessibility::accessibility_service_server::AccessibilityServiceServer;
use grpc_service::window_info::window_info_service_server::WindowInfoServiceServer;
use grpc_service::{AccessibilityServiceImpl, WindowInfoServiceImpl};
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::signal;
use tonic::transport::Server;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Host address to bind to
    #[arg(short = 'H', long, default_value = "[::]")]
    host: String,

    /// Port number to listen on
    #[arg(short, long, default_value = "50051")]
    port: u16,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 初始化日志
    tracing_subscriber::fmt::init();

    // 解析命令行参数
    let args = Args::parse();
    let addr: SocketAddr = format!("{}:{}", args.host, args.port).parse()?;

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
