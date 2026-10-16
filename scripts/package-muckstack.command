#!/bin/bash
# Run in Terminal, which can access the existing MyMan signing Keychain.
set -euo pipefail
cd "$(dirname "$0")/.."
export SIGNING_IDENTITY='Developer ID Application: MuckStack, LLC (K8NAZ76CBQ)'
export APPLE_TEAM_ID=K8NAZ76CBQ
export NOTARY_PROFILE=mumbls-notary
export INSTALLER_FORMAT=dmg
VERSION="$(python3 -c 'import json; print(json.load(open("release/config.json"))["version"])')"
BUILD="$(python3 -c 'import json; print(json.load(open("release/config.json"))["build"])')"
DIST="$PWD/.build/releases/$VERSION"
mkdir -p "$DIST"
printf '{"completed":false}\n' > "$DIST/signing-result.json"
echo "Signing WisprFlowIsDead $VERSION with $SIGNING_IDENTITY"
security find-identity -v -p codesigning | grep -F "\"$SIGNING_IDENTITY\""
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" --output-format json > /dev/null
bash scripts/package-release.sh 2>&1 | tee "$DIST/signing.log"
cp "$DIST/WisprFlowIsDead-$VERSION.dmg" "$HOME/Downloads/WisprFlowIsDead-$VERSION-build$BUILD.dmg"
cp "$DIST/WisprFlowIsDead-$VERSION.zip" "$HOME/Downloads/WisprFlowIsDead-$VERSION-build$BUILD.zip"
printf '{"completed":true,"team":"K8NAZ76CBQ","version":"%s","build":"%s"}\n' "$VERSION" "$BUILD" > "$DIST/signing-result.json"
echo "Signed and notarized installer: $HOME/Downloads/WisprFlowIsDead-$VERSION-build$BUILD.dmg"
echo 'Ready for GitHub release publication; no upload was performed.'
