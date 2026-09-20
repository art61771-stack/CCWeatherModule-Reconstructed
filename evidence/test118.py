"""Generate a macOS Foundation harness from exact production Objective-C methods.
No UIKit/AVFoundation/iOS16 runtime claim. Run --generate then clang on macOS.
"""
from pathlib import Path
import sys
r=Path(__file__).resolve().parents[1]
s=(r/'src/WCCContentViewController.m').read_text()
def method(signature):
    start=s.index(signature); end=s.find('\n- (',start+1)
    if end<0: end=s.index('\n@end',start)
    return s[start:end]
resolver=method('- (UIImage *)systemWeatherImageForConditionCode:(NSInteger)code selectedAssetKey:')
create=method('- (UIView *)createHourlyItemWithForecast:')
refresh=method('- (void)refreshHourlyMedia {')
assert 'WCCHourlyDaylight' not in s
assert 'selectedAssetKey:&selectedKey' in create and 'item.assetKey=selectedKey' in create
assert 'imageNamed:name' in resolver and '*selectedKey=name' in resolver
assert 'WCCSafePath' not in refresh and 'stat(' not in refresh
assert 'WCCBalanceMeasuredStrip' in s
assert 'current.originalIcon.hidden=current.media.hasMedia' in create
assert 'WCCHourlyAnimatedLimit' not in s
# Compile exact method bodies, not a parallel reproduction of their decisions.
pre=(r/'evidence/hourly118-stub.inc').read_text()
post=(r/'evidence/hourly118-main.inc').read_text()
keymethod=(r/'src/ConditionTables.m').read_text().split('- (NSString *)imageNameForConditionCode:',1)[1].split('\n@end',1)[0]
out=pre+'\n- (NSString *)imageNameForConditionCode:'+keymethod+'\n'+resolver+'\n'+create+'\n'+refresh+'\n'+method('- (void)scheduleHourlyLayoutValidation {')+'\n'+method('- (void)didTransitionToExpandedContentMode:')+'\n@end\n'+post
if '--generate' in sys.argv:
    (r/'evidence/hourly118-generated.m').write_text(out)
print('PASS 118 source linkage; Objective-C executable requires macOS Foundation; iOS16 NOT RUN')
