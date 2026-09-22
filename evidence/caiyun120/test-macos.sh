#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ "$(uname -s)" != Darwin ]; then
  echo 'NOT RUN: Apple Foundation/Security tests require macOS + Xcode Command Line Tools.'
  exit 77
fi
BUILD=$(mktemp -d "${TMPDIR:-/tmp}/caiyun-offline.XXXXXX")
trap 'rm -rf "$BUILD"' EXIT HUP INT TERM
# Compile the real production branch separately; test hooks must not leak into it.
xcrun clang -fobjc-arc -fblocks -Wall -Wextra -Wno-unused-parameter \
  -mmacosx-version-min=11.0 -c CYCaiyunProvider.m -o "$BUILD/production.o"
xcrun clang -fobjc-arc -fblocks -Wall -Wextra -Wno-unused-parameter \
  -mmacosx-version-min=11.0 -DCY_TESTING=1 \
  CYCaiyunProvider.m Tests.m -framework Foundation -framework Security -o "$BUILD/tests"
# Mock transport is injected: this executable makes zero live weather requests.
"$BUILD/tests" "$PWD/fixtures/synthetic.json"
