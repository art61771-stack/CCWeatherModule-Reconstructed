from pathlib import Path
p=Path(__file__).resolve().parents[1]
c=(p/'src/WCCContentViewController.m').read_text()
h=(p/'src/WCCContentViewController.h').read_text()
e=(p/'src/WCCTextShadow.m').read_text()
assert 'UIView *_iconContentView;' in h and 'UIImageView *_systemIconView;' in h
assert 'WCCApplyMainContentAnimations(_iconContentView' in c
assert '[_iconContentView addSubview:_systemIconView]' in c
assert '[_iconContentView addSubview:self.customMedia]' in c
assert '_systemIconView.frame=_iconContentView.bounds' in c
assert 'self.customMedia.frame=_iconContentView.bounds' in c
assert c.count('_iconView.image') == 0
assert 'animationWithKeyPath:i?@"transform.scale":@"opacity"' in e
assert 'a.fromValue=@(.94);a.toValue=@(1.06);a.additive=NO' in e
assert 'a.additive=YES' not in e
assert 'wcc.icon.opacity.breathe125' in e and 'wcc.icon.shadowOpacity.breathe124' in e
post=(p/'layout/DEBIAN/postinst').read_bytes()
assert post == b"#!/bin/sh\nset -e\necho 'finish:restart'\nexit 0\n"
for bad in (b'killall',b'launchctl',b'sbreload',b'ldrestart',b' rm ',b' cp ',b'curl',b'wget'):
 assert bad not in post.lower()
for f in ('control','Resources/Info.plist','.github/workflows/build.yml','README.md'):
 assert '1.2.9' in (p/f).read_text(), f
print('PASS129 static: independent native/custom-media content container, non-additive scale, opacity/shadow coexistence, strict safe finish hint and version wiring.')
