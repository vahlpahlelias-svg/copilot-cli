#!/usr/bin/env bats
# Tests for install.sh
#
# Requirements: bats-core (https://github.com/bats-core/bats-core)
# Run from the repository root: /tmp/bats-core/bin/bats tests/install.bats

INSTALL_SCRIPT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)/install.sh"

# ─── Helpers ──────────────────────────────────────────────────────────────────

# Create a minimal valid tarball containing a 'copilot' executable.
make_tarball() {
  local dest="$1"
  local tmp
  tmp="$(mktemp -d)"
  printf '#!/bin/sh\necho "copilot stub"\n' > "$tmp/copilot"
  chmod +x "$tmp/copilot"
  /usr/bin/tar -czf "$dest" -C "$tmp" copilot
  /usr/bin/rm -rf "$tmp"
}

# Write a shim script to $MOCK_BIN/<name>.
# Uses 'rm -f' first so that existing symlinks do not cause "permission denied"
# when the redirect tries to follow the symlink to a root-owned target.
write_mock() {
  local name="$1"; shift
  rm -f "$MOCK_BIN/$name"
  { printf '#!/bin/sh\n'; printf '%s\n' "$@"; } > "$MOCK_BIN/$name"
  chmod +x "$MOCK_BIN/$name"
}

# Write the default curl mock that serves $TARBALL_PATH for tarball downloads
# and writes a dummy file for SHA256SUMS requests.
# Optional second argument controls SHA256SUMS behavior:
#   "fail"    – curl exits 1 for checksums (CHECKSUMS_AVAILABLE stays false)
#   "corrupt" – curl writes garbage as the tarball (triggers tarball validation error)
# Default: serve the real tarball and a dummy checksums file.
write_curl_mock() {
  local tp="$1"
  local variant="${2:-normal}"
  rm -f "$MOCK_BIN/curl"
  case "$variant" in
    fail)
      # Succeed for the tarball, fail for the checksums download.
      cat > "$MOCK_BIN/curl" << MOCK
#!/bin/sh
out=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    -o) out="\$2"; shift 2 ;;
    *)  shift ;;
  esac
done
[ -z "\$out" ] && exit 0
case "\$out" in
  *SHA256SUMS*) exit 1 ;;
  *) /usr/bin/cp "$tp" "\$out" ;;
esac
MOCK
      ;;
    corrupt)
      # Write garbage as the tarball; write a dummy checksums file.
      cat > "$MOCK_BIN/curl" << MOCK
#!/bin/sh
out=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    -o) out="\$2"; shift 2 ;;
    *)  shift ;;
  esac
done
[ -z "\$out" ] && exit 0
case "\$out" in
  *SHA256SUMS*) echo dummy > "\$out" ;;
  *) echo "not a tarball" > "\$out" ;;
esac
MOCK
      ;;
    *)
      # Normal: serve the real tarball and a dummy checksums file.
      cat > "$MOCK_BIN/curl" << MOCK
#!/bin/sh
out=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    -o) out="\$2"; shift 2 ;;
    *)  shift ;;
  esac
done
[ -z "\$out" ] && exit 0
case "\$out" in
  *SHA256SUMS*) echo dummy > "\$out" ;;
  *) /usr/bin/cp "$tp" "\$out" ;;
esac
MOCK
      ;;
  esac
  chmod +x "$MOCK_BIN/curl"
}

# Write the default wget mock (same semantics as the curl mock normal variant).
write_wget_mock() {
  local tp="$1"
  rm -f "$MOCK_BIN/wget"
  # wget is called as: wget -qO <file> <url>  ($1=-qO, $2=file, $3=url)
  cat > "$MOCK_BIN/wget" << MOCK
#!/bin/sh
out="\$2"
[ -z "\$out" ] && exit 0
case "\$out" in
  *SHA256SUMS*) echo dummy > "\$out" ;;
  *) /usr/bin/cp "$tp" "\$out" ;;
esac
MOCK
  chmod +x "$MOCK_BIN/wget"
}

# Run install.sh under the mock environment.
# Reads VERSION from the current shell scope (set per-test as needed).
run_install() {
  run setsid env \
    HOME="$FAKE_HOME" \
    PREFIX="$FAKE_PREFIX" \
    PATH="$MOCK_BIN" \
    VERSION="${VERSION:-}" \
    bash "$INSTALL_SCRIPT"
}

# Run install.sh without a PREFIX override (tests default prefix logic).
run_install_no_prefix() {
  run setsid env \
    HOME="$FAKE_HOME" \
    PATH="$MOCK_BIN" \
    VERSION="${VERSION:-}" \
    bash "$INSTALL_SCRIPT"
}

# ─── Setup / teardown ─────────────────────────────────────────────────────────

setup() {
  MOCK_BIN="$(mktemp -d)"
  FAKE_HOME="$(mktemp -d)"
  FAKE_PREFIX="$(mktemp -d)"
  TARBALL_PATH="$MOCK_BIN/fake.tar.gz"

  # Symlink real system utilities so they are available under our restricted PATH.
  # gzip must be present because GNU tar shells out to it for .tar.gz operations.
  for cmd in bash cp gzip mktemp mkdir chmod rm basename awk tail setsid; do
    ln -sf "$(which "$cmd")" "$MOCK_BIN/$cmd"
  done
  # tar: write as a thin wrapper script (not a symlink) to avoid chmod errors
  # when tests need to overwrite it later.
  printf '#!/bin/sh\n/usr/bin/tar "$@"\n' > "$MOCK_BIN/tar"
  chmod +x "$MOCK_BIN/tar"

  # Create a valid fake tarball used by the curl/wget mocks.
  make_tarball "$TARBALL_PATH"

  # uname: default Linux x86_64
  write_mock "uname" \
    'case "$1" in' \
    '  -s) echo "Linux" ;;' \
    '  -m) echo "x86_64" ;;' \
    '  *) /usr/bin/uname "$@" ;;' \
    'esac'

  # id: default non-root (uid 1000)
  write_mock "id" 'echo "1000"'

  # curl: copies the fake tarball or writes a dummy checksums file.
  write_curl_mock "$TARBALL_PATH"

  # sha256sum: succeeds for checksum validation (-c flag); delegates to the
  # real binary for all other invocations (e.g., during tarball creation).
  write_mock "sha256sum" \
    'case "$1" in' \
    '  -c) exit 0 ;;' \
    '  *) /usr/bin/sha256sum "$@" ;;' \
    'esac'

  # shasum: always succeeds
  write_mock "shasum" 'exit 0'

  # git: mocks "ls-remote --tags" for prerelease version detection
  write_mock "git" \
    'case "$1 $2" in' \
    '  "ls-remote --tags") printf "abc123\trefs/tags/v2.5.0\n" ;;' \
    '  *) /usr/bin/git "$@" ;;' \
    'esac'

  # copilot stub: present by default so that "command -v copilot" succeeds,
  # which skips the interactive PATH-notice section in most tests.
  # Tests that specifically exercise the PATH-notice path remove this stub.
  printf '#!/bin/sh\necho "stub"\n' > "$MOCK_BIN/copilot"
  chmod +x "$MOCK_BIN/copilot"
}

teardown() {
  /usr/bin/rm -rf "$MOCK_BIN" "$FAKE_HOME" "$FAKE_PREFIX"
}

# ─── Platform detection ───────────────────────────────────────────────────────

@test "platform: Linux is detected and used in the download URL" {
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"linux"* ]]
}

@test "platform: Darwin is detected and used in the download URL" {
  write_mock "uname" \
    'case "$1" in -s) echo "Darwin" ;; -m) echo "x86_64" ;; *) /usr/bin/uname "$@" ;; esac'
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"darwin"* ]]
}

@test "platform: Windows with winget prints message and exits 0" {
  write_mock "uname" \
    'case "$1" in -s) echo "CYGWIN_NT-10.0" ;; -m) echo "x86_64" ;; esac'
  write_mock "winget" 'echo "winget install called"; exit 0'
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"Windows detected"* ]]
}

@test "platform: Windows without winget exits 1 with error message" {
  write_mock "uname" \
    'case "$1" in -s) echo "CYGWIN_NT-10.0" ;; -m) echo "x86_64" ;; esac'
  # winget absent from MOCK_BIN → command -v winget fails
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"winget not found"* ]]
}

# ─── Architecture detection ───────────────────────────────────────────────────

@test "arch: x86_64 maps to x64 in download URL" {
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"x64"* ]]
}

@test "arch: amd64 maps to x64 in download URL" {
  write_mock "uname" \
    'case "$1" in -s) echo "Linux" ;; -m) echo "amd64" ;; esac'
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"x64"* ]]
}

@test "arch: aarch64 maps to arm64 in download URL" {
  write_mock "uname" \
    'case "$1" in -s) echo "Linux" ;; -m) echo "aarch64" ;; esac'
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"arm64"* ]]
}

@test "arch: arm64 maps to arm64 in download URL" {
  write_mock "uname" \
    'case "$1" in -s) echo "Linux" ;; -m) echo "arm64" ;; esac'
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"arm64"* ]]
}

@test "arch: unsupported architecture exits 1 with error message" {
  write_mock "uname" \
    'case "$1" in -s) echo "Linux" ;; -m) echo "mips64" ;; esac'
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported architecture"* ]]
}

# ─── Version / URL handling ───────────────────────────────────────────────────

@test "version: empty VERSION uses /releases/latest/ URL" {
  VERSION=""
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"/releases/latest/"* ]]
}

@test "version: VERSION=latest uses /releases/latest/ URL" {
  VERSION="latest"
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"/releases/latest/"* ]]
}

@test "version: VERSION=prerelease resolves tag via git ls-remote" {
  VERSION="prerelease"
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"v2.5.0"* ]]
}

@test "version: VERSION=prerelease without git exits 1" {
  rm -f "$MOCK_BIN/git"
  VERSION="prerelease"
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"git is required"* ]]
}

@test "version: VERSION=prerelease with git returning no tags exits 1" {
  write_mock "git" \
    'case "$1 $2" in "ls-remote --tags") echo "" ;; *) /usr/bin/git "$@" ;; esac'
  VERSION="prerelease"
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not determine prerelease version"* ]]
}

@test "version: numeric VERSION gets v-prefix added to download URL" {
  VERSION="1.2.3"
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"/download/v1.2.3/"* ]]
}

@test "version: already v-prefixed VERSION is not double-prefixed" {
  VERSION="v1.2.3"
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"/download/v1.2.3/"* ]]
  [[ "$output" != *"/download/vv1.2.3/"* ]]
}

# ─── Download tool selection ──────────────────────────────────────────────────

@test "download: curl is used when available" {
  run_install
  [ "$status" -eq 0 ]
  # Success indicates curl was used (wget not in MOCK_BIN)
}

@test "download: wget is used when curl is absent" {
  rm -f "$MOCK_BIN/curl"
  write_wget_mock "$TARBALL_PATH"
  run_install
  [ "$status" -eq 0 ]
}

@test "download: exits 1 with error when neither curl nor wget is available" {
  rm -f "$MOCK_BIN/curl"
  # wget also absent
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Neither curl nor wget found"* ]]
}

# ─── Checksum validation ──────────────────────────────────────────────────────

@test "checksum: validated successfully with sha256sum" {
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓ Checksum validated"* ]]
}

@test "checksum: exits 1 when sha256sum reports mismatch" {
  write_mock "sha256sum" \
    'case "$1" in' \
    '  -c) exit 1 ;;' \
    '  *) /usr/bin/sha256sum "$@" ;;' \
    'esac'
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Checksum validation failed"* ]]
}

@test "checksum: falls back to shasum when sha256sum is absent" {
  rm -f "$MOCK_BIN/sha256sum"
  # shasum mock is already set up to succeed in setup()
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓ Checksum validated"* ]]
}

@test "checksum: exits 1 when shasum reports mismatch" {
  rm -f "$MOCK_BIN/sha256sum"
  write_mock "shasum" 'exit 1'
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Checksum validation failed"* ]]
}

@test "checksum: warns and continues when neither sha256sum nor shasum is available" {
  rm -f "$MOCK_BIN/sha256sum"
  rm -f "$MOCK_BIN/shasum"
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"No sha256sum or shasum found"* ]]
}

@test "checksum: skips validation when checksums file download fails" {
  # curl: succeeds for the tarball download but fails for the checksums download.
  write_curl_mock "$TARBALL_PATH" "fail"
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" != *"Checksum validated"* ]]
}

# ─── Tarball validation ───────────────────────────────────────────────────────

@test "tarball: exits 1 with error when downloaded file is not a valid tarball" {
  # curl: writes garbage instead of a real tarball.
  write_curl_mock "$TARBALL_PATH" "corrupt"
  run_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a valid tarball"* ]]
}

# ─── Installation directory ───────────────────────────────────────────────────

@test "install dir: non-root installs to HOME/.local/bin" {
  # Run without PREFIX so the script uses the default non-root path.
  run_install_no_prefix
  [ "$status" -eq 0 ]
  [ -f "$FAKE_HOME/.local/bin/copilot" ]
}

@test "install dir: non-root install message references HOME/.local/bin" {
  run_install_no_prefix
  [ "$status" -eq 0 ]
  [[ "$output" == *"$FAKE_HOME/.local/bin"* ]]
}

@test "install dir: root defaults to /usr/local/bin (shown in output)" {
  write_mock "id" 'echo "0"'
  # mkdir will fail for /usr/local/bin (not actually root); the error message
  # must still mention /usr/local/bin, confirming the correct prefix was chosen.
  run_install_no_prefix
  [[ "$output" == *"/usr/local/bin"* ]]
}

@test "install dir: custom PREFIX is respected" {
  run_install
  [ "$status" -eq 0 ]
  [ -f "$FAKE_PREFIX/bin/copilot" ]
}

@test "install dir: exits 1 with error when directory cannot be created" {
  local readonly_dir
  readonly_dir="$(mktemp -d)"
  chmod 555 "$readonly_dir"
  run setsid env \
    HOME="$FAKE_HOME" \
    PREFIX="$readonly_dir/no-perms" \
    PATH="$MOCK_BIN" \
    VERSION="" \
    bash "$INSTALL_SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not create directory"* ]]
  chmod 755 "$readonly_dir"
  rm -rf "$readonly_dir"
}

@test "install dir: prints success message with install path after install" {
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓ GitHub Copilot CLI installed to"* ]]
}

@test "install dir: prints notice when replacing an existing binary" {
  mkdir -p "$FAKE_PREFIX/bin"
  echo "old binary stub" > "$FAKE_PREFIX/bin/copilot"
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"Notice: Replacing copilot binary"* ]]
}

# ─── PATH check ───────────────────────────────────────────────────────────────

@test "PATH: prints notice when install dir is not in PATH" {
  # Remove the copilot stub so "command -v copilot" fails and the PATH section runs.
  rm -f "$MOCK_BIN/copilot"
  # setsid ensures /dev/tty is inaccessible, so the interactive read returns
  # immediately and the script does not block.
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"not in your PATH"* ]]
}

@test "PATH: no PATH notice when copilot binary is already accessible" {
  # copilot stub is present in MOCK_BIN by default (see setup).
  run_install
  [ "$status" -eq 0 ]
  [[ "$output" != *"not in your PATH"* ]]
}

@test "PATH: non-interactive mode prints manual export instruction" {
  rm -f "$MOCK_BIN/copilot"
  # Run without stdin attached to a tty and with /dev/tty inaccessible (setsid),
  # so the script takes the non-interactive else-branch.
  run_install
  [ "$status" -eq 0 ]
  # Either the prompt or the manual export instruction should appear.
  [[ "$output" == *"PATH"* ]]
}
