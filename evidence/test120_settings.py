#!/usr/bin/env python3
"""Source wiring only, NOT Objective-C/Foundation/UIKit execution."""
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'src'
s={x.stem:x.read_text() for x in p.glob('*.m')}
h=(p/'WCCPreferences.h').read_text(); prefs=s['WCCPreferences']; ui=s['WCCSettings']; regions=s['WCCRegionSettings']; controller=s['WCCContentViewController']; config=s['WCCConfigurations']
checks=0
def check(value):
 global checks
 assert value
 checks+=1
for api in ['WCCMainIconPercentForMode','WCCSetMainIconPercentForMode','WCCTextShadowEnabled','WCCSetTextShadowEnabled','WCCCustomGreetingEnabled','WCCCustomGreetingText','WCCSetCustomGreeting','WCCNormalizePresentationValues']:
 check(api in h and api in prefs)
check('WCCMainIconPercentForMode(_isExpanded)' in controller)
check('self.expandedSlider.minimumValue=50;self.expandedSlider.maximumValue=150' in ui)
check('WCCSetMainIconPercentForMode(slider.tag==1,slider.value)' in ui)
check('WCCScaleKeys()[1]:@(WCCMainIconPercentForMode(YES))' in prefs)
check('WCCNormalizePositionOffset((int)index' in prefs)
check('slider.minimumValue=tag%2?-40:-1366' in regions)
check('@selector(step:)' in regions and '@selector(enterOffset:)' in regions)
check('fmax(-limit,fmin(limit,' in regions)
check('WCCSetTextShadowEnabled(sender.tag,sender.on)' in regions)
check('WCCSetCustomGreeting(WCCCustomGreetingEnabled(),text)' in regions)
check('text.length>80' in prefs)
check('if(WCCCustomGreetingEnabled()){[self bindGreetingText];return;}' in controller)
check('self.greetingLabel.text=WCCCustomGreetingText()' in controller)
check('self.customGreetingWasEnabled=NO;' in controller)
local=controller.split('- (void)regionPositionChanged {')[1].split('- (void)mainIconScaleChanged')[0]
check('[self bindGreetingText]' in local and 'drawGreeting' not in local and 'refreshWeather' not in local)
check('@"version":@2' in config)
check('WCCNormalizePresentationValues(object[@"values"]' in config)
check(config.index('if(!WCCWriteConfiguration(WCCBackupID')<config.index('if (!WCCCommitSliderValues(values))'))
check('NSDataWritingAtomic' in config and 'NSUUID.UUID.UUIDString' in config)
check('setPersistentDomain:before' in prefs)
check('CFBooleanGetTypeID' in prefs and 'isfinite(n)' in prefs)
check('if(![keys containsObject:key])return nil' in prefs)
check('version==1?@"mainCustomIconPercent":key' in prefs)
check('data.length>16384' in config)
check('setValue:slider' not in ui and 'contentViewController' not in regions)
print(f'PASS {checks} static120 settings wiring assertions (not Foundation/UIKit runtime)')
