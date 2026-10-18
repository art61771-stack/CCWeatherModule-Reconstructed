from pathlib import Path
p=Path(__file__).resolve().parents[1]
prefs=(p/'src/WCCPreferences.m').read_text(); vc=(p/'src/WCCContentViewController.m').read_text(); ui=(p/'src/WCCWeatherSettings.m').read_text(); cfg=(p/'src/WCCConfigurations.m').read_text(); make=(p/'Makefile').read_text()
assert 'weatherDetailsEnabled1211' in prefs and 'return value ?' in prefs and ': YES' in prefs
assert 'WCCWeatherDetailsChanged' in prefs and 'WCCSetWeatherDetailsEnabled' in ui and '@"天气详细信息"' in ui
assert 'WCCWeatherDetailProjection.m' in make and 'applyWeatherTextProjection' in vc
method=vc[vc.index('- (void)weatherDetailsPreferenceChanged {'):vc.index('- (void)preferencesChanged {')]
assert 'refreshManual' not in method
assert 'drawGreeting' not in method
assert '@"version":@6' in cfg and 'detailsBefore' in cfg
assert 'Version: 1.2.12' in (p/'control').read_text()
assert 'CCWeatherModule-1.2.12-rootless' in (p/'.github/workflows/build.yml').read_text()
assert '1.2.12' in (p/'Resources/Info.plist').read_text()
print('PASS1211 static production wiring: shared source toggle, no network/greeting side effects, independent base projections, v6 configuration notification, UI and version consistency.')
