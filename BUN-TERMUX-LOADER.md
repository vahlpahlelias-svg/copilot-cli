# Bun Termux Loader Installer

This repository includes an installer script for [bun-termux-loader](https://github.com/kaan-escober/bun-termux-loader), a tool that enables running Bun applications on Android via Termux.

## What is bun-termux-loader?

Bun-termux-loader is a wrapper that allows you to run Bun (a fast JavaScript runtime) applications on Android devices using Termux. It creates self-contained binaries that can execute Bun apps in the Termux environment.

## Prerequisites

- **Android device** with [Termux](https://termux.dev/) installed
- **Termux** terminal emulator (available from F-Droid)
- Internet connection for downloading dependencies

## Installation

Run the installer script in Termux:

```bash
bash install-bun-termux-loader.sh
```

The installer will:
1. Verify you're running on Termux
2. Install required dependencies (clang, glibc-runner, python, git)
3. Clone the bun-termux-loader repository
4. Build the wrapper binary
5. Compile the BunFS shim for native library support

## Supported Architectures

- **ARM64 (aarch64)**: Modern 64-bit ARM devices
- **ARMv7 (32-bit)**: Older 32-bit ARM devices

## Usage

After installation, navigate to the installation directory and use the build script:

```bash
cd ~/bun-termux-loader
python3 build.py ./your-bun-app
```

This creates a self-contained binary: `./your-bun-app-termux`

## Troubleshooting

### "Error: This script must be run on Termux (Android)"
- Ensure you're running the script in Termux, not in a regular terminal

### "Error: glibc directory not found"
- Make sure glibc-runner is properly installed: `pkg install glibc-runner`

### "Error: Unsupported architecture"
- Your device architecture is not supported. Currently supports ARM64 and ARMv7

### Build failures
- Ensure you have enough storage space
- Try updating Termux packages: `pkg update && pkg upgrade`

## Credits

- Original bun-termux-loader by [kaan-escober](https://github.com/kaan-escober)
- Installer script maintained in this repository

## License

This installer script is provided as-is. Please refer to the [bun-termux-loader repository](https://github.com/kaan-escober/bun-termux-loader) for the license of the actual loader software.
