# =========================
# Stage 1: build rust
# =========================
FROM rust:1.75 AS rust-builder

WORKDIR /app

COPY . .

# Build sshx-server (sshx-core tự được build theo)
RUN cargo build --release -p sshx-server


# =========================
# Stage 2: runtime
# =========================
FROM node:20-bookworm

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary đã build
COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

# Copy frontend
COPY . .

RUN npm install

EXPOSE 5173 8080

CMD sh -c "sshx-server & npm run dev"
