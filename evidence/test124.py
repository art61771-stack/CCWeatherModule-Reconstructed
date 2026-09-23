from pathlib import Path
import subprocess,tempfile
p=Path(__file__).resolve().parents[1];s=p/'src'
def read(n):return (s/n).read_text()
c=read('WCCContentViewController.m');route=read('WCCSettings.m');effect=read('WCCTextShadow.m');source=read('WCCWeatherSource.m');provider=read('CYCaiyunProvider.m')
assert c.count('arc4random')==2
for name in ['regionPositionChanged','applyTextShadows','layoutMainCustomMedia','applyRegionPositions']:
 t=c.split('- (void)'+name+' {',1)[1].split('\n- (',1)[0];assert 'drawGreeting' not in t and 'loadPath' not in t and 'arc4random' not in t
assert 'WCCInformationAlignment(WCCRegionOffset(4)' in c
assert c.index('WCCInformationAlignment(WCCRegionOffset(4)')<c.index('CGRect text=[label textRectForBounds')
assert 'WCCMainIconTargetForLayout' in c
assert 'setAutomaticActive:self.mediaVisible' in c and 'UIApplicationDidEnterBackgroundNotification' in c and 'UIApplicationProtectedDataWillBecomeUnavailable' in c
assert '[self applyTextShadows]' in c.split('- (void)renderWeatherIcon {')[1].split('\n- (')[0]
assert 'NSTimer scheduledTimerWithTimeInterval:delay repeats:NO' in source and 'self.provider.cacheTTL=self.refreshTTL' in source
assert 'generation!=self.generation || epoch!=self.requestEpoch' in source
assert 'age<(self.cacheTTL>0?self.cacheTTL:900)' in provider and 'age>=(self.cacheTTL>0?self.cacheTTL:900)' in provider
# Provider parser, Keychain, transport success/cancellation logic unchanged, except TTL comparisons.
baseline=subprocess.check_output(['git','show','3b37db575ae45c1f9122854d663bc0f8ca7286c6:src/CYCaiyunProvider.m'],cwd=p,text=True)
assert provider.replace('age<(self.cacheTTL>0?self.cacheTTL:900)','age<900').replace('age>=(self.cacheTTL>0?self.cacheTTL:900)','age>=900')==baseline
for token in ['WCCRouteCanEnter','WCCRouteCanReturn','WCCRouteOwnsDismiss','session.ended=YES','session.finish=nil','root.isBeingPresented && root.transitionCoordinator','WCCReturn(p,^{'] :assert token in route,token
assert '[WCCSettings cancelFrom:self]' in c
assert 'addChildViewController' not in route and 'makeKeyAndVisible' not in route
assert effect.count('animationWithKeyPath:@"shadowOpacity"')==2
assert 'removeAllAnimations' not in effect and 'WCCEffectOpacity' in effect and 'WCCEffectLow' in effect
assert 'wcc.icon.shadowOpacity.breathe124' in effect and 'wcc.text.shadowOpacity.breathe124' in effect
assert 'layer.shadowPath=video?' in effect
# The three text groups and independent icon use the same new production standard.
assert 'double standard=WCCEffectStandardOpacity124;' in effect
assert 'WCCEffectOpacity(standard,' in effect and 'WCCEffectLow(high,standard)' in effect
assert 'WCCEffectOpacity(WCCEffectStandardOpacity124,' in effect
assert 'WCCEffectLow(layer.shadowOpacity,WCCEffectStandardOpacity124)' in effect
assert 'NSArray *settings=WCCTextEffectSettings(index++);' in c
assert 'WCCTextEffectSettings(3)' in c
assert '@"textEffect124_%ld"' in read('WCCPreferences.m')
assert ':@[@[],@NO,@0,@0]' in read('WCCPreferences.m')
assert 'alpha:[rgba[3] doubleValue]' in effect and 'alpha:[c[3] doubleValue]' in effect
assert 'label.alpha=' not in effect and 'icon.alpha=' not in effect
assert '右侧饱和' not in read('WCCRegionSettings.m')
assert 'AVMediaTypeAudio' not in read('WCCMedia.m')
assert 'UIColorPickerViewController' in read('WCCRegionSettings.m') and '颜色浓淡' in read('WCCRegionSettings.m')
with tempfile.TemporaryDirectory() as d:
 subprocess.run(['cc','-Wall','-Wextra',str(p/'evidence/runtime124.c'),'-lm','-o',d+'/test'],check=True);subprocess.run([d+'/test'],check=True)
print('PASS124 SOURCE guards: provider unchanged except TTL; native session ownership; colors/four groups/density; event-only RNG; no hourly/no audio; not UIKit verification')
