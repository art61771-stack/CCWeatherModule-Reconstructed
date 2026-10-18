#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then echo 'NOT RUN: Apple Foundation requires macOS'; exit 77; fi
out="$(mktemp -d)"; trap 'rm -rf "$out"' EXIT
xcrun clang -fobjc-arc -framework Foundation -framework CoreGraphics evidence/UIKit128GreetingTests.m -o "$out/greeting128"
"$out/greeting128"
