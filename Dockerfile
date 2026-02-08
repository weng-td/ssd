# =========================
# Stage 1: Rust build
# =========================
FROM rust:latest AS rust-builder

# Chỉ cài thứ BẮT BUỘC
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- Cache Rust deps (rất quan trọng) ----
COPY Cargo.toml Cargo.lock ./
COPY crates/sshx-core/Cargo.toml crates/sshx-core/
COPY crates/sshx-server/Cargo.toml crates/sshx-server/

RUN cargo fetch

# ---- Copy source ----
COPY . .

# Build đúng binary
RUN cargo build --release -p sshx-server


# =========================
# Stage 2: Runtime (siêu nhẹ)
# =========================
FROM node:20-slim

# Cài cực ít package
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- Copy backend binary ----
COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

# ---- Cloudflared ----
RUN curl -L \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

# ---- Copy FE files ----
COPY . .

# =========================
# AUTO DETECT PACKAGE MANAGER
# =========================
RUN set -eux; \
    if [ -f pnpm-lock.yaml ]; then \
        echo "👉 Using pnpm"; \
        npm install -g pnpm; \
        pnpm install --frozen-lockfile; \
    elif [ -f yarn.lock ]; then \
        echo "👉 Using yarn"; \
        yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then \
        echo "👉 Using npm ci"; \
        npm ci --omit=optional --no-audit --no-fund; \
    else \
        echo "👉 Using npm install"; \
        npm install --omit=optional --no-audit --no-fund; \
    fi

# =========================
# ENV – GIẢM RAM TỐI ĐA
# =========================
ENV NODE_ENV=development
ENV NODE_OPTIONS="--max-old-space-size=384"
ENV VITE_SSR=false
ENV VITE_HMR_PORT=443

EXPOSE 5173 8051

# =========================
# RUN – nhẹ nhất có thể
# =========================
CMD sh -c "\
  sshx-server & \
  cloudflared tunnel --no-autoupdate --url http://localhost:5173 & \
  npm run dev -- --host 0.0.0.0 --clearScreen=false \
"
