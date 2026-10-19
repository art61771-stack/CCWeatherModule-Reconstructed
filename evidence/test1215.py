from pathlib import Path
p=Path('src/WCCContentViewController.m').read_text()
r=Path('src/WCCRuntime.h').read_text()
assert 'CGRect slot=_isExpanded?self.expandedIconSlot:self.collapsedIconSlot;' in p
assert 'CGRect slot=_isExpanded?_iconView.frame:self.collapsedIconSlot;' not in p
assert 'self.collapsedIconSlot=collapsed;' in p
assert p.index('if (_isExpanded) {\n        [self layoutOriginalExpanded:size]; return;') < p.index('self.collapsedIconSlot=collapsed;')
assert 'self.expandedIconSlot=expanded;' in p
assert '_iconView.center=CGPointMake(layout.centerX,layout.centerY);' in p
assert '_iconView.transform=CGAffineTransformMakeScale(layout.scaleX,layout.scaleY);' in p
assert 'expanded?0:x,expanded?0:y' in r
assert 'removeAnimationForKey:@"wcc.icon.transform.scale125"' in p
for callback in ['visibilityChanged','controlCenterWillPresent','viewDidAppear','preferencesChanged','updateWeatherDisplay','renderWeatherIcon','viewWillLayoutSubviews','viewDidLayoutSubviews']:
    assert callback in p
wf=Path('.github/workflows/build.yml').read_text()
assert 'run1215-foundation.sh' in wf and 'UIKit1215IconTests.m' not in wf
for forbidden in ['presentationLayer','_iconView.layer.presentationLayer']:
    assert forbidden not in p
print('PASS1215 static: host presentation/weather/media callbacks cannot overwrite mode baselines or read transformed frame; expanded offsets neutral; own scale reset')
