# =========================
# Stage 1: build rust
# =========================
FROM rust:1.79 AS rust-builder

# 👉 CÀI PROTOC Ở ĐÂY
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ca-certificates \
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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=rust-builder /app/target/release/sshx-server /usr/local/bin/sshx-server

COPY . .
RUN npm install

EXPOSE 5173 8080

CMD sh -c "sshx-server & npm run dev"
