#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then
  echo 'NOT RUN: Apple Foundation required (run on macOS).'
  exit 77
fi
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
xcrun clang -fobjc-arc -fblocks -DWCC_TESTING=1 -Wall -Wextra \
  -framework Foundation -framework CoreFoundation \
  src/WCCPreferences.m src/WCCConfigurations.m evidence/configurations121.m \
  -o "$out/configurations121"
"$out/configurations121"

xcrun clang -fobjc-arc -fblocks -DWCC_TESTING=1 -I evidence/mock121 -framework Foundation -framework CoreFoundation -framework CoreGraphics -framework QuartzCore src/WCCPreferences.m src/WCCTextShadow.m evidence/shadow121.m -o "$out/shadow121"
"$out/shadow121"
