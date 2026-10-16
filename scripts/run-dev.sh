#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
CONFIG="${CONFIG:-debug}" bash scripts/build-app.sh
[ "${NO_OPEN:-0}" = "1" ] || open .build/app/WisprFlowIsDead.app
