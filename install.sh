#!/bin/bash
# Installs Farsight.app (next to this script, or in ./dist) and launches it.
# Uses /Applications when writable, otherwise ~/Applications (no admin rights needed).
set -euo pipefail
cd "$(dirname "$0")"

SRC=Farsight.app
[ -d "$SRC" ] || SRC=dist/Farsight.app
[ -d "$SRC" ] || { echo "Farsight.app not found. Run ./build.sh first."; exit 1; }

DEST_DIR=/Applications
if [ ! -w "$DEST_DIR" ]; then
    DEST_DIR="$HOME/Applications"
    mkdir -p "$DEST_DIR"
fi
DEST="$DEST_DIR/Farsight.app"

pkill -x Farsight 2>/dev/null || true
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
# The app isn't notarized; clear the download quarantine so Gatekeeper lets it open.
xattr -cr "$DEST"
open "$DEST"

echo "Farsight installed to $DEST. Look for the eye icon in the menu bar."
echo "Turn on 'Launch at login' from its menu to start it automatically."
