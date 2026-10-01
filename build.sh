#!/bin/bash
# Builds a universal (Apple Silicon + Intel) Farsight.app and Farsight.dmg into ./dist
set -euo pipefail
trap 'echo ""; echo "Build cancelled."; exit 130' INT
cd "$(dirname "$0")"

APP=dist/Farsight.app
BUILD=.build
SDK="$(xcrun --show-sdk-path)"

rm -rf dist "$BUILD"
mkdir -p "$BUILD" "$APP/Contents/MacOS" "$APP/Contents/Resources"

source tools/setup-overlay.sh

# Compile each architecture, then merge into one universal binary.
for ARCH in arm64 x86_64; do
    echo "Compiling for $ARCH..."
    swiftc -O -swift-version 5 -parse-as-library ${EXTRA[@]+"${EXTRA[@]}"} \
        -sdk "$SDK" -target "$ARCH-apple-macosx13.0" \
        Sources/Farsight/*.swift -o "$BUILD/Farsight-$ARCH"
done

echo "Creating universal binary..."
lipo -create "$BUILD"/Farsight-arm64 "$BUILD"/Farsight-x86_64 -output "$APP/Contents/MacOS/Farsight"
cp Resources/Info.plist "$APP/Contents/Info.plist"
# Stamp the build time as the build number, so the menu shows which build is running.
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date +%Y%m%d.%H%M)" "$APP/Contents/Info.plist"
cp -R Resources/Tips "$APP/Contents/Resources/Tips"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature: required for Apple Silicon to run the binary at all.
echo "Signing app..."
codesign --force --deep --sign - "$APP"

# Distributable disk image containing the app and the installer script.
STAGE="$BUILD/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
cp install.sh "$STAGE/Install Farsight.command"
ln -s /Applications "$STAGE/Applications"
echo "Creating dist/Farsight.dmg..."
hdiutil create -volname Farsight -srcfolder "$STAGE" -ov -format UDZO dist/Farsight.dmg >/dev/null

lipo -info "$APP/Contents/MacOS/Farsight"
echo "Built $APP and dist/Farsight.dmg"
