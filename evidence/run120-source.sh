#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then
 echo 'NOT RUN: production Foundation/Security source tests require macOS Apple SDK.'
 exit 77
fi
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT HUP INT TERM
# Production branch, never defines CY_TESTING.
xcrun clang -fobjc-arc -fblocks -Wall -Wextra -c src/CYCaiyunProvider.m -o "$out/provider.o"
xcrun clang -fobjc-arc -fblocks -Wall -Wextra -c src/WCCWeatherSource.m -o "$out/source.o"
xcrun clang -fobjc-arc -fblocks -DCY_TESTING=1 -DWCC_TESTING=1 -Wall -Wextra src/CYCaiyunProvider.m src/WCCPreferences.m src/WCCWeatherSource.m evidence/source120.m -framework Foundation -framework CoreFoundation -framework Security -o "$out/source-tests"
"$out/source-tests" "$PWD/evidence/caiyun120/fixtures/synthetic.json"
# Component assertions link the actual production file, not the archival copy.
xcrun clang -fobjc-arc -fblocks -DCY_TESTING=1 -Wall -Wextra src/CYCaiyunProvider.m evidence/caiyun120/Tests.m -framework Foundation -framework Security -o "$out/provider-tests"
"$out/provider-tests" "$PWD/evidence/caiyun120/fixtures/synthetic.json"
