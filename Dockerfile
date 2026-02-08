# =========================
# Stage 1: Build sshx-server
# =========================
FROM rust:1.82-slim AS builder

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- Workspace manifest ----
COPY Cargo.toml ./

# ---- Crate manifests ----
COPY crates/sshx-core/Cargo.toml crates/sshx-core/Cargo.toml
COPY crates/sshx-server/Cargo.toml crates/sshx-server/Cargo.toml

# ---- ⚠️ BẮT BUỘC: copy src để Cargo thấy target ----
COPY crates/sshx-core/src crates/sshx-core/src
COPY crates/sshx-server/src crates/sshx-server/src

# ---- Fetch deps (KHÔNG lỗi) ----
RUN cargo fetch

# ---- Copy phần còn lại (proto, config, etc.) ----
COPY . .

# ---- Build ----
RUN cargo build --release -p sshx-server


# =========================
# Stage 2: Runtime siêu nhẹ
# =========================
FROM gcr.io/distroless/cc-debian12

WORKDIR /app

COPY --from=builder /app/target/release/sshx-server /usr/local/bin/sshx-server

EXPOSE 8051

ENTRYPOINT ["/usr/local/bin/sshx-server"]
