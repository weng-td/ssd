#!/bin/bash
# Optimized build script for production deployment
# This script builds both frontend and backend with maximum optimization

set -e

echo "🚀 Starting optimized production build..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Clean previous builds
echo -e "${YELLOW}[1/5] Cleaning previous builds...${NC}"
rm -rf build/ target/release/

# 2. Build Rust backend (server + client) with production profile
echo -e "${YELLOW}[2/5] Building Rust binaries (optimized)...${NC}"
export RUSTFLAGS="-C target-cpu=native -C link-arg=-s"
cargo build --profile production --bin sshx-server --bin sshx

# 3. Strip binaries for even smaller size
echo -e "${YELLOW}[3/5] Stripping binaries...${NC}"
if command -v strip &> /dev/null; then
    strip target/production/sshx-server 2>/dev/null || true
    strip target/production/sshx 2>/dev/null || true
fi

# 4. Build frontend with optimizations
echo -e "${YELLOW}[4/5] Building frontend (minified)...${NC}"
npm run build

# 5. Compress static assets
echo -e "${YELLOW}[5/5] Compressing assets...${NC}"
if command -v gzip &> /dev/null; then
    find build -type f \( -name '*.js' -o -name '*.css' -o -name '*.html' \) -exec gzip -9 -k {} \;
    echo "✓ Gzip compression complete"
fi

if command -v brotli &> /dev/null; then
    find build -type f \( -name '*.js' -o -name '*.css' -o -name '*.html' \) -exec brotli -9 -k {} \;
    echo "✓ Brotli compression complete"
fi

# Display sizes
echo ""
echo -e "${GREEN}=== Build Complete! ===${NC}"
echo ""
echo "📦 Binary sizes:"
ls -lh target/production/sshx-server target/production/sshx 2>/dev/null | awk '{print "  " $9 ": " $5}'

echo ""
echo "📁 Frontend size:"
du -sh build/ | awk '{print "  Total: " $1}'

echo ""
echo -e "${GREEN}✓ Production build ready for deployment!${NC}"
echo ""
echo "Next steps:"
echo "  1. Copy target/production/sshx-server to your server"
echo "  2. Copy target/production/sshx to client machines"
echo "  3. Deploy build/ folder to web server (nginx/caddy)"
