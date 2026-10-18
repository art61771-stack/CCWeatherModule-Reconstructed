#!/bin/sh
set -eu
out="${TMPDIR:-/tmp}/wcc1214"
mkdir -p "$out"
xcrun clang -fobjc-arc -framework Foundation -framework CoreGraphics evidence/UIKit1214GreetingTests.m -o "$out/greeting1214"
"$out/greeting1214"
