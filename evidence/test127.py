from pathlib import Path
import plistlib,subprocess
p=Path(__file__).resolve().parents[1]
base='9a1ef30107e9e7682ef3201678fd7d7966398550'
def old(path): return subprocess.check_output(['git','show',f'{base}:{path}'],cwd=p,text=not path.endswith('.plist'))
c=old('src/WCCContentViewController.m'); h=old('src/WCCRuntime.h'); w=old('.github/workflows/build.yml')
method=lambda n:c.split('- (void)'+n+' {',1)[1].split('\n- (',1)[0]
a=method('applyRegionPositions'); b=method('bindGreetingText'); layout=method('viewDidLayoutSubviews')
assert 'if(region==3)' in a and 'WCCGreetingTranslation' in a and 'WCCGreetingAlignment(WCCRegionOffset(6)' in a
assert 'textRectForBounds' in a and 'WCCRegionTranslation' in a
assert 'WCCGreetingTranslation' in h and 'WCCRegionTranslation(rail,width,height,x,y)' in h
for text in (b,layout,a): assert 'WCCSetRegionOffset' not in text and 'arc4random' not in text
assert 'drawGreeting' not in layout and 'drawGreeting' not in a and 'drawGreeting' not in b
assert c.count('arc4random')==2
info=plistlib.loads(subprocess.check_output(['git','show',f'{base}:Resources/Info.plist'],cwd=p)); assert info['CFBundleVersion']==info['CFBundleShortVersionString']=='1.2.7'
assert 'Version: 1.2.7' in old('control')
assert 'runtime127.c' in w and 'run127-foundation.sh' in w and 'test127.py' in w and 'CCWeatherModule-1.2.7-rootless' in w
print('PASS127 historical static at 9a1ef30: original assertions retained; fixed rail test contract archived (device-visible failure acknowledged by 128)')
