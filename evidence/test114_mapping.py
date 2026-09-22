from pathlib import Path
import json,re
r=Path(__file__).resolve().parents[1]
s=lambda f:(r/'src'/f).read_text()
h=s('WCCAssetKeys.h'); original=json.loads((r/'evidence/tables.json').read_text())['images']
templates=re.findall(r'^    "(.*?)",',h,re.M)
assert templates==original,(templates,original)
assert 'return WCCAssetKey(code, night)' in s('ConditionTables.m')
c=s('WCCContentViewController.m'); p=s('WCCPreferences.m'); g=s('WCCGallery.m'); m=s('WCCMedia.m'); settings=s('WCCSettings.m')
assert 'boolForKey:@"customIcon"] ? WCCSafePath(WCCRoot(), WCCMappedName(key)) : nil' in c
assert '[self.customMedia loadPath:nil]; self.mediaAssetKey=key;' in c
assert '[self.customMedia loadPath:path]' in c
assert 'self.customMedia.hasMedia' in c and '[self systemWeatherImageForConditionCode:code]' in c
assert 'stringForKey:@"icon"' not in p+c+g and 'forKey:@"icon"' not in g
assert 'gallery.targetKey=WCCAssetKeys()[index.row]' in settings
assert 'WCCSetMappedName(WCCAssetKeys()[index.row],nil)' in settings
assert 'WCCSetMappedName(self.targetKey,name)' in g and '!_preview.hasMedia' in g
assert 'WCCMediaCallbackCurrent(generation,self->_generation,object==self->_layer || object==self->_player || object==self->_looper)' in m
assert 'generation != self->_generation' in m
assert '[_path isEqual:path] && [_identity isEqual:identity]' in m
assert 'st.st_mtimespec.tv_nsec' in m and 'st.st_ctimespec.tv_nsec' in m
print('PASS recovered 48 resource templates exactly; Settings->target Gallery->validated mapping->live Controller->media; legacy ignored; fallback; stat cache and asynchronous guards. Static assertions, not device playback.')
