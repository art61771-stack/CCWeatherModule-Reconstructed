"""Local static production wiring + compiled portable helpers; no UIKit claim."""
from pathlib import Path
import re, subprocess, tempfile, struct
p=Path(__file__).resolve().parents[1]
s=(p/'src/WCCSettings.m').read_text()
c=(p/'src/WCCContentViewController.m').read_text()
h=(p/'src/WCCHostObserver.m').read_text()
page=s.split('@implementation WCCWeatherMappings',1)[1].split('@end',1)[0]
assert '@interface WCCWeatherMappings : UITableViewController' in s
assert '按天气名称管理绑定' in s and 'UIModalPresentationPopover' in s
assert 'WCCWeatherMappings *gallery' in s
assert 'gallery.targetKey=WCCAssetKeys()[index.row]' in page
assert 'WCCSetMappedName(WCCAssetKeys()[index.row],nil)' in page
assert '[self.tableView reloadData]' in page
image=page.split('cell.imageView.image=nil;',1)[1].split('cell.textLabel.text=key',1)[0]
assert 'bundleForClass:WCCWeatherMappings.class' in image
assert 'pathForResource:key ofType:@"png"' in image
assert 'imageWithContentsOfFile:path' in image
assert 'UIImageRenderingModeAlwaysOriginal' in image
assert 'WCCMappedName' not in image and 'WCCRoot' not in image
assert 'setValue:' not in s and 'forKey:@"image"' not in s
assert 'CCWeatherModule_RESOURCE_DIRS = Resources' in (p/'Makefile').read_text()
with tempfile.TemporaryDirectory() as d:
    d=Path(d)
    # Enumerate exact compiled production keys, not a hand-maintained category list.
    f=d/'keys.c'
    f.write_text('#include "WCCAssetKeys.h"\nint main(){char b[128];for(int c=0;c<48;c++)for(int n=0;n<2;n++){WCCAssetBasename(c,n,b,sizeof b);puts(b);}return 0;}')
    subprocess.run(['cc','-I'+str(p/'src'),str(f),'-o',str(d/'keys')],check=True)
    names=set(subprocess.check_output([str(d/'keys')],text=True).splitlines())
    for name in names:
        data=(p/'Resources'/f'{name}.png').read_bytes()
        assert data[:8]==b'\x89PNG\r\n\x1a\n', name
        assert all(struct.unpack('>II',data[16:24])), name
    print(f'PASS: all {len(names)} categories / 96 code-night combinations have original bundle PNGs')
    for test in ['layout118','runtime115']:
        subprocess.run(['cc',str(p/'evidence'/f'{test}.c'),'-lm','-o',str(d/test)],check=True)
        subprocess.run([str(d/test)],check=True)
for f in (p/'src').glob('*'):
    if f.suffix not in ['.h','.m']: continue
    text=f.read_text()
    for bad in ['WCCDiagnostic','diagnosticValue','diagnosticsEnabled','diagnosticCounts','diagnosticABI','hostDiagnostics','host-diagnostics','diagnosticsFrom:','本地诊断']:
        assert bad not in text,(f,bad)
# Compiler #pragma clang diagnostic is not a user diagnostic feature.
for bad in ['writeToFile','NSJSONSerialization','WCCPrefs','Documents','removeItem']:
    assert bad not in h
for token in ['WCCConsumeHostEvent(&state,e,visible)','weakObjectsHashTable','modules.allObjects','@finally { notifying=previous; }','WCCABICompatible','method_getTypeEncoding','class_addMethod','method_setImplementation','*original=method_getImplementation(m)','if(installed)','if(!notifying && !state.visible)','NSThread.isMainThread']:
    assert token in h,token
for name in ['beginOriginal','presentOriginal','dismissOriginal','presentOldOriginal','dismissOldOriginal']:
    assert h.count(name)>=3,name
assert h.index('if(!modern&&!legacy)')<h.index('replace(cls,@"_beginPresentation')
for token in ['WCCObserveHostForModule(self)','WCCConsumeModuleHost','WCCCurrentHostState()','[self drawGreeting]','WCCPresentGreeting','WCCConsumeExpansion','WCCHostVisibilityChanged']:
    assert token in c,token
host=(p/'evidence/host115.m').read_text()
for token in ['assert(observed==2000)','assert(!weakModule)','assert(beforeCalls==1000)','assert(afterCalls==1000)','assert(begins==n+1&&state.generation==gen&&notices==notifications)','assert(!installed)']:
    assert token in host,token
assert 'WCCPrefs' not in host
for token in ['self.slider.minimumValue=-1; self.slider.maximumValue=1','self.expandedSlider.minimumValue=50;self.expandedSlider.maximumValue=150','WCCCollapsedSliderPosition(WCCMainIconPercentForMode(NO))','WCCCollapsedSliderPercent(slider.value)','WCCSetMainIconPercentForMode']:
    assert token in s
for token in ['WCCHourlyScrollView','WCCHourlyLayoutReady','scheduleHourlyLayoutValidation','hourlyLayoutGeneration']:
    assert token in c
print('PASS: native category navigation/clear/targetKey + original-only thumbnail + diagnostic removal + observer ABI/weak/original/session wiring; slider and first-visible gate retained')
print('NOT RUN: UIKit rendering, iOS host runtime, macOS Foundation host115 executable; no network/CI')
