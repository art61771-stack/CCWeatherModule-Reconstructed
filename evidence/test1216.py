from pathlib import Path
p=Path('src/WCCContentViewController.m').read_text(); r=Path('src/WCCRuntime.h').read_text(); q=Path('src/WCCPreferences.m').read_text()
block=p[p.index('- (void)layoutMainCustomMedia'):p.index('- (void)viewDidLayoutSubviews')]
assert 'WCCCanonicalCollapsedIcon(width,height' in block
assert 'WCCMainIconAbsoluteCenter(width,height' in block
assert '_iconView.bounds=(CGRect){CGPointZero,finalSize};' in block
assert '_iconView.center=CGPointMake(centerX,centerY);' in block
assert '_iconView.transform=CGAffineTransformIdentity;' in block
assert 'CGAffineTransformMakeScale' not in block
assert 'WCCRegionOffset(2)' not in block and 'WCCRegionOffset(3)' not in block
assert 'WCCMaterializeMainIconAbsoluteCenter(size.width,g.headerHeight,self.layoutSize);' in p
assert 'mainIconAbsoluteNormalizedCenterX1216' in q and 'mainIconAbsoluteNormalizedCenterY1216' in q
assert 'if(WCCStoredIconAbsolute(&nx,&ny)){' in q
assert 'WCCAbsoluteIconCenterFromLegacy' in q
assert 'WCCCanonicalCollapsedIcon' in r and 'WCCClampAbsoluteIconCenter' in r
for forbidden in ['presentationLayer','_iconView.frame:self.collapsedIconSlot']:
 assert forbidden not in p
for f in ['control','package/control/control']:
 assert 'Version: 1.2.16' in Path(f).read_text()
assert Path('Resources/Info.plist').read_text().count('<string>1.2.16</string>')==2
print('PASS1216 static: collapsed production consumes only persisted normalized final center + canonical bounds geometry; parent transform stays identity')
