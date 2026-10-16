#!/bin/bash
# Build a local installer and cryptographically signed Sparkle feed. No upload.
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="$(python3 -c 'import json; print(json.load(open("release/config.json"))["version"])')"
DIST="$PWD/.build/releases/$VERSION"
APP_DIR="$PWD/.build/app/WisprFlowIsDead.app"
UPDATE_KEY_FILE="${UPDATE_KEY_FILE:-$HOME/Library/Application Support/WisprFlowIsDead/Signing/update-ed25519.key}"
test -f "$UPDATE_KEY_FILE" || { echo "Set UPDATE_KEY_FILE to the protected Sparkle signing key file." >&2; exit 1; }
CONFIG=release bash scripts/build-app.sh
mkdir -p "$DIST"
if [ -n "${NOTARY_PROFILE:-}" ]; then
  [ "${SIGNING_IDENTITY:--}" != "-" ] || { echo 'Notarization requires SIGNING_IDENTITY.' >&2; exit 1; }
  ditto -c -k --keepParent "$APP_DIR" "$DIST/notarize.zip"
  xcrun notarytool submit "$DIST/notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_DIR"
fi
ZIP="$DIST/WisprFlowIsDead-$VERSION.zip"
PKG="$DIST/WisprFlowIsDead-$VERSION.pkg"
ditto -c -k --keepParent "$APP_DIR" "$ZIP"
STAGING="$(mktemp -d "$PWD/.build/pkg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP_DIR" "$STAGING/WisprFlowIsDead.app"
pkgbuild --analyze --root "$STAGING" "$DIST/components.plist"
python3 - "$DIST/components.plist" <<'PY'
import plistlib, sys
path = sys.argv[1]
with open(path, 'rb') as file:
    components = plistlib.load(file)
for component in components:
    component['BundleIsRelocatable'] = False
with open(path, 'wb') as file:
    plistlib.dump(components, file)
PY
pkg_options=(--root "$STAGING" --component-plist "$DIST/components.plist" --install-location /Applications --identifier com.muckstack.wisprflowisdead --version "$VERSION")
if [ -n "${INSTALLER_IDENTITY:-}" ]; then pkg_options+=(--sign "$INSTALLER_IDENTITY"); fi
pkgbuild "${pkg_options[@]}" "$PKG"
if [ -n "${NOTARY_PROFILE:-}" ]; then
  [ -n "${INSTALLER_IDENTITY:-}" ] || { echo 'Notarizing a PKG requires INSTALLER_IDENTITY.' >&2; exit 1; }
  xcrun notarytool submit "$PKG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$PKG"
fi
SIGN_UPDATE="$(find .build/artifacts -path '*/bin/sign_update' -type f -print -quit)"
test -x "$SIGN_UPDATE"
SIGNATURE="$("$SIGN_UPDATE" --ed-key-file "$UPDATE_KEY_FILE" -p "$ZIP")"
"$SIGN_UPDATE" --ed-key-file "$UPDATE_KEY_FILE" --verify "$ZIP" "$SIGNATURE"
python3 scripts/write-appcast.py "$ZIP" "$SIGNATURE" "$DIST/appcast.xml"
"$SIGN_UPDATE" --ed-key-file "$UPDATE_KEY_FILE" "$DIST/appcast.xml"
"$SIGN_UPDATE" --ed-key-file "$UPDATE_KEY_FILE" --verify "$DIST/appcast.xml"
(cd "$DIST"; shasum -a 256 "$(basename "$ZIP")" "$(basename "$PKG")" > SHA256SUMS)
echo "Installer: $PKG"
echo "Signed feed: $DIST/appcast.xml"
