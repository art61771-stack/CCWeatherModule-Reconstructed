import pathlib,json,shutil,hashlib
root=pathlib.Path(__file__).resolve().parent.parent
t=json.loads((root/'evidence/tables.json').read_text())
out=['// Generated from arm64 dictionary construction, jump table and pointer table.\n#import "WCCContentViewController.h"\n@implementation WCCContentViewController (RecoveredConditionTables)\n']
for name,key,default in [('localizedConditionForCode','conditions','--'),('sfSymbolForConditionCode','symbols','cloud.fill')]:
 out.append('- (NSString *)%s:(NSInteger)code {\n    NSArray *table = @[\n'%name)
 out.extend('        @"'+s+'", // '+str(i)+'\n' for i,s in enumerate(t[key]))
 out.append('    ];\n    return code >= 0 && code < 48 ? table[code] : @"'+default+'";\n}\n')
out.append('- (NSString *)imageNameForConditionCode:(NSInteger)code {\n    BOOL night = _currentCity && [_currentCity respondsToSelector:@selector(isDay)] && ![_currentCity isDay];\n    NSArray *table = @[\n')
out.extend('        @"'+s+'", // '+str(i)+'\n' for i,s in enumerate(t['images']))
out.append('    ];\n    NSString *name = code >= 0 && code < 48 ? table[code] : @"多云-%@";\n    return [NSString stringWithFormat:name, night ? @"夜间" : @"白天"];\n}\n@end\n')
(root/'src/ConditionTables.m').write_text(''.join(out))
source=root/'package/var/jb/Library/ControlCenter/Bundles/CCWeatherModule.bundle'
resources=root/'Resources';resources.mkdir(exist_ok=True)
manifest=[]
for p in sorted(source.iterdir()):
 if p.name=='CCWeatherModule':continue
 dest=resources/p.name;shutil.copyfile(p,dest)
 manifest.append(hashlib.sha256(dest.read_bytes()).hexdigest()+'  Resources/'+p.name)
(root/'evidence/resources.sha256').write_text('\n'.join(manifest)+'\n')
shutil.copyfile(root/'package/control/control',root/'control')
print('Resources:',len(manifest),'files; generated table entries:',sum(map(len,t.values())))
