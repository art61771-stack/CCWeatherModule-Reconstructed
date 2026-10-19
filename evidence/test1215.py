from pathlib import Path
p=Path('src/WCCContentViewController.m').read_text()
r=Path('src/WCCRuntime.h').read_text()
# Historical 1.2.15 helper/fixture remains testable, but current production is
# intentionally no longer bound to its dynamic cached-baseline semantics.
assert 'WCCMainIconLayoutForBaseline' in r
assert '1.2.15 historical baseline contract remains for fixtures' in r
assert 'presentationLayer' not in p
assert '_iconView.frame:self.collapsedIconSlot' not in p
assert 'WCCCanonicalCollapsedIcon(width,height' in p
assert '_iconView.transform=CGAffineTransformIdentity;' in p
for callback in ['visibilityChanged','controlCenterWillPresent','viewDidAppear','preferencesChanged','updateWeatherDisplay','renderWeatherIcon','viewWillLayoutSubviews','viewDidLayoutSubviews']:
    assert callback in p
wf=Path('.github/workflows/build.yml').read_text()
assert 'runtime1215.c' in wf and 'run1215-foundation.sh' in wf
print('PASS1215 historical fixture: baseline helper retained; production promoted to 1.2.16 absolute-center contract')
