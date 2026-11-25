#!/bin/zsh
# Regenerate the Xcode project and run the unit tests (they run real R).
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodegen generate --quiet
xcodebuild -project SampleSpace.xcodeproj -scheme SampleSpace -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData test -quiet "$@"
echo "Tests passed."
