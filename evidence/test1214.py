from pathlib import Path
import plistlib,re
p=Path(__file__).resolve().parents[1]
c=(p/'src/WCCContentViewController.m').read_text(); h=(p/'src/WCCRuntime.h').read_text(); wf=(p/'.github/workflows/build.yml').read_text()
def method(name):
 m=re.search(r'- \([^\n]+\)'+re.escape(name)+r'(?::\([^\n]+\)[^\n]*)? \{',c); assert m,name
 return c[m.start():].split('\n- (',1)[0]
a=method('applyRegionPositions'); layout=method('viewWillLayoutSubviews'); expanded=method('layoutOriginalExpanded')
assert 'WCCGreetingRail' in h and 'WCCGreetingMinimumVisibleWidth = 1' in h
assert 'WCCRect target=WCCGreetingRail(' in a and 'self.greetingLabel.frame=WCCCGRect(target)' in a
assert 'self.greetingLabel.textAlignment=NSTextAlignmentLeft' in a
assert 'textRectForBounds' in a and a.index('if(region==3)') < a.index('textRectForBounds')
section=a[a.index('if(region==3)'):a.index('textRectForBounds')]
assert 'textRectForBounds' not in section
assert 'WCCGreetingVisibleAlignment(WCCRegionOffset(6))' not in a
assert 'if (_isExpanded) return;' in a
for needle in ('adjustsFontSizeToFitWidth=NO','minimumScaleFactor=1','numberOfLines=1','NSLineBreakByTruncatingTail'): assert needle in layout
assert 'textAlignment=NSTextAlignmentLeft' in expanded
assert 'WCCInformationAlignment' in a
for f in ('control','package/control/control'):
 assert 'Version: 1.2.14' in (p/f).read_text()
info=plistlib.loads((p/'Resources/Info.plist').read_bytes()); assert info['CFBundleVersion']==info['CFBundleShortVersionString']=='1.2.14'
assert 'CCWeatherModule-1.2.14-rootless' in wf and 'runtime1214.c' in wf and 'run1214-foundation.sh' in wf
for old in ('runtime128.c','run128-foundation.sh','test128.py','runtime127.c','run127-foundation.sh','test127.py'): assert old not in wf
assert '1.2.14' in (p/'README.md').read_text()
print('PASS1214 static: production greeting frame is a text-independent left-aligned rail; expanded excluded; metadata semantics retained; version/workflow wired')
