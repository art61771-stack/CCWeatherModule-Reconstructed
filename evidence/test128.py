from pathlib import Path
import plistlib,re
p=Path(__file__).resolve().parents[1]
s=(p/'src/WCCContentViewController.m').read_text(); h=(p/'src/WCCRuntime.h').read_text(); w=(p/'.github/workflows/build.yml').read_text()
def method(name):
 m=re.search(r'- \([^\n]+\)'+re.escape(name)+r'(?::\([^\n]+\)[^\n]*)? \{',s); assert m,name
 return s[m.start():].split('\n- (',1)[0]
a=method('applyRegionPositions'); layout=method('viewWillLayoutSubviews'); expanded=method('layoutOriginalExpanded')
assert 'WCCGreetingVisibleAlignment(WCCRegionOffset(6))' in a and 'region==3 ? WCCGreetingTranslation' in a
assert 'WCCNormalizePositionOffset(6,preference)>0?2:0' in h
for needle in ('adjustsFontSizeToFitWidth=NO','minimumScaleFactor=1','numberOfLines=1','NSLineBreakByTruncatingTail'): assert needle in layout
assert 'adjustsFontSizeToFitWidth=NO' in expanded and 'textAlignment=NSTextAlignmentLeft' in expanded
assert 'if (_isExpanded) return;' in a
assert 'WCCInformationAlignment' in a and 'textRectForBounds' in a
info=plistlib.loads((p/'Resources/Info.plist').read_bytes()); assert info['CFBundleVersion']==info['CFBundleShortVersionString'] and tuple(map(int,info['CFBundleVersion'].split('.'))) >= (1,2,8)
assert 'Version: 1.2.11' in (p/'control').read_text()
for needle in ('runtime128.c','run128-foundation.sh','test128.py','run127-foundation.sh','run126-foundation.sh','run125-foundation.sh','run124-foundation.sh','CCWeatherModule-1.2.11-rootless'): assert needle in w
print('PASS128 static: visible-anchor helper, fixed collapsed font/truncation, expanded exclusion, region retention, metadata/workflow')
