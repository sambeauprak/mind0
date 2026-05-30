#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMG_NAME="Mind0.dmg"
VOLUME_NAME="Mind0"
APP_NAME="Mind0.app"
BUILD_DIR="$PROJECT_DIR/.build"

# Eject any stale mounts from previous runs
for v in "$VOLUME_NAME" "$VOLUME_NAME 1" "$VOLUME_NAME 2" "$VOLUME_NAME 3"; do
    hdiutil detach "/Volumes/$v" 2>/dev/null || true
done

echo "Building Mind0.app (release)..."
cd "$PROJECT_DIR"
swift build -c release

# Locate the built binary
BINARY_PATH="$BUILD_DIR/release/Mind0"
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    exit 1
fi

# Create .app bundle structure
APP_BUNDLE="$BUILD_DIR/$APP_NAME"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/Mind0"

# Copy resources
if [ -d "$PROJECT_DIR/Sources/Mind0/Resources" ]; then
    cp -r "$PROJECT_DIR/Sources/Mind0/Resources/"* "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Mind0</string>
    <key>CFBundleIdentifier</key>
    <string>com.mind0.app</string>
    <key>CFBundleName</key>
    <string>Mind0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>Mind0</string>
</dict>
</plist>
PLIST

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Sign the app (ad-hoc)
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "Creating DMG..."
DMG_STAGE="$BUILD_DIR/dmg-stage"
DMG_TMP="$BUILD_DIR/${DMG_NAME}.tmp"
DMG_FINAL="$PROJECT_DIR/$DMG_NAME"

# Remove old artifacts
rm -rf "$DMG_STAGE" "$DMG_TMP.dmg" "$DMG_FINAL"

# Set up staging directory with the app + Applications symlink
mkdir -p "$DMG_STAGE"
cp -R "$APP_BUNDLE" "$DMG_STAGE/$APP_NAME"
ln -s /Applications "$DMG_STAGE/Applications"

hdiutil create -srcfolder "$DMG_STAGE" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRO \
    -size "$(($(du -sm "$DMG_STAGE" | cut -f1) + 10))M" \
    "$DMG_TMP"

rm -rf "$DMG_STAGE"
hdiutil convert "$DMG_TMP.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -f "$DMG_TMP.dmg"

echo "✅ DMG created: $DMG_FINAL"
