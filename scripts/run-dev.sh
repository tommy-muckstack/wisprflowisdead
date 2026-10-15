#!/bin/bash
# Build, wrap in a minimal .app (macOS only asks for Microphone and
# Accessibility for a real bundle with usage strings), ad-hoc sign, launch.
# No notarization, no release. Adapted from MyMan's scripts/run-dev.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="WisprFlowIsDead"
BUNDLE_ID="com.muckstack.wisprflowisdead"
CONFIG="${CONFIG:-debug}"
BUILD_DIR=".build/$CONFIG"
APP_DIR=".build/app/$APP_NAME.app"

bash scripts/build-icons.sh
swift build -c "$CONFIG"

pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/"{MacOS,Frameworks,Resources}
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"
for b in "$BUILD_DIR"/*.bundle; do [ -d "$b" ] && cp -R "$b" "$APP_DIR/Contents/Resources/"; done
while IFS= read -r slice; do
    for fw in "$slice"/*.framework; do [ -d "$fw" ] && cp -R "$fw" "$APP_DIR/Contents/Frameworks/"; done
done < <(find .build/artifacts -type d -name "macos-arm64_x86_64" 2>/dev/null)
# App icon: original art in assets/AppIcon-1024.png -> .icns
ICONSET="$(mktemp -d)/AppIcon.iconset"; mkdir -p "$ICONSET"
for sz in 16 32 128 256 512; do
    sips -z $sz $sz assets/AppIcon-1024.png --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
    sips -z $((sz*2)) $((sz*2)) assets/AppIcon-1024.png --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.2</string>
    <key>LSUIElement</key><true/>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>NSAudioCaptureUsageDescription</key>
    <string>Notetaker records what other people say in your calls, on this Mac only, when you start a recording.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>WisprFlowIsDead listens only while you hold your dictation shortcut, and transcribes on this Mac.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>WisprFlowIsDead types your dictation into the app you are using.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR"
[ "${NO_OPEN:-0}" = "1" ] || open "$APP_DIR"
echo "Built $APP_DIR (ad-hoc signed)"
