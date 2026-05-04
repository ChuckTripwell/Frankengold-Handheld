#!/usr/bin/bash
# Millennium installer/upgrader for Bazzite (immutable OS)
# Works around read-only /usr and /opt by:
#   1. Extracting the tarball directly to ~/.local/
#   2. Patching hardcoded paths in the .so files (/opt, /usr -> /var, same length)
#   3. Using systemd-tmpfiles to create /var/ symlinks on every boot

set -e

MILL_LIB="$HOME/.local/lib/millennium"
MILL_SHARE="$HOME/.local/share/millennium"
PYTHON_DIR="$HOME/.local/opt/python-i686-3.11.8"
STEAM_DIR="$HOME/.steam/steam"
GITHUB_ACCOUNT="SteamClientHomebrew/Millennium"

# ── 1. Fetch latest release tag ───────────────────────────────────────────────
echo "==> Fetching latest Millennium release..."
TAG=$(curl -fsSL "https://api.github.com/repos/${GITHUB_ACCOUNT}/releases" \
    -H 'Accept: application/vnd.github.v3+json' \
    | jq -r '[.[] | select(.prerelease == false)] | first | .tag_name')

if [[ -z "$TAG" || "$TAG" == "null" ]]; then
    echo "ERROR: Could not fetch release info"
    exit 1
fi

VERSION="${TAG#v}"
TARBALL_URL="https://github.com/${GITHUB_ACCOUNT}/releases/download/${TAG}/millennium-v${VERSION}-linux-x86_64.tar.gz"
echo "    Version: $VERSION"

# ── 2. Download and extract to ~/.local/ ──────────────────────────────────────
echo "==> Downloading tarball..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$TARBALL_URL" -o "$TMPDIR/millennium.tar.gz"

echo "==> Extracting to ~/.local/..."
mkdir -p "$MILL_LIB" "$MILL_SHARE" "$PYTHON_DIR"

# Extract to temp dir first, then copy to writable targets
tar -xzf "$TMPDIR/millennium.tar.gz" -C "$TMPDIR" --warning=no-timestamp 2>/dev/null || true

cp -r "$TMPDIR/usr/lib/millennium/."   "$MILL_LIB/"
cp -r "$TMPDIR/usr/share/millennium/." "$MILL_SHARE/"
cp -r "$TMPDIR/opt/python-i686-3.11.8/." "$PYTHON_DIR/"
chmod +x "$PYTHON_DIR/bin/python3.11"

# ── 3. Verify key files ───────────────────────────────────────────────────────
for f in \
    "$MILL_LIB/libmillennium_x86.so" \
    "$MILL_LIB/libmillennium_bootstrap_86x.so" \
    "$PYTHON_DIR/lib/libpython-3.11.8.so" \
    "$PYTHON_DIR/bin/python3.11"
do
    [[ -f "$f" ]] || { echo "ERROR: missing $f"; exit 1; }
done

# ── 4. Patch binaries (same-length string replacement, no relocation needed) ──
# /opt/python-i686-3.11.8  (23 chars) -> /var/python-i686-3.11.8  (23 chars)
# /usr/lib/millennium      (19 chars) -> /var/lib/millennium       (19 chars)
# /usr/share/millennium    (21 chars) -> /var/share/millennium     (21 chars)
echo "==> Patching binaries..."

perl -pi -e '
    s|/opt/python-i686-3\.11\.8|/var/python-i686-3.11.8|g;
    s|/usr/lib/millennium|/var/lib/millennium|g;
    s|/usr/share/millennium|/var/share/millennium|g;
' "$MILL_LIB/libmillennium_x86.so" \
  "$MILL_LIB/libmillennium_bootstrap_86x.so"

echo "    Verified patched paths:"
strings "$MILL_LIB/libmillennium_x86.so" \
    | grep -E "^/var/(python-i686|lib/millennium|share/millennium)" \
    | sed 's/^/      /'

# ── 5. Steam preload symlink ──────────────────────────────────────────────────
echo "==> Installing Steam preload hook..."
ln -sf "$MILL_LIB/libmillennium_bootstrap_86x.so" \
       "$STEAM_DIR/ubuntu12_32/libXtst.so.6"

# ── 6. systemd-tmpfiles for persistent /var/ symlinks ────────────────────────
echo "==> Writing /etc/tmpfiles.d/millennium.conf (requires sudo)..."
sudo tee /etc/tmpfiles.d/millennium.conf > /dev/null << EOF
# Millennium Steam mod framework — Bazzite immutable OS workaround
# Redirects hardcoded /var/ paths (patched from /opt/ and /usr/) to ~/.local installs
L /var/python-i686-3.11.8  -  -  -  -  $HOME/.local/opt/python-i686-3.11.8
L /var/lib/millennium      -  -  -  -  $HOME/.local/lib/millennium
L /var/share/millennium    -  -  -  -  $HOME/.local/share/millennium
EOF

sudo systemd-tmpfiles --create /etc/tmpfiles.d/millennium.conf

echo ""
echo "==> Symlinks:"
ls -la /var/python-i686-3.11.8 /var/lib/millennium /var/share/millennium

echo ""
echo "Done — Millennium $VERSION installed. Restart Steam to load it."
