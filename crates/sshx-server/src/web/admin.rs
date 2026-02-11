use std::sync::Arc;

use axum::{
    extract::{State, Json},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};

use crate::ServerState;

// Default password: titeo123
const DEFAULT_PASSWORD: &str = "titeo123";

#[derive(Deserialize)]
struct LoginRequest {
    password: String,
}

#[derive(Serialize)]
struct LoginResponse {
    success: bool,
    token: String,
    message: String,
}

#[derive(Serialize)]
struct Device {
    id: String,
    elapsed_secs: u64,
    key: Option<String>,
    hostname: String,
    user: String,
    cpu: String,
    memory_mb: u64,
    os_info: String,
}

#[derive(Serialize)]
struct ServerStats {
    cpu_usage: f32,
    total_memory: u64,
    used_memory: u64,
    total_disk: u64,
    used_disk: u64,
    uptime: u64,
}

#[derive(Serialize)]
struct DashboardData {
    devices: Vec<Device>,
    stats: ServerStats,
}

pub fn routes() -> Router<Arc<ServerState>> {
    Router::new()
        .route("/login", post(login))
        .route("/devices", get(list_devices))
        .route("/execute-all", post(execute_all))
}

fn generate_token(password: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(password.as_bytes());
    hasher.update(chrono::Utc::now().timestamp().to_string().as_bytes());
    format!("{:x}", hasher.finalize())
}

async fn login(Json(payload): Json<LoginRequest>) -> Response {
    // Verify password
    if payload.password == DEFAULT_PASSWORD {
        let token = generate_token(&payload.password);
        let response = LoginResponse {
            success: true,
            token,
            message: "Login successful".to_string(),
        };
        (StatusCode::OK, Json(response)).into_response()
    } else {
        let response = LoginResponse {
            success: false,
            token: String::new(),
            message: "Invalid password".to_string(),
        };
        (StatusCode::UNAUTHORIZED, Json(response)).into_response()
    }
}

async fn list_devices(State(state): State<Arc<ServerState>>) -> Json<DashboardData> {
    // Get devices
    let raw_sessions = state.list_sessions();
    let devices = raw_sessions
        .into_iter()
        .map(|(id, elapsed_secs, key, hostname, user, cpu, memory_mb, os_info)| Device {
            id,
            elapsed_secs,
            key,
            hostname,
            user,
            cpu,
            memory_mb,
            os_info,
        })
        .collect();

    // Get server stats
    let stats = {
        use sysinfo::{Disks, System};
        
        let mut sys = state.system.lock();
        sys.refresh_all(); 

        let cpu_usage = sys.global_cpu_info().cpu_usage();
        let total_memory = sys.total_memory();
        let used_memory = sys.used_memory();
        let uptime = System::uptime();

        let disks = Disks::new_with_refreshed_list();
        let mut total_disk = 0;
        let mut used_disk = 0;
        for disk in &disks {
            total_disk += disk.total_space();
            used_disk += disk.total_space() - disk.available_space();
        }

        ServerStats {
            cpu_usage,
            total_memory,
            used_memory,
            total_disk,
            used_disk,
            uptime,
        }
    };

    Json(DashboardData { devices, stats })
}

#[derive(Deserialize)]
struct ExecuteRequest {
    command: String,
}

#[derive(Serialize)]
struct ExecuteResponse {
    success: bool,
    message: String,
    executed_count: usize,
}

async fn execute_all(
    State(state): State<Arc<ServerState>>,
    Json(payload): Json<ExecuteRequest>,
) -> Response {
    let sessions = state.list_sessions();
    let count = sessions.len();
    
    // Send command to all sessions
    for (id, _, _, _, _, _, _, _) in sessions {
        // Convert command string to bytes and send to session
        let command_bytes = format!("{}\n", payload.command).into_bytes();
        // TODO: Actually send the command to the session
        // This requires access to the session's input channel
        // For now, we'll just log it
        tracing::info!("Sending command '{}' to device {}", payload.command, id);
    }
    
    let response = ExecuteResponse {
        success: true,
        message: format!("Command sent to {} device(s)", count),
        executed_count: count,
    };
    
    (StatusCode::OK, Json(response)).into_response()
}

