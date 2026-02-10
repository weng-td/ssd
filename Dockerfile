# =========================
# Stage 1: Build sshx-server
# =========================
FROM rust:1.83-slim AS rust-builder

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    sudo \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*
RUN sudo apt-get install -y protobuf-compiler libprotobuf-dev --allow-unauthenticated
WORKDIR /app

# ---- Copy toàn bộ workspace (tránh thiếu crate) ----
COPY . .

# ---- Build đúng binary ----
RUN cargo build --release -p sshx-server


# =========================
# Stage 2: Runtime (SIÊU NHẸ)
# =========================
FROM gcr.io/distroless/cc-debian12

WORKDIR /app

COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

EXPOSE 8051

ENTRYPOINT ["/usr/local/bin/sshx-server"]
