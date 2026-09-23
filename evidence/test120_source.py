from pathlib import Path
import re, plistlib
root=Path(__file__).resolve().parents[1]
s=(root/'src/WCCWeatherSource.m').read_text(); ui=(root/'src/WCCWeatherSettings.m').read_text(); c=(root/'src/WCCContentViewController.m').read_text(); p=(root/'src/CYCaiyunProvider.m').read_text(); make=(root/'Makefile').read_text()
checks=[
 'src/CYCaiyunProvider.m' in make, 'src/WCCWeatherSource.m' in make, 'src/WCCWeatherSettings.m' in make, 'Foundation Security' in make, 'CY_TESTING' not in make,
 'secureTextEntry=i==0' in ui, 'self.fields[0].text=@""' in ui, 'UIAlertActionStyleDestructive' in ui,
 'WCCParseCoordinate(self.fields[1].text,YES)' in ui, 'WCCParseCoordinate(self.fields[2].text,NO)' in ui,
 'WCCWeatherSource.shared.caiyun ? self.caiyunRender[@"hours"]' in c,
 'generation!=self.generation' in s,'epoch!=self.requestEpoch' in s,
 'sourceGeneration!=self.sourceGeneration' in c, 's.stale?@" · 已过期"' in c,
 'WCCRenderCaiyunSnapshot(s.snapshot' in c, 'f.timeZone=s.timezone' in s,
 'CYCancelled' in p, 'kSecAttrAccessibleWhenUnlockedThisDeviceOnly' in p,
 'Token' not in ''.join(re.findall(r'forKey:@"([^\"]+)"',s)),
 'return nil;' not in (root/'src/WCCModule.m').read_text().split('WCCLoadWeatherFrameworks();',1)[1].split('WCCContentViewController *controller',1)[0],
 'Version: 1.2.4' in (root/'control').read_text(), 'Icon: https://' in (root/'control').read_text(),
]
info=plistlib.loads((root/'Resources/Info.plist').read_bytes()); checks.extend([info['CFBundleVersion']=='1.2.4',info['CFBundleShortVersionString']=='1.2.4'])
# All network-derived resource choices reside in audited component static mapping.
for name in ['CLEAR_DAY','CLEAR_NIGHT','PARTLY_CLOUDY_DAY','PARTLY_CLOUDY_NIGHT','CLOUDY','LIGHT_HAZE','MODERATE_HAZE','HEAVY_HAZE','LIGHT_RAIN','MODERATE_RAIN','HEAVY_RAIN','STORM_RAIN','FOG','LIGHT_SNOW','MODERATE_SNOW','HEAVY_SNOW','STORM_SNOW','DUST','SAND','WIND']: checks.append(name in p)
for i,ok in enumerate(checks): assert ok, f'wiring assertion {i+1}'
import source124_contract
source124_contract.verify(root)
print(f'PASS {len(checks)} source120 static assertions + provider TTL-only / source security contract (NOT compile/runtime)')
