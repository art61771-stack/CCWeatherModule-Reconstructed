#!/bin/sh
set -eu
out="${TMPDIR:-/tmp}/wcc1215"
mkdir -p "$out"
xcrun clang -fobjc-arc -framework Foundation -framework CoreGraphics -framework QuartzCore evidence/UIKit1215IconTests.m -o "$out/icon1215"
"$out/icon1215"
