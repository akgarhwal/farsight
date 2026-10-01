#!/bin/bash
# Sets up EXTRA compiler flags with a VFS overlay if this Mac has the
# Command Line Tools bug where both module.modulemap and bridging.modulemap exist.
EXTRA=()
CLT_SWIFT_INC=/Library/Developer/CommandLineTools/usr/include/swift
if [ -f "$CLT_SWIFT_INC/module.modulemap" ] && [ -f "$CLT_SWIFT_INC/bridging.modulemap" ]; then
    mkdir -p .build
    : > .build/empty.modulemap
    cat > .build/vfs.yaml <<EOF
{ "version": 0, "case-sensitive": "false", "roots": [ { "type": "directory",
  "name": "$CLT_SWIFT_INC", "contents": [ { "type": "file",
  "name": "module.modulemap", "external-contents": "$PWD/.build/empty.modulemap" } ] } ] }
EOF
    EXTRA=(-vfsoverlay .build/vfs.yaml -Xcc -ivfsoverlay -Xcc .build/vfs.yaml)
fi
