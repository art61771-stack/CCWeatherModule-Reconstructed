from pathlib import Path
import plistlib
p=Path(__file__).resolve().parents[1]
s=(p/'src/WCCSystemWeatherDetails.m').read_text(); c=(p/'src/WCCContentViewController.m').read_text(); mk=(p/'Makefile').read_text()
assert 'WCCRenderSystemWeatherDetails' in s and 'respondsToSelector' in s and 'methodSignatureForSelector' in s
assert 'valueForKey' not in s and 'windSpeed' in s and 'unproven speed' in s
assert 'WCCRenderSystemWeatherDetails(_currentCity' in c and 'native[@"details"]' in c and 'native[@"outlook"]' in c
assert 'src/WCCSystemWeatherDetails.m' in mk
info=plistlib.loads((p/'Resources/Info.plist').read_bytes()); assert info['CFBundleVersion']==info['CFBundleShortVersionString'] and tuple(map(int,info['CFBundleVersion'].split('.'))) >= (1,2,6)
assert 'Version: '+info['CFBundleVersion'] in (p/'control').read_text()
w=(p/'.github/workflows/build.yml').read_text(); assert 'run126-foundation.sh' in w and 'CCWeatherModule-1.2.12-rootless' in w
print('PASS126 static production wiring, safe runtime helper, source binding and 1.2.6 metadata')
