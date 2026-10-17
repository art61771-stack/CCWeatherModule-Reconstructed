#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then echo 'NOT RUN: Apple Foundation/QuartzCore require macOS'; exit 77; fi
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
xcrun clang -fobjc-arc -fblocks -DWCC_TESTING=1 -I evidence/mock121 -framework Foundation -framework CoreFoundation -framework CoreGraphics -framework QuartzCore src/WCCPreferences.m src/WCCConfigurations.m src/WCCTextShadow.m evidence/features125.m -o "$out/features125"
"$out/features125"
xcrun clang -fobjc-arc -fblocks -DCY_TESTING=1 -DWCC_TESTING=1 src/CYCaiyunProvider.m src/WCCPreferences.m src/WCCWeatherSource.m evidence/weather125.m -framework Foundation -framework CoreFoundation -framework Security -o "$out/weather125"
"$out/weather125"
