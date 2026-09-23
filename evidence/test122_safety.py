#!/usr/bin/env python3
"""Self-contained SOURCE checks plus extraction for separate macOS Foundation execution."""
from pathlib import Path
import plistlib
p=Path(__file__).resolve().parents[1];s=p/'src';old=p/'evidence/fixtures122'
def method(text,start,end):return text.split(start,1)[1].split(end,1)[0]
c=(s/'WCCContentViewController.m').read_text();o=(old/'WCCContentViewController.m').read_text()
for start,end in [('- (void)handleDoubleTap:', '- (void)handleTwoFingerDoubleTap:'),('UITapGestureRecognizer *tap =','[self.view addGestureRecognizer:settingsTap];')]:
 assert method(c,start,end)==method(o,start,end),start
import source124_contract
source124_contract.verify(p)
config=(s/'WCCConfigurations.m').read_text(); previous=(old/'WCCConfigurations.m').read_text()
# Config schema evolves, but filesystem confinement and backup-before-commit stay.
for start,end in [('static BOOL WCCSafeConfigurationDirectory','static BOOL WCCSafeConfigurationFile'),('static NSString *WCCConfigPath','static NSDictionary *WCCValidatedConfiguration'),('BOOL WCCLoadConfiguration','BOOL WCCDeleteConfiguration')]:
 assert method(config,start,end)==method(previous,start,end),start
safe=method(config,'static BOOL WCCSafeConfigurationFile','static NSString *WCCConfigPath')
for guard in ['WCCSafeConfigurationDirectory(error)','lstat(path.fileSystemRepresentation,&st)','!S_ISREG(st.st_mode)','st.st_size<1','!mustExist && errno==ENOENT']:assert guard in safe
u=(s/'WCCSettings.m').read_text();f=(s/'WCCFloatingPanel.m').read_text()
assert 'WCCPanelMenu' not in u
assert 'addChildViewController' not in f and 'WCCPanelOverlay' not in f and 'WCCPanelStyleChanged' not in f
assert '[WCCSettings presentFrom:owner completion:completion]' in f
assert 'boolForKey:@"settingsPanelTransparent"' in f
n=(s/'WCCNativeSettingsNavigation.m').read_text()
assert 'UIPresentationController' in n and 'shouldRemovePresentersView { return NO; }' in n
assert 'configureWithTransparentBackground' in n and 'configureWithDefaultBackground' in n
assert 'sender.on forKey:@"settingsPanelTransparent"' in n
assert 'UIPanGestureRecognizer' not in f+n and 'addChildViewController' not in f+n
assert u.count('[[WCCNativeSettingsNavigation alloc] initWithRootViewController:')==4
assert u.count('WCCShow(p, nav, completion);')==4
assert 'WCCShow(p, a);' not in u
assert 'p.transitionCoordinator' in u and 'if (p.presentedViewController != a && rejected) rejected();' in u
assert 'session.finish=WCCOnce(completion);' in u and 'completion=WCCOnce(^{ if(session.ended)return;' in u
for n in ['WCCSettings.m','WCCRegionSettings.m','WCCWeatherSettings.m']:
 t=(s/n).read_text();assert 'popViewControllerAnimated' not in t
 assert 'self.onDone=nil; if(done) [self dismissViewControllerAnimated:YES completion:done];' in t
 assert 'popoverPresentationControllerShouldDismissPopover:' in t
assert 'WCCCollapsedSliderPercent(self.slider.value)' in u
assert 'self.expandedSlider.minimumValue=50;self.expandedSlider.maximumValue=150' in u
info=plistlib.loads((p/'Resources/Info.plist').read_bytes());assert info['CFBundleVersion']=='1.2.4' and info['CFBundleShortVersionString']=='1.2.4'
assert 'Version: 1.2.4' in (p/'control').read_text()
helpers=u[u.index('static void (^WCCOnce'):u.index('@interface WCCSettingsGallery')]
entry='- (void)handleTwoFingerDoubleTap:'+method(c,'- (void)handleTwoFingerDoubleTap:','- (void)showCustomNameAlert')
done='- (void)done {'+method(u,'- (void)done {','- (UIModalPresentationStyle)')
stub=(p/'evidence/route122-stub.inc').read_text().replace('// INSERT_HELPERS',helpers).replace('// INSERT_ENTRY',entry).replace('// INSERT_DONE',done)
import sys
if '--generate' in sys.argv:
 import subprocess
 subprocess.run([sys.executable,str(p/'evidence/generate-route124.py')],check=True)
print('PASS122 static: native routing/rejection, no floating construction/menu/notifications, modal once-done, 122 byte-identical gestures, 124 provider TTL-only/source guards and config confinement/rollback; 124 metadata. NOT UIKit runtime.')
