# =========================
# Stage 1: Rust build
# =========================
FROM rust:1.82-slim AS rust-builder

# Chỉ cài thứ BẮT BUỘC
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- Cache Rust deps (rất quan trọng) ----
COPY Cargo.toml ./
COPY crates/sshx-core/Cargo.toml crates/sshx-core/Cargo.toml
COPY crates/sshx-server/Cargo.toml crates/sshx-server/Cargo.toml

# ⚠️ BẮT BUỘC: copy src để Cargo thấy target
COPY crates/sshx-core/src crates/sshx-core/src
COPY crates/sshx-server/src crates/sshx-server/src

RUN cargo fetch

# ---- Copy source còn lại (proto, config, etc.) ----
COPY . .

# Build đúng binary
RUN cargo build --release -p sshx-server


# =========================
# Stage 2: Runtime (SIÊU NHẸ)
# =========================
FROM gcr.io/distroless/cc-debian12

WORKDIR /app

# ---- Copy backend binary ----
COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

EXPOSE 8051

# Chỉ chạy server, không process nào khác
ENTRYPOINT ["/usr/local/bin/sshx-server"]
