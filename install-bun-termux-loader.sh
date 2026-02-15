#!/data/data/com.termux/files/usr/bin/bash
# install-bun-termux-loader.sh
# Simple installer for bun-termux-loader on Termux

set -e

echo "=== Bun Termux Loader Installer ==="
echo ""

# Check if running on Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "Error: This script must be run on Termux (Android)"
    exit 1
fi

# Install dependencies
echo "[1/4] Installing dependencies..."
pkg update -y
pkg install -y clang glibc-runner python git

# Clone repository
echo "[2/4] Cloning bun-termux-loader..."
INSTALL_DIR="$HOME/bun-termux-loader"
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory already exists, updating..."
    cd "$INSTALL_DIR"
    git pull
else
    git clone https://github.com/kaan-escober/bun-termux-loader "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Build wrapper
echo "[3/4] Building wrapper binary..."
make

# Build BunFS shim (for native libs support)
echo "[4/4] Building BunFS shim..."
GLIBC=/data/data/com.termux/files/usr/glibc
clang --target=aarch64-linux-gnu \
    --sysroot=$GLIBC \
    -shared -fPIC -O2 -nostdlib \
    -I$GLIBC/include \
    -L$GLIBC/lib \
    -Wl,--dynamic-linker=$GLIBC/lib/ld-linux-aarch64.so.1 \
    -Wl,-rpath,$GLIBC/lib \
    -o bunfs_shim.so bunfs_shim.c -lc -ldl

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Usage:"
echo "  cd $INSTALL_DIR"
echo "  python3 build.py ./your-bun-app"
echo ""
echo "This creates a self-contained binary: ./your-bun-app-termux"
