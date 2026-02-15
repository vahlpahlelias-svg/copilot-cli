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
if ! pkg update -y; then
    echo "Error: Failed to update package repositories. Check your internet connection."
    exit 1
fi
if ! pkg install -y clang glibc-runner python git; then
    echo "Error: Failed to install required dependencies. Check your internet connection and try again."
    exit 1
fi

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
if [ ! -f "Makefile" ]; then
    echo "Error: Makefile not found in $INSTALL_DIR"
    exit 1
fi
if ! make; then
    echo "Error: Build failed. Check the build logs above for details."
    echo "Common solutions:"
    echo "  - Ensure all dependencies are installed"
    echo "  - Check that you have enough disk space"
    echo "  - Report the issue at https://github.com/kaan-escober/bun-termux-loader/issues"
    exit 1
fi

# Build BunFS shim (for native libs support)
echo "[4/4] Building BunFS shim..."
GLIBC=/data/data/com.termux/files/usr/glibc
if [ ! -d "$GLIBC" ]; then
    echo "Error: glibc directory not found at $GLIBC. Ensure glibc-runner is properly installed."
    exit 1
fi

if [ ! -f "bunfs_shim.c" ]; then
    echo "Error: bunfs_shim.c not found in $INSTALL_DIR"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)
        TARGET="aarch64-linux-gnu"
        LINKER="ld-linux-aarch64.so.1"
        ;;
    armv7l|armv8l)
        TARGET="armv7a-linux-gnueabihf"
        LINKER="ld-linux-armhf.so.3"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

if ! clang --target=$TARGET \
    --sysroot=$GLIBC \
    -shared -fPIC -O2 -nostdlib \
    -I$GLIBC/include \
    -L$GLIBC/lib \
    -Wl,--dynamic-linker=$GLIBC/lib/$LINKER \
    -Wl,-rpath,$GLIBC/lib \
    -o bunfs_shim.so bunfs_shim.c -lc -ldl; then
    echo "Error: Failed to compile bunfs_shim.so. Check the error messages above."
    exit 1
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Usage:"
echo "  cd $INSTALL_DIR"
echo "  python3 build.py ./your-bun-app"
echo ""
echo "This creates a self-contained binary: ./your-bun-app-termux"
