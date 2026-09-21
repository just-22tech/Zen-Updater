#!/usr/bin/env bash
set -euo pipefail

echo "================================================="
echo "   🚀 Zen Browser (.deb) Auto-Packager (amd64) "
echo "================================================="

# Get latest tag
LATEST_TAG=$(curl -sL -w "%{url_effective}" -o /dev/null https://github.com/zen-browser/desktop/releases/latest | grep -o '[^/]*$')

if [ -z "$LATEST_TAG" ] || [[ "$LATEST_TAG" == *"releases"* ]]; then
    echo "❌ ERROR: Could not fetch the latest repo tag."
    exit 1
fi

VERSION=$LATEST_TAG
TARBALL_URL="https://github.com/zen-browser/desktop/releases/download/${VERSION}/zen.linux-x86_64.tar.xz"

echo "   ✅ Found Version: $VERSION"
echo "   ✅ Download URL: $TARBALL_URL"

DEB_VERSION=$(echo "$VERSION" | sed 's/^v//' | sed 's/[^a-zA-Z0-9.-]//g')
BUILD_DIR="zen-browser-build"
DEB_NAME="zen-browser_${DEB_VERSION}_amd64.deb"
OUTPUT_DIR="/app/output"

echo "=> Preparing Deb build directory structure..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/opt/zen"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/512x512/apps"

echo "=> Generating DEBIAN/control file..."
cat <<CONTROL_EOF > "$BUILD_DIR/DEBIAN/control"
Package: zen-browser
Version: $DEB_VERSION
Architecture: amd64
Maintainer: Auto Builder <builder@localhost>
Description: Private, fast, and honest web browser based on Firefox
Depends: libasound2, libdbus-1-3, libdbus-glib-1-2, libgtk-3-0, libx11-xcb1, libxcomposite1, libxdamage1, libxext6, libxfixes3, libxtst6, libpango-1.0-0, libcairo2, libglib2.0-0, libnss3, libatk1.0-0, libatk-bridge2.0-0, xdg-utils, ca-certificates
CONTROL_EOF

cat << 'POSTINST_EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/sh
set -e
/usr/bin/update-desktop-database -q || true
/usr/bin/gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
exit 0
POSTINST_EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

echo "=> Downloading and extracting the x86_64 Zen Binary..."
curl -L -f --progress-bar "$TARBALL_URL" | tar -xJ -C "$BUILD_DIR/opt/zen" --strip-components=1

ln -sf /opt/zen/zen "$BUILD_DIR/usr/bin/zen"

echo "=> Fetching Metadata and Icon..."
RAW_FLATPAK_URL="https://raw.githubusercontent.com/zen-browser/flatpak/main"
curl -sLf "https://raw.githubusercontent.com/zen-browser/desktop/dev/configs/branding/twilight/logo512.png" -o "$BUILD_DIR/usr/share/icons/hicolor/512x512/apps/zen-browser.png"
curl -sLf "$RAW_FLATPAK_URL/app.zen_browser.zen.desktop" -o "$BUILD_DIR/usr/share/applications/zen.desktop" || true

if [ -f "$BUILD_DIR/usr/share/applications/zen.desktop" ]; then
    sed -i 's|launch-script.sh|/usr/bin/zen|g' "$BUILD_DIR/usr/share/applications/zen.desktop"
    sed -i 's|^Icon=app.zen_browser.zen|Icon=zen-browser|' "$BUILD_DIR/usr/share/applications/zen.desktop"
fi

find "$BUILD_DIR" -type d -exec chmod 755 {} +
find "$BUILD_DIR" -type f -exec chmod ugo+r {} +
chmod +x "$BUILD_DIR/opt/zen/zen" "$BUILD_DIR/opt/zen/zen-bin" 2>/dev/null || true
# chmod 777 "$BUILD_DIR/usr/bin/zen"

echo "=> Packing the final .deb file..."
dpkg-deb -b "$BUILD_DIR" "$OUTPUT_DIR/$DEB_NAME"

echo "Cleaning up..."
rm -rf "$BUILD_DIR"
echo "🎉 SUCCESS: $DEB_NAME is ready in $OUTPUT_DIR!"
