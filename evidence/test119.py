"""Local source wiring checks + compiled exact production C, not UIKit execution."""
from pathlib import Path
import subprocess,tempfile
r=Path(__file__).resolve().parents[1]
c=(r/'src/WCCContentViewController.m').read_text()
s=(r/'src/WCCSettings.m').read_text()
p=(r/'src/WCCPreferences.m').read_text()
u=(r/'src/WCCRegionSettings.m').read_text()
f=(r/'src/WCCConfigurations.m').read_text()
def method(name):
 start=c.index('- (void)'+name+' {'); end=c.find('\n- (',start+1)
 return c[start:end]
for name in ['applyRegionPositions','regionPositionChanged','mainIconScaleChanged','layoutMainCustomMedia']:
 body=method(name)
 for forbidden in ['drawGreeting','loadPath:','updateWeather','refreshHourly','updateHourly','cacheHourly']:
  assert forbidden not in body,(name,forbidden)
body=method('layoutMainCustomMedia')
assert body.index('_iconView.transform=CGAffineTransformIdentity')<body.index('CGRect slot=_iconView.frame')
assert 'WCCMainIconTarget' in body and '_iconView.transform=CGAffineTransformMake(' in body
assert 'self.customMedia.frame=_iconView.bounds' in body
assert '_iconView.frame=' not in body and 'customIcon' not in body
assert 'if (_isExpanded) return;' in method('applyRegionPositions')
assert 'if (region==1) { region++; continue; }' in method('applyRegionPositions')
assert '[self layoutMainCustomMedia]' in method('renderWeatherIcon')
assert 'icon.frame = CGRectMake(12, 22, 30, 30)' in c
assert '@[@[_tempLabel,_highLowLabel],@[_iconView]' in c
assert '@[_cityLabel,_conditionLabel,_precipLabel],@[self.greetingLabel]' in c
assert 'self.slider.enabled=YES' in s and '主图标大小' in s
assert 'minimumValue=50' in s and 'maximumValue=150' in s and 'roundf(slider.value/5)*5' in s
assert 'slider.minimumValue=-40' in u and 'slider.maximumValue=40' in u
assert 'index.section*2+index.row' in u and 'round(slider.value)' in u
assert '[self resetRegion:index.section]' in u and '[self resetRegion:-1]' in u and 'WCCResetRegionOffsets(region)' in u
assert 'UITableViewController' in (r/'src/WCCRegionSettings.h').read_text()
assert '[prefs setPersistentDomain:after forName:WCCPreferenceSuite]' in p
assert '[prefs setPersistentDomain:before forName:WCCPreferenceSuite]' in p
load=f.split('BOOL WCCLoadConfiguration',1)[1].split('BOOL WCCDeleteConfiguration',1)[0]
assert load.index('WCCReadConfiguration')<load.index('WCCWriteConfiguration')<load.index('WCCCommitSliderValues')<load.index('postNotificationName:')
assert load.count('postNotificationName:')==1 and 'WCCPreferencesChanged' not in load
assert 'NSUUID.UUID.UUIDString' in f and 'NSDataWritingAtomic' in f
assert 'CFBooleanGetTypeID' in f and '16384' in f
with tempfile.TemporaryDirectory() as d:
 exe=str(Path(d)/'runtime119')
 subprocess.run(['cc','-std=c11','-D_GNU_SOURCE','-Wall','-Wextra',str(r/'evidence/runtime119.c'),'-lm','-o',exe],check=True)
 subprocess.run([exe],check=True)
print('PASS 119 source wiring; no weather/hourly/media reload or greeting draw on slider events')
print('NOT RUN: Foundation configuration executable and UIKit/iOS runtime (Apple SDK unavailable locally)')
