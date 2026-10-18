from pathlib import Path
import re,subprocess,plistlib
p=Path(__file__).resolve().parents[1];s=p/'src'
c=(s/'WCCContentViewController.m').read_text();effects=(s/'WCCTextShadow.m').read_text();prefs=(s/'WCCPreferences.m').read_text()
def method(name):
 m=re.search(r'^- \([^\n]+\)'+re.escape(name)+r'[^\n]*\{',c,re.M);assert m,name
 a=c.index('{',m.start());i=a+1;depth=1
 while depth:depth+=(c[i]=='{')-(c[i]=='}');i+=1
 return c[m.start():i]
assert 'WCCApplyMainContentAnimations(_iconView,WCCMainContentSettings(0),WCCMainContentSettings(1),self.mediaVisible && !self.mediaSuspended && !self.presentedViewController && WCCCurrentHostState().visible)' in c
assert '[self applyTextShadows]' in method('refreshHourlyMedia')
for name in ['handleTwoFingerDoubleTap:','showCustomNameAlert','viewWillDisappear:','controlCenterDidDismiss','willResignActive']:
 assert '[self refreshHourlyMedia]' in method(name),name
assert 'WCCApplyMainContentAnimations' not in (s/'WCCMedia.m').read_text()
new=effects.split('void WCCApplyMainContentAnimations(')[1]
for bad in ['removeAllAnimations','loadPath','AVPlayer','shadowOpacity=','layer.transform=','layer.opacity=','icon.transform=']:assert bad not in new,bad
assert 'a.additive=YES' in new
assert '@"wcc.icon.opacity.breathe125"' in new and '@"wcc.icon.transform.scale125"' in new
assert 'WCCBreathDuration' in new
for file in ['WCCMedia.m','WCCHourly.h','WCCSettings.m','WCCNativeSettingsNavigation.m','WCCHostObserver.m']:
 baseline=subprocess.check_output(['git','show','c5685b444a5cef18f87327fd0dd9229cd81e5e91:src/'+file],cwd=p)
 assert (s/file).read_bytes()==baseline,file
# 1.2.7 intentionally adds greeting-only helpers to Runtime; 1.2.5 animation
# primitives and their callers remain present and unchanged in behavior.
assert 'WCCBreathDuration' in (s/'WCCRefreshPolicy.h').read_text()
info=plistlib.loads((p/'Resources/Info.plist').read_bytes());assert info['CFBundleVersion']==info['CFBundleShortVersionString']=='1.2.7'
assert 'Version: 1.2.7' in (p/'control').read_text()
print('PASS125 static: owner pause routing/settings visibility, independent animation keys, no media reload/hourly changes; original host/native routing/runtime unchanged; 1.2.5 metadata. No UIKit device execution.')
