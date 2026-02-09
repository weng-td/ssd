# Makefile for Remote Terminal - Optimized Build System
# Works on Windows (with make), Linux, and macOS

.PHONY: help build run clean install test dev production optimize size-check analyze quick build-all

# Default target
help:
	@echo "Remote Terminal - Build Commands"
	@echo ""
	@echo "Development:"
	@echo "  make dev          - Run development server"
	@echo "  make quick        - Quick build for testing"
	@echo ""
	@echo "Production:"
	@echo "  make production   - Optimized production build"
	@echo "  make optimize     - Production + compression"
	@echo "  make build-all    - Cross-compile for all platforms"
	@echo ""
	@echo "Analysis:"
	@echo "  make analyze      - Analyze bundle size"
	@echo "  make size-check   - Check build sizes"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make test         - Run tests"
	@echo "  make install      - Install to system"
	@echo ""

# Build release binary
build:
	@echo "Building release binary..."
	cargo build --release
	@echo "Done! Binary at: ./target/release/sshx-server"

# Build and run
run: build
	@echo "Starting server..."
ifeq ($(OS),Windows_NT)
	powershell -ExecutionPolicy Bypass -File start-server.ps1
else
	chmod +x start-server.sh
	./start-server.sh
endif

# Development mode
dev:
	@echo "Starting development server..."
	npm run dev &
	cargo run --bin sshx-server -- --listen 0.0.0.0 --port 8051

# Production build (optimized)
production:
	@echo "Building for production (optimized)..."
	@echo "This may take a while..."
	npm run build:prod
	cargo build --profile production --bin sshx-server --bin sshx
	@echo "Stripping binaries..."
	@strip target/production/sshx-server 2>/dev/null || true
	@strip target/production/sshx 2>/dev/null || true
	@echo "✓ Production build complete!"
	@make size-check

# Optimize everything (production + compression)
optimize: production
	@echo "Compressing assets..."
	@find build -type f \( -name '*.js' -o -name '*.css' -o -name '*.html' \) -exec gzip -9 -k {} \; 2>/dev/null || true
	@echo "✓ Optimization complete!"

# Check sizes
size-check:
	@echo ""
	@echo "=== Build Sizes ==="
	@echo "Frontend:"
	@du -sh build/ 2>/dev/null || echo "  Not built"
	@echo ""
	@echo "Backend:"
	@ls -lh target/production/sshx-server 2>/dev/null | awk '{print "  Server: " $$5}' || echo "  Server: Not built"
	@ls -lh target/production/sshx 2>/dev/null | awk '{print "  Client: " $$5}' || echo "  Client: Not built"
	@echo ""

# Analyze bundle
analyze:
	@echo "Building and analyzing bundle..."
	npm run build:analyze

# Quick build (for testing)
quick:
	@echo "Quick build (dev mode)..."
	npm run build
	cargo build --release --bin sshx-server --bin sshx

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/ target/ build_artifacts/ node_modules/.vite
	cargo clean
	@echo "Done!"

# Install to system (Linux/macOS only)
install: production
ifeq ($(OS),Windows_NT)
	@echo "Install not supported on Windows. Use the binary directly."
else
	@echo "Installing to /usr/local/bin..."
	sudo cp target/production/sshx-server /usr/local/bin/
	sudo chmod +x /usr/local/bin/sshx-server
	@echo "Done! Run with: sshx-server"
endif

# Run tests
test:
	@echo "Running tests..."
	cargo test
	npm run check

# Cross-compile for all platforms (Linux host required)
build-all:
	chmod +x build-all.sh
	./build-all.sh

# Build optimized for VPS
build-vps:
	@echo "Building optimized for low-resource VPS..."
	RUSTFLAGS="-C target-cpu=native" cargo build --profile production
	@echo "Done! Binary size:"
ifeq ($(OS),Windows_NT)
	@powershell -Command "Get-Item target\\production\\sshx-server.exe | Select-Object Length"
else
	@ls -lh target/production/sshx-server | awk '{print $$5}'
endif
