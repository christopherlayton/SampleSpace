#!/bin/zsh
# Build a Release copy of Sample Space and wrap it in an installer package:
#   build/SampleSpace-<version>.pkg   (installs Sample Space.app into /Applications)
# Double-click the .pkg to install. The app still uses this Mac's R (and, for the Python
# Wormhole, Python); the welcome tour's systems check says if anything is missing.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer

xcodegen generate --quiet
xcodebuild -project SampleSpace.xcodeproj -scheme SampleSpace -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData build -quiet

app=build/DerivedData/Build/Products/Release/SampleSpace.app
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist")
codesign --verify --deep --strict "$app"

# Stage the app on its own, so the package holds nothing else.
stage=build/package-root
rm -rf "$stage" build/component.plist
mkdir -p "$stage"
ditto --norsrc --noextattr --noqtn "$app" "$stage/SampleSpace.app"
codesign --verify --deep --strict "$stage/SampleSpace.app"

# Not relocatable: otherwise Installer may "upgrade" a copy it finds elsewhere (such as the
# Debug build in build/DerivedData) instead of putting the app in /Applications.
pkgbuild --analyze --root "$stage" build/component.plist >/dev/null
/usr/libexec/PlistBuddy -c "Delete :0:BundleIsRelocatable" build/component.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :0:BundleIsRelocatable bool false" build/component.plist

pkg="build/SampleSpace-$version.pkg"
rm -f "$pkg"
pkgbuild --root "$stage" --component-plist build/component.plist \
  --identifier app.samplespace.SampleSpace.pkg --version "$version" \
  --install-location /Applications "$pkg" >/dev/null
echo "Package: $(pwd)/$pkg"
