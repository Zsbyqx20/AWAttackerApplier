pub mod adb;
pub mod grpc_service;

pub mod proto {
    pub mod accessibility {
        tonic::include_proto!("accessibility");
    }
    pub mod window_info {
        tonic::include_proto!("window_info");
    }
}