# Contributing to GitHub Copilot CLI

Thank you for your interest in contributing! This repository hosts the installation scripts and documentation for the GitHub Copilot CLI.

## Repository Overview

This is a documentation and distribution repository for GitHub Copilot CLI. The key files are:

| File | Description |
|------|-------------|
| `install.sh` | Main installer for Linux and macOS |
| `install-bun-termux-loader.sh` | Installer for running Bun apps on Android via Termux |
| `README.md` | Getting started guide and installation instructions |
| `BUN-TERMUX-LOADER.md` | Documentation for the Termux/Bun installer |
| `changelog.md` | Release history |
| `.github/workflows/` | Automation workflows |
| `.github/ISSUE_TEMPLATE/` | Templates for bug reports and feature requests |

## How to Contribute

### Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml) to file issues. Include:

- Copilot CLI version (`copilot --version`)
- Operating system and CPU architecture
- Steps to reproduce the issue
- Expected vs. actual behavior

### Requesting Features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml) to suggest improvements.

### Submitting Pull Requests

1. Fork the repository and create a branch from the relevant base branch.
2. Make your changes following the guidelines below.
3. Validate your changes (see [Testing](#testing)).
4. Open a pull request with a clear description of the change and its motivation.

## Contributing to Shell Scripts

The repository contains two installer scripts. Both follow the same conventions.

### Code Style

- Use `#!/usr/bin/env bash` for scripts that must run on standard Linux/macOS systems.
- Use `#!/data/data/com.termux/files/usr/bin/bash` for Termux-specific scripts.
- Always include `set -e` at the top of scripts so they exit on errors.
- Wrap commands in `if ! <command>; then ... exit 1; fi` blocks to provide actionable error messages.
- Quote all variable expansions (`"$VAR"`, `"${VAR}"`).
- Use `[ ... ]` for POSIX-compatible conditionals.

### `install.sh`

This script installs the Copilot CLI binary on Linux and macOS. When making changes:

- Preserve support for both `curl` and `wget` download paths.
- Keep checksum validation logic intact.
- Maintain the `PREFIX` and `VERSION` environment variable overrides.
- Test on both Linux and macOS.

### `install-bun-termux-loader.sh`

This script installs [bun-termux-loader](https://github.com/kaan-escober/bun-termux-loader) on Android devices running Termux. When making changes:

- Preserve the Termux environment check (`/data/data/com.termux`).
- Maintain architecture detection for `aarch64`, `armv7l`, and `armv8l`.
- Ensure error messages include specific remediation steps.
- Test the script on a physical Android device or emulator running Termux, or validate syntax offline (see [Testing](#testing)).

## Testing

### Syntax Validation

Validate shell script syntax without executing the script:

```bash
bash -n install.sh
bash -n install-bun-termux-loader.sh
```

### Linting with ShellCheck

Install [ShellCheck](https://github.com/koalaman/shellcheck) and run it on the scripts:

```bash
shellcheck install.sh
shellcheck install-bun-termux-loader.sh
```

Fix all warnings and errors reported by ShellCheck before submitting a pull request. `shellcheck` can be installed via most package managers:

```bash
# macOS
brew install shellcheck

# Debian/Ubuntu
apt install shellcheck

# Termux
pkg install shellcheck
```

### Manual Testing

For `install.sh`, test in a clean environment:

```bash
# Dry-run: inspect the script output without running it
bash -x install.sh 2>&1 | head -50
```

For `install-bun-termux-loader.sh`, test on an Android device with Termux installed:

```bash
bash install-bun-termux-loader.sh
```

## Documentation

When adding or changing script functionality, update the corresponding documentation:

- Changes to `install.sh` → update `README.md`
- Changes to `install-bun-termux-loader.sh` → update `BUN-TERMUX-LOADER.md`

Keep documentation concise and include practical usage examples.

## License

By contributing, you agree that your contributions will be governed by the repository's [license](LICENSE.md).
