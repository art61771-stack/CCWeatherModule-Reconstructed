from pathlib import Path
import plistlib,re
p=Path(__file__).resolve().parents[1];s=p/'src'
c=(s/'WCCContentViewController.m').read_text();prefs=(s/'WCCPreferences.m').read_text();ui=(s/'WCCRegionSettings.m').read_text()
def method(name):
 match=re.search(r'- \(void\)'+re.escape(name)+r'[^;\n]*\{',c);assert match,name
 start=match.start();end=c.find('\n- (',start+1)
 return c[start:end if end>=0 else None]
# RNG only on event entry, never layout/preferences/effects binding.
assert c.count('arc4random')==2 and method('drawGreeting').count('arc4random')==2
for name in ['bindGreetingText','regionPositionChanged','viewDidLayoutSubviews','applyRegionPositions','applyTextShadows','layoutMainCustomMedia']:
 t=method(name);assert 'arc4random' not in t and 'drawGreeting' not in t,name
for name,gate in [('consumeHostSession','WCCConsumeModuleHost'),('willTransitionToExpandedContentMode:','WCCConsumeExpansion')]:
 t=method(name);assert gate in t and '[self drawGreeting]' in t
assert 'WCCPickCustomGreeting(texts.count,previous,arc4random())' in method('drawGreeting')
assert 'indexOfObject:displayed' in method('drawGreeting') and 'self.greetingLabel.text ?: self.selectedCustomGreeting' in method('drawGreeting')
assert 'textRectForBounds:label.bounds' in method('applyRegionPositions')
assert 'if(!_isExpanded)_iconView.frame=slot' in method('layoutMainCustomMedia')
assert 'self.collapsedIconSlot=WCCCGRect(g.icon)' in c
assert 'WCCGreetingEntries().count+1' in ui and 'WCCSaveGreetingEntry(entry[@"id"]' in ui and 'WCCDeleteGreetingEntry(rows[index.row-1][@"id"])' in ui
assert 'WCCApplyTextEffects(label,enabled,glow)' in c and 'WCCTextGlowEnabled(index++)' in c
for f in ['CYCaiyunProvider.m','CYCaiyunProvider.h','WCCWeatherSource.m','WCCWeatherSource.h']:
 assert (s/f).read_bytes()==(p/'evidence/fixtures122'/f).read_bytes()
info=plistlib.loads((p/'Resources/Info.plist').read_bytes())
assert info['CFBundleVersion']==info['CFBundleShortVersionString']=='1.2.3'
assert 'Version: 1.2.3' in (p/'control').read_text()
assert 'CCWeatherModule-1.2.3-rootless' in (p/'.github/workflows/build.yml').read_text()
print('PASS123 static production wiring: event-gated RNG, pure binding/layout/effects, independent CRUD, three glow groups, provider/source byte identity, version consistency. UIKit/device NOT RUN.')
