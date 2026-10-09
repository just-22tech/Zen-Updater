#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "  Zen Browser .deb Packager (amd64)"
echo "==========================================="

if [ -z "${ZEN_VERSION:-}" ]; then
    echo "ERROR: ZEN_VERSION is not set." >&2
    exit 1
fi

VERSION="$ZEN_VERSION"
DEB_VERSION="${VERSION#v}"
DEB_VERSION="${DEB_VERSION//[^a-zA-Z0-9.-]/}"
DEB_NAME="zen-browser_${DEB_VERSION}_amd64.deb"
BUILD_DIR="zen-browser-build"
OUTPUT_DIR="/app/output"
TARBALL_URL="https://github.com/zen-browser/desktop/releases/download/${VERSION}/zen.linux-x86_64.tar.xz"

echo "  Version:  $VERSION"
echo "  Download: $TARBALL_URL"

echo "=> Setting up build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"/{DEBIAN,opt/zen,usr/bin,usr/share/applications,usr/share/icons/hicolor/512x512/apps}

cat > "$BUILD_DIR/DEBIAN/control" <<EOF
Package: zen-browser
Version: $DEB_VERSION
Architecture: amd64
Maintainer: Zen Updater <noreply@localhost>
Description: Private, fast, and honest web browser based on Firefox
Depends: libasound2, libdbus-1-3, libdbus-glib-1-2, libgtk-3-0, libx11-xcb1, libxcomposite1, libxdamage1, libxext6, libxfixes3, libxtst6, libpango-1.0-0, libcairo2, libglib2.0-0, libnss3, libatk1.0-0, libatk-bridge2.0-0, xdg-utils, ca-certificates
EOF

cat > "$BUILD_DIR/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
/usr/bin/update-desktop-database -q || true
/usr/bin/gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
exit 0
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

echo "=> Downloading Zen Browser binary..."
curl -L -f --progress-bar "$TARBALL_URL" | tar -xJ -C "$BUILD_DIR/opt/zen" --strip-components=1

ln -sf /opt/zen/zen "$BUILD_DIR/usr/bin/zen"

echo "=> Fetching icon and desktop entry..."
curl -sLf "https://raw.githubusercontent.com/zen-browser/desktop/dev/configs/branding/twilight/logo512.png" \
    -o "$BUILD_DIR/usr/share/icons/hicolor/512x512/apps/zen-browser.png"

curl -sLf "https://raw.githubusercontent.com/zen-browser/flatpak/main/app.zen_browser.zen.desktop" \
    -o "$BUILD_DIR/usr/share/applications/zen.desktop" || true

if [ -f "$BUILD_DIR/usr/share/applications/zen.desktop" ]; then
    sed -i 's|launch-script.sh|/usr/bin/zen|g' "$BUILD_DIR/usr/share/applications/zen.desktop"
    sed -i 's|^Icon=app.zen_browser.zen|Icon=zen-browser|' "$BUILD_DIR/usr/share/applications/zen.desktop"
fi

find "$BUILD_DIR" -type d -exec chmod 755 {} +
find "$BUILD_DIR" -type f -exec chmod ugo+r {} +
chmod +x "$BUILD_DIR/opt/zen/zen" "$BUILD_DIR/opt/zen/zen-bin" 2>/dev/null || true

echo "=> Building .deb package..."
dpkg-deb -b "$BUILD_DIR" "$OUTPUT_DIR/$DEB_NAME"

rm -rf "$BUILD_DIR"
echo "Done: $DEB_NAME"
