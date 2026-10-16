#!/bin/bash
# Verify actual distributed bytes, using Apple's trust checks and Sparkle signatures.
set -euo pipefail
cd "$(dirname "$0")/.."
DIST="${1:?Provide the release directory}"
VERSION="$(python3 -c 'import json; print(json.load(open("release/config.json"))["version"])')"
EXPECTED_TEAM="${APPLE_TEAM_ID:-K8NAZ76CBQ}"
ZIP="$DIST/WisprFlowIsDead-$VERSION.zip"
DMG="$DIST/WisprFlowIsDead-$VERSION.dmg"
STAGING="$(mktemp -d "$PWD/.build/signed-verification.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto -x -k "$ZIP" "$STAGING"
APP="$STAGING/WisprFlowIsDead.app"
python3 qa/verify-native-app.py "$APP"
DETAILS="$(codesign -d --verbose=4 "$APP" 2>&1)"
printf '%s\n' "$DETAILS" | grep -Fx "TeamIdentifier=$EXPECTED_TEAM"
printf '%s\n' "$DETAILS" | grep -E 'flags=.*runtime'
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"
hdiutil verify "$DMG"
codesign --verify --strict "$DMG"
codesign -d --verbose=4 "$DMG" 2>&1 | grep -Fx "TeamIdentifier=$EXPECTED_TEAM"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
swift scripts/verify-release.swift "$DIST"
echo 'Developer ID, notarization, Gatekeeper and Sparkle verification passed.'
