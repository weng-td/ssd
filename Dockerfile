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

# ---- Cache dependency (quan trọng) ----
COPY Cargo.toml ./
COPY crates/sshx-core/Cargo.toml crates/sshx-core/Cargo.toml
COPY crates/sshx-server/Cargo.toml crates/sshx-server/Cargo.toml

RUN cargo fetch

# ---- Copy source ----
COPY . .

# ---- Build ----
RUN cargo build --release -p sshx-server


# =========================
# Stage 2: Runtime siêu nhẹ
# =========================
FROM gcr.io/distroless/cc-debian12

WORKDIR /app

# Copy đúng 1 binary
COPY --from=builder /app/target/release/sshx-server /usr/local/bin/sshx-server

EXPOSE 8051

# Distroless không có shell → exec trực tiếp
ENTRYPOINT ["/usr/local/bin/sshx-server"]
