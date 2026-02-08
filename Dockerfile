# =========================
# Stage 1: build rust
# =========================
FROM rust:1.75 AS rust-builder

WORKDIR /app

# Copy toàn bộ source
COPY . .

# Build & install sshx
RUN cargo install --path crates/sshx-core
RUN cargo install --path crates/sshx-server


# =========================
# Stage 2: runtime
# =========================
FROM node:20-bookworm

# Cài các dependency cần thiết cho sshx
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary từ rust stage
COPY --from=rust-builder /usr/local/cargo/bin/sshx-server /usr/local/bin/sshx-server
COPY --from=rust-builder /usr/local/cargo/bin/sshx-core /usr/local/bin/sshx-core

# Copy source frontend
COPY . .

# Cài npm deps
RUN npm install

EXPOSE 5173 8080

# Chạy song song sshx-server + npm dev
CMD sh -c "sshx-server & npm run dev"
