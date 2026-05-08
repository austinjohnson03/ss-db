use sqlx::PgPool;
use sqlx::postgres::PgPoolOptions;
use std::time::Duration;

#[derive(Debug)]
pub struct Client {
    pub pool: PgPool,
}

impl Client {
    pub async fn new(config: &Config) -> Self {
        let mut retries = 5;
        let pool = loop {
            match PgPoolOptions::new()
                .max_connections(config.max_connections)
                .acquire_timeout(config.acquire_timeout_in_secs())
                .connect(&config.to_connection_string())
                .await
            {
                Ok(pool) => break pool,
                Err(e) => {
                    if retries == 0 {
                        panic!("Failed to connect to database after retries: {}", e);
                    }
                    tracing::warn!("DB not ready, retrying in 5s... ({} retries left)", retries);
                    retries -= 1;
                    tokio::time::sleep(Duration::from_secs(5)).await;
                }
            }
        };

        Client { pool }
    }

    pub async fn ping(&self) -> bool {
        sqlx::query("SELECT 1").execute(&self.pool).await.is_ok()
    }
}

#[derive(Debug)]
pub struct Config {
    pub name: String,
    pub user: String,
    pub password: String,
    pub host: String,
    pub port: u16,
    pub max_connections: u32,
    pub timeout: u64,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            name: std::env::var("DB_NAME").expect("DB_NAME not set"),
            user: std::env::var("DB_USER").expect("DB_USER not set"),
            password: std::env::var("DB_PASSWORD").expect("DB_PASSWORD not set"),
            host: std::env::var("DB_HOST").expect("DB_HOST not set"),
            port: std::env::var("DB_PORT")
                .unwrap_or_else(|_| "5432".to_string())
                .parse()
                .expect("DB_PORT must be a number"),
            max_connections: std::env::var("DB_MAX_CONNECTIONS")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .expect("DB_MAX_CONNECTIONS must be a number"),
            timeout: std::env::var("DB_TIMEOUT")
                .unwrap_or_else(|_| "30".to_string())
                .parse()
                .expect("DB_TIMEOUT must be a number"),
        }
    }

    pub fn to_connection_string(&self) -> String {
        format!(
            "postgres://{}:{}@{}:{}/{}",
            self.user, self.password, self.host, self.port, self.name
        )
    }

    pub fn acquire_timeout_in_secs(&self) -> Duration {
        Duration::from_secs(self.timeout)
    }
}
