#!/bin/bash
# Pull theme tokens and the wisprflow fonts from the shared IsDead design
# system (github.com/tommy-muckstack/isdead-design). The app ships TTF
# copies of the same families (CoreText loads TTF everywhere).
set -euo pipefail
cd "$(dirname "$0")/.."
DESIGN="${ISDEAD_DESIGN:-../isdead-design}"
cp "$DESIGN/swift/IsDeadTokens.swift" Sources/IsDeadDesign/IsDeadTokens.swift
cp "$DESIGN"/fonts/wisprflow/OFL-*.txt Sources/WisprFlowIsDead/Resources/Fonts/
cp "$DESIGN/css/wisprflow.css" site/wisprflowisdead/assets/isdead-wisprflow.css
cp "$DESIGN"/fonts/wisprflow/*.woff2 site/wisprflowisdead/assets/fonts/
echo "Synced from $DESIGN"
