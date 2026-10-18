#!/bin/sh
set -eu
clang -fobjc-arc -fblocks -DWCC_TESTING=1 -framework Foundation -framework CoreFoundation \
  src/WCCPreferences.m src/WCCConfigurations.m src/WCCWeatherDetailProjection.m evidence/weather1211.m -o /tmp/weather1211
/tmp/weather1211
