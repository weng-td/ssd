# =========================
# Stage 1: build rust
# =========================
FROM rust:latest AS rust-builder

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN cargo build --release -p sshx-server


# =========================
# Stage 2: runtime
# =========================
FROM node:20-bookworm

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

# Tải cloudflared
RUN curl -L \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

COPY . .
RUN npm install

EXPOSE 5173 8080

# 🚀 Quick tunnel
CMD sh -c "sshx-server & cloudflared tunnel --no-autoupdate --url http://localhost:5173 & npm run dev"
