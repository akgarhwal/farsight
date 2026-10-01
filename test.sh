#!/bin/bash
# Runs the TimerModel lock/sleep tests in tools/Tests.swift.
set -euo pipefail
trap 'echo ""; echo "Tests cancelled."; exit 130' INT
cd "$(dirname "$0")"

mkdir -p .build
source tools/setup-overlay.sh

echo "Compiling tests..."
# Everything except FarsightApp.swift, whose @main would clash with the test runner's.
swiftc -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx13.0" ${EXTRA[@]+"${EXTRA[@]}"} \
    $(ls Sources/Farsight/*.swift | grep -v FarsightApp.swift) tools/Tests.swift \
    -o .build/farsight-tests

echo "Running tests..."
.build/farsight-tests
