use ss_db::client::{Client, Config};

#[tokio::main]
async fn main() {
    let db_client = Client::new(&Config::from_env()).await;
    db_client.ping().await;
}
