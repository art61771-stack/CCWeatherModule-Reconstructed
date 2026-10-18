from pathlib import Path
import plistlib,re
p=Path(__file__).resolve().parents[1]
c=(p/'src/WCCContentViewController.m').read_text(); h=(p/'src/WCCRuntime.h').read_text(); w=(p/'.github/workflows/build.yml').read_text()
method=lambda n:c.split('- (void)'+n+' {',1)[1].split('\n- (',1)[0]
a=method('applyRegionPositions'); b=method('bindGreetingText'); layout=method('viewDidLayoutSubviews')
assert 'if(region==3)' in a and 'WCCGreetingTranslation' in a and 'WCCGreetingAlignment(WCCRegionOffset(6)' in a
assert 'textRectForBounds' in a and 'WCCRegionTranslation' in a # region measured-ink contract retained
assert 'WCCGreetingTranslation' in h and 'WCCRegionTranslation(rail,width,height,x,y)' in h
for text in (b,layout,a): assert 'WCCSetRegionOffset' not in text and 'arc4random' not in text
assert 'drawGreeting' not in layout and 'drawGreeting' not in a and 'drawGreeting' not in b
assert c.count('arc4random')==2
info=plistlib.loads((p/'Resources/Info.plist').read_bytes());assert info['CFBundleVersion']==info['CFBundleShortVersionString']=='1.2.7'
assert 'Version: 1.2.7' in (p/'control').read_text()
assert 'runtime127.c' in w and 'run127-foundation.sh' in w and 'test127.py' in w and 'CCWeatherModule-1.2.7-rootless' in w
print('PASS127 static: fixed greeting rail only, pure bind/layout, random event boundary, region contract, 1.2.7 metadata/workflow')
