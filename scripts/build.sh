#!/bin/zsh
# Regenerate the Xcode project and build a Debug app into ./build.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodegen generate --quiet
xcodebuild -project SampleSpace.xcodeproj -scheme SampleSpace -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData build -quiet
echo "Built: $(pwd)/build/DerivedData/Build/Products/Debug/SampleSpace.app"
