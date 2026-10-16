#!/bin/bash
# Assemble the same Sparkle-enabled app for development and local distribution.
set -euo pipefail
cd "$(dirname "$0")/.."
APP_NAME="WisprFlowIsDead"
CONFIG="${CONFIG:-release}"
APP_DIR="${APP_DIR:-$PWD/.build/app/$APP_NAME.app}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

bash scripts/build-icons.sh
swift build -c "$CONFIG"
BUILD_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
STAGING="$(mktemp -d "$PWD/.build/bundle.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
STAGED_APP="$STAGING/$APP_NAME.app"
mkdir -p "$STAGED_APP/Contents/"{MacOS,Frameworks,Resources}
cp "$BUILD_DIR/$APP_NAME" "$STAGED_APP/Contents/MacOS/"
for resource in "$BUILD_DIR"/*.bundle; do
  [ ! -d "$resource" ] || ditto "$resource" "$STAGED_APP/Contents/Resources/$(basename "$resource")"
done
while IFS= read -r framework; do
  ditto "$framework" "$STAGED_APP/Contents/Frameworks/$(basename "$framework")"
done < <(find .build/artifacts -type d -name '*.framework' -prune)
test -f "$STAGED_APP/Contents/Frameworks/Sparkle.framework/Sparkle"

ICONSET="$STAGING/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" assets/AppIcon-1024.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z "$((size*2))" "$((size*2))" assets/AppIcon-1024.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
if ! iconutil -c icns "$ICONSET" -o "$STAGED_APP/Contents/Resources/AppIcon.icns"; then
  # Some macOS toolchains reject valid PNG iconsets. Package their existing
  # PNG representations in the documented ICNS container without changing art.
  python3 scripts/write-icns.py "$ICONSET" "$STAGED_APP/Contents/Resources/AppIcon.icns"
fi
if ! otool -l "$STAGED_APP/Contents/MacOS/$APP_NAME" | grep -q '@executable_path/../Frameworks'; then
  install_name_tool -add_rpath '@executable_path/../Frameworks' "$STAGED_APP/Contents/MacOS/$APP_NAME"
fi
python3 scripts/write-app-plist.py "$STAGED_APP/Contents/Info.plist"

# Sign nested helpers before the framework and app. Ad-hoc local builds do not
# enable hardened runtime/library validation; Developer ID builds do.
sign_options=(--force --sign "$SIGNING_IDENTITY")
if [ "$SIGNING_IDENTITY" != "-" ]; then sign_options+=(--timestamp --options runtime); fi
SPARKLE="$STAGED_APP/Contents/Frameworks/Sparkle.framework/Versions/B"
for helper in "$SPARKLE"/XPCServices/*.xpc "$SPARKLE/Updater.app" "$SPARKLE/Autoupdate"; do
  [ ! -e "$helper" ] || codesign "${sign_options[@]}" "$helper"
done
for framework in "$STAGED_APP/Contents/Frameworks/"*.framework; do
  codesign "${sign_options[@]}" "$framework"
done
codesign "${sign_options[@]}" "$STAGED_APP"
codesign --verify --deep --strict "$STAGED_APP"
mkdir -p "$(dirname "$APP_DIR")"
# APP_DIR is generated build output, never an installed app.
case "$APP_DIR" in "$PWD/.build/"*) ;; *) echo 'APP_DIR must be inside this checkout’s .build directory' >&2; exit 1;; esac
rm -rf "$APP_DIR"
mv "$STAGED_APP" "$APP_DIR"
echo "Built $APP_DIR (signing identity: $SIGNING_IDENTITY)"
