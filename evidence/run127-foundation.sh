#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then
 echo 'NOT RUN: Apple Foundation/CoreGraphics UILabel stub requires macOS; Linux/iSH exit 77. No UIKit/device verification.'
 exit 77
fi
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
xcrun clang -fobjc-arc -framework Foundation -framework CoreGraphics evidence/UIKit127GreetingTests.m -o "$out/greeting127"
"$out/greeting127"
