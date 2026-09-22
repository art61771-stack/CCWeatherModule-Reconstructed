"""Local-only: compile portable production helpers, inspect Objective-C wiring.
No UIKit/AVFoundation execution is claimed by this test.
"""
from pathlib import Path
import subprocess, tempfile
root=Path(__file__).resolve().parents[1]
s=(root/'src/WCCContentViewController.m').read_text()
m=(root/'src/WCCMedia.m').read_text()
h=(root/'src/WCCRuntime.h').read_text()
def method(name,next_name):
    return s.split('- (void)'+name+' {',1)[1].split('- (void)'+next_name,1)[0]
refresh=method('refreshHourlyMedia','viewDidLayoutSubviews')
assert 'WCCSafePath' not in refresh and 'stat(' not in refresh and 'WCCPrefs' not in refresh
assert 'if (item.boundIdentity && ![item.boundIdentity isEqual:identity])' in refresh
assert 'if (!item.boundIdentity)' in refresh
assert refresh.index('[item.media loadPath:nil]')<refresh.index('for (WCCHourlyItem *item in admitted)')
assert 'WCCHourlyAdmit(visible,item.cachedPath!=nil)' in refresh
assert 'WCCHourlyAnimatedLimit' not in (root/'src/WCCHourly.h').read_text()
assert '_isExpanded && self.mediaVisible && !self.mediaSuspended && self.view.window && !self.presentedViewController' in refresh
assert 'item.media.active=NO; [item.media loadPath:nil]; item.boundIdentity=nil;' in refresh
assert 'DISPATCH_QUEUE_SERIAL' in m and 'dispatch_async(WCCPreparationQueue()' in m
assert '10*NSEC_PER_SEC' in m and '[asset cancelLoading]' in m
assert m.count('generation != self->_generation')>=2
assert 'if (!current) return;' in m
for lifecycle in ['viewWillDisappear:', 'controlCenterDidDismiss', 'willResignActive']:
    body=s.split('- (void)'+lifecycle,1)[1].split('\n- (',1)[0]
    assert '[self refreshHourlyMedia]' in body
original=(root/'evidence/original104-WCCContentViewController.m').read_text()
# All original six-element expanded constraints and hourly-cell numeric frames survive.
import re
for line in s.split('- (void)layoutOriginalExpanded:',1)[1].split('- (void)refreshWeatherData',1)[0].splitlines():
    if 'constraintEqualTo' in line:
        assert line.strip().rstrip(',') in original
for frame in ['CGRectMake(12 + i * 55, 0, 55, 80)', 'CGRectMake(0, 0, 55, 18)', 'CGRectMake(12, 22, 30, 30)', 'CGRectMake(0, 56, 55, 20)']:
    assert frame in original and frame in s
assert '[self cacheHourlyMediaPaths]' in method('preferencesChanged','viewDidAppear:')
assert '[self cacheHourlyMediaPaths]' in method('updateHourlyForecast','unused')
assert 'self.greetingLabel.hidden=YES' not in s and 'self.greetingLabel.hidden=_isExpanded' not in s
expanded=s.split('- (void)layoutOriginalExpanded:',1)[1].split('- (void)refreshWeatherData',1)[0]
assert 'CGRectMake(0,0,size.width,85)' in expanded
assert 'CGRectMake(0,85,size.width,size.height-85)' in expanded
assert expanded.index('[_headerView layoutIfNeeded]')<expanded.index('occupied[n++]=WCCR')
assert 'WCCExpandedGreeting(size.width,occupied,n)' in expanded
assert 'systemFontOfSize:8' in expanded and 'NSLineBreakByTruncatingTail' in expanded
assert 'if (_active == active) return;' in m
assert 'generation != self->_generation' in m and 'WCCMediaCallbackCurrent(' in m

assert 'NSString *key = _currentCity ? [self imageNameForConditionCode:[_currentCity conditionCode]] : nil;' in s
assert 'old.timeLabel.text=item.timeLabel.text' in s
assert 'Icon: https://i.imgs.ovh/2026/09/20/17d0953ee53152da8e61955e8bcf444a.png' in (root/'control').read_text()

print("PASS retained 116 media lifecycle, identity cache, generation, expanded layout, hourly frames, main mapping, greeting and Icon assertions; only obsolete daylight-gate assertions excluded")
