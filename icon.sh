#!/bin/bash
# Regenerates Resources/AppIcon.icns (and docs/icon.png) from tools/Icon.swift.
set -euo pipefail
trap 'echo ""; echo "Icon generation cancelled."; exit 130' INT
cd "$(dirname "$0")"

mkdir -p .build docs
source tools/setup-overlay.sh

echo "Compiling icon generator..."
swiftc -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx13.0" ${EXTRA[@]+"${EXTRA[@]}"} \
    tools/Icon.swift -o .build/icon

echo "Generating icon..."
.build/icon docs/icon.png

ICONSET=.build/AppIcon.iconset
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
for SIZE in 16 32 128 256 512; do
    sips -z $SIZE $SIZE docs/icon.png --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
    sips -z $((SIZE * 2)) $((SIZE * 2)) docs/icon.png --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "wrote Resources/AppIcon.icns"
