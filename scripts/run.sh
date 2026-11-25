#!/bin/zsh
# Build, then launch the app.
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SampleSpace.app
