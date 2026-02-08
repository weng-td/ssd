# =====================================================
# Stage 1: Rust build (sshx-server)
# =====================================================
FROM rust:1.82-slim AS rust-builder

ENV CARGO_HOME=/cargo \
    RUSTUP_HOME=/rustup \
    CARGO_TARGET_DIR=/app/target

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ca-certificates \
    pkg-config \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- Cache Rust deps ----
COPY Cargo.toml ./
COPY crates/sshx-core/Cargo.toml crates/sshx-core/Cargo.toml
COPY crates/sshx-server/Cargo.toml crates/sshx-server/Cargo.toml

RUN cargo fetch

# ---- Copy source ----
COPY . .

# ---- Build ----
RUN cargo build --release -p sshx-server


# =====================================================
# Stage 2: Runtime (Node + sshx + cloudflared)
# =====================================================
FROM node:20-slim

ENV NODE_ENV=development
WORKDIR /app

# ---- System deps ----
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# ---- cloudflared ----
RUN curl -L \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /usr/local/bin/cloudflared \
  && chmod +x /usr/local/bin/cloudflared

# ---- sshx-server binary ----
COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

# ---- Frontend deps (auto detect) ----
COPY package.json ./
COPY package-lock.json* pnpm-lock.yaml* yarn.lock* ./

RUN \
  if [ -f package-lock.json ]; then \
    npm ci --omit=optional --no-audit --no-fund ; \
  elif [ -f pnpm-lock.yaml ]; then \
    npm install -g pnpm && pnpm install --frozen-lockfile ; \
  elif [ -f yarn.lock ]; then \
    yarn install --frozen-lockfile ; \
  else \
    npm install ; \
  fi

# ---- Frontend source ----
COPY . .

# ---- Vite allow all hosts (fix blank screen) ----
ENV VITE_HOST=0.0.0.0

EXPOSE 5173 8051

# =====================================================
# Start all services (song song)
# =====================================================
CMD ["dumb-init", "sh", "-c", "\
  sshx-server --bind 0.0.0.0:8051 & \
  npm run dev -- --host 0.0.0.0 & \
  cloudflared tunnel --no-autoupdate --url http://localhost:5173 \
"]
