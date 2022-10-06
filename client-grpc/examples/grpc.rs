//! gRPC client implementation

///module svc_storage generated from svc-storage-grpc.proto
// use std::time::SystemTime;
use svc_storage_client_grpc::client::{storage_rpc_client::StorageRpcClient, QueryIsReady};

/// Example svc-storage-client
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // let port = env!("GRPC_PORT");
    let mut client = StorageRpcClient::connect("http://[::1]:50051").await?;
    let request = tonic::Request::new(QueryIsReady {
        // No arguments
    });

    let response = client.is_ready(request).await?;

    println!("RESPONSE={:?}", response.into_inner());

    Ok(())
}
