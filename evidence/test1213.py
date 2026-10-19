#!/usr/bin/env python3
from pathlib import Path
import plistlib
p=Path(__file__).resolve().parents[1]
c=(p/'src/WCCContentViewController.m').read_text()
h=(p/'src/WCCBackgroundClip.h').read_text(); m=(p/'src/WCCBackgroundClip.m').read_text()
mk=(p/'Makefile').read_text(); wf=(p/'.github/workflows/build.yml').read_text()
assert 'backgroundClipView' in c and '[self.backgroundClipView addSubview:self.backgroundMedia]' in c
assert '[self.backgroundClipView addSubview:self.backgroundMaskView]' in c
assert c.index('[self.backgroundClipView addSubview:self.backgroundMedia]') < c.index('[self setupHeaderView]')
assert 'self.view.clipsToBounds' not in c and 'self.view.layer.mask' not in c
assert '[self layoutBackgroundClip];\n    NSString *path=' in c
assert c[c.index('- (void)viewDidLayoutSubviews'):].index('[self layoutBackgroundClip]') < c[c.index('- (void)viewDidLayoutSubviews'):].index('[self bindGreetingText]')
for needle in ('kCACornerCurveContinuous','host.layer.mask','convertPoint:CGPointZero fromLayer:source','WCCBackgroundFallbackRadius','clipsToBounds=YES'):
    assert needle in m,needle
assert 'src/WCCBackgroundClip.m' in mk
assert 'Version: 1.2.16' in (p/'control').read_text()
info=plistlib.loads((p/'Resources/Info.plist').read_bytes()); assert info['CFBundleVersion']==info['CFBundleShortVersionString']=='1.2.16'
assert 'CCWeatherModule-1.2.16-rootless' in wf and 'test1213.py' in wf
print('PASS1213 static: shared media/overlay clip, host shape/corner introspection, fallback, layout-before-display, root effects unmasked.')
