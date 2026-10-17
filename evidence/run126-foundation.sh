#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then echo 'NOT RUN: Apple Foundation requires macOS'; exit 77; fi
out="$(mktemp -d)"; trap 'rm -rf "$out"' EXIT
xcrun clang -fobjc-arc -fblocks -I src -framework Foundation src/WCCSystemWeatherDetails.m evidence/system126.m -o "$out/system126"
"$out/system126"
