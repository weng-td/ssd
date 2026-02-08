# =========================
# Stage 1: Rust build (nặng nhưng chỉ build 1 lần)
# =========================
FROM rust:latest AS rust-builder

# Cài đúng thứ cần, không dư
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 👉 Copy Cargo trước để cache dependency (RẤT QUAN TRỌNG)
COPY Cargo.toml Cargo.lock ./
COPY crates/sshx-core/Cargo.toml crates/sshx-core/
COPY crates/sshx-server/Cargo.toml crates/sshx-server/

RUN cargo fetch

# 👉 Copy source sau (đổi code frontend không rebuild Rust)
COPY . .

# Build đúng binary cần
RUN cargo build --release -p sshx-server


# =========================
# Stage 2: Runtime nhẹ
# =========================
FROM node:20-slim

# Cài rất ít package
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary Rust (rất nhẹ)
COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

# Tải cloudflared (binary đơn)
RUN curl -L \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

# Copy package.json trước để cache npm
COPY package.json package-lock.json ./
RUN npm ci --omit=optional --no-audit --no-fund

# Copy frontend source sau
COPY . .

# ⚠️ Giảm tải dev server
ENV NODE_ENV=development
ENV VITE_SSR=false
ENV VITE_HMR_PORT=443

EXPOSE 5173 8051

# 🚀 Chạy 3 process – nhẹ nhất có thể
CMD sh -c "\
  sshx-server & \
  cloudflared tunnel --no-autoupdate --url http://localhost:5173 & \
  npm run dev -- --host 0.0.0.0 \
"
