#!/bin/bash
# Package the checked-in imagegen masters at the sizes consumed by the site/app.
set -euo pipefail
cd "$(dirname "$0")/.."
WEB="site/wisprflowisdead/assets"
NATIVE="Sources/WisprFlowIsDead/Resources/Branding"
mkdir -p "$NATIVE"
cp assets/AppIcon-1024.png "$WEB/icon.png"
cp assets/AppIcon-1024.png "$NATIVE/AppIcon.png"
cp assets/Tombstone-512.png "$WEB/tombstone.png"
cp assets/Tombstone-512.png "$NATIVE/Tombstone.png"
sips -z 64 64 assets/AppIcon-1024.png --out "$WEB/favicon.png" >/dev/null
sips -z 180 180 assets/AppIcon-1024.png --out "$WEB/apple-touch-icon.png" >/dev/null
