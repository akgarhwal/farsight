#!/bin/bash
# Regenerates the README screenshots in ./docs by rendering the app's views off-screen.
set -euo pipefail
trap 'echo ""; echo "Screenshots cancelled."; exit 130' INT
cd "$(dirname "$0")"

mkdir -p .build docs
source tools/setup-overlay.sh

echo "Compiling screenshot renderer..."
# Everything except FarsightApp.swift, whose @main would clash with the renderer's.
swiftc -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx13.0" ${EXTRA[@]+"${EXTRA[@]}"} \
    $(ls Sources/Farsight/*.swift | grep -v FarsightApp.swift) tools/Screenshots.swift \
    -o .build/screenshots

echo "Rendering screenshots..."
.build/screenshots docs
