#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 evidence/generate-route124.py
if [ "$(uname -s)" != Darwin ]; then
 echo 'NOT RUN: Apple Foundation requires macOS; Linux/iSH exit 77. No UIKit/device verification.'
 exit 77
fi
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
xcrun clang -fobjc-arc -fblocks -DWCC_TESTING=1 -framework Foundation -framework CoreFoundation src/WCCPreferences.m src/WCCConfigurations.m evidence/configurations124.m -o "$out/configurations124"
"$out/configurations124"
xcrun clang -fobjc-arc -fblocks -framework Foundation evidence/route124-generated.m -o "$out/route124"
"$out/route124"
xcrun clang -fobjc-arc -fblocks -DWCC_TESTING=1 -I evidence/mock121 -framework Foundation -framework CoreFoundation -framework CoreGraphics -framework QuartzCore src/WCCPreferences.m src/WCCTextShadow.m evidence/effects124.m -o "$out/effects124"
"$out/effects124"
xcrun clang -fobjc-arc -fblocks -DCY_TESTING=1 -DWCC_TESTING=1 src/CYCaiyunProvider.m src/WCCPreferences.m src/WCCWeatherSource.m evidence/source124.m -framework Foundation -framework CoreFoundation -framework Security -o "$out/source124"
"$out/source124" "$PWD/evidence/caiyun120/fixtures/synthetic.json"
