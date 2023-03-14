use std::net::SocketAddr;

use axum::{response::Html, routing::get, Router};

#[tokio::main]
async fn main() {
    println!("Checking that HTTPS is working...");
    println!("-> GET https://google.com");
    let response = reqwest::get("https://google.com").await.unwrap();
    assert!(
        response.status().is_success(),
        "Unsuccessful HTTPS response"
    );
    println!("-> OK");

    // build our application with a route
    let app = Router::new().route("/", get(handler));
    // run it
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("listening on {addr}");

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn handler() -> Html<&'static str> {
    // Force binary to use symbols from the rdkafka and rocksdb libraries.
    let _client = rdkafka::config::ClientConfig::new()
        .create_native_config()
        .unwrap();
    let path = tempfile::tempdir().unwrap();
    let _db = rocksdb::DB::open_default(&path).unwrap();

    Html("<h1>Hello, World!</h1>")
}
