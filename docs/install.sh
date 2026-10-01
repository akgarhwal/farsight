#!/bin/bash
# Installs Farsight.app and launches it.
# Can be run locally after build, inside the DMG, or via one-liner:
#   curl -fsSL https://akgarhwal.github.io/farsight/install.sh | bash
set -euo pipefail

DEST_DIR=/Applications
if [ ! -w "$DEST_DIR" ]; then
    DEST_DIR="$HOME/Applications"
    mkdir -p "$DEST_DIR"
fi
DEST="$DEST_DIR/Farsight.app"

TMP_DIR=""
cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        if [ -n "${MOUNT_DIR:-}" ] && [ -d "${MOUNT_DIR:-}" ]; then
            hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
        fi
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

SRC=""
SCRIPT_DIR="$(cd "$(dirname "$0" 2>/dev/null || echo ".")" 2>/dev/null && pwd -P || echo ".")"
if [ -d "$SCRIPT_DIR/Farsight.app" ]; then
    SRC="$SCRIPT_DIR/Farsight.app"
elif [ -d "$SCRIPT_DIR/dist/Farsight.app" ]; then
    SRC="$SCRIPT_DIR/dist/Farsight.app"
fi

if [ -z "$SRC" ]; then
    echo "Downloading latest Farsight release from GitHub..."
    TMP_DIR="$(mktemp -d -t farsight-install)"
    DMG_PATH="$TMP_DIR/Farsight.dmg"
    RELEASE_URL="https://github.com/akgarhwal/farsight/releases/latest/download/Farsight.dmg"
    curl -fsSL -L "$RELEASE_URL" -o "$DMG_PATH"
    
    MOUNT_OUTPUT="$(hdiutil attach -nobrowse -readonly "$DMG_PATH")"
    MOUNT_DIR="$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/.*' | head -n1)"
    SRC="$MOUNT_DIR/Farsight.app"
fi

echo "Installing Farsight to $DEST..."
pkill -x Farsight 2>/dev/null || true
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
# Clear download quarantine so macOS Gatekeeper allows it to open without warning
xattr -cr "$DEST" 2>/dev/null || true
open "$DEST"

echo ""
echo "✓ Farsight installed successfully to $DEST!"
echo "Look for the eye icon in your menu bar."
echo "Turn on 'Launch at login' from its menu to start it automatically."
