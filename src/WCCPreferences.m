#import "WCCPreferences.h"
#import "WCCRuntime.h"
#import "WCCAssetKeys.h"
NSString * const WCCPreferencesChanged = @"WCCPreferencesChanged";
NSUserDefaults *WCCPrefs(void) { static NSUserDefaults *p; static dispatch_once_t once; dispatch_once(&once, ^{ p = [[NSUserDefaults alloc] initWithSuiteName:@"com.simon.ccweathermodule.custom"]; }); return p; }
NSArray<NSString *> *WCCSizeOptions(void) { return @[@"2x1", @"3x1", @"4x1", @"2x2", @"3x3"]; }
NSString *WCCSelectedSize(void) {
    id size = [WCCPrefs() objectForKey:@"moduleSize"];
    if (size) return [size isKindOfClass:NSString.class] && [WCCSizeOptions() containsObject:size] ? size : @"4x1";
    // 1.1.0 stored only columns. Missing/invalid legacy values fall back to 4x1.
    id old = [WCCPrefs() objectForKey:@"columns"];
    if ([old isKindOfClass:NSNumber.class] && [@[@2, @3, @4] containsObject:old])
        return [NSString stringWithFormat:@"%ldx1", (long)[old integerValue]];
    return @"4x1";
}
BOOL WCCSetSelectedSize(NSString *size) {
    if (![size isKindOfClass:NSString.class] || ![WCCSizeOptions() containsObject:size]) return NO;
    [WCCPrefs() setObject:size forKey:@"moduleSize"];
    NSArray *parts = [size componentsSeparatedByString:@"x"];
    [WCCPrefs() setInteger:[parts[0] integerValue] forKey:@"columns"];
    [WCCPrefs() setInteger:[parts[1] integerValue] forKey:@"rows"];
    return [WCCPrefs() synchronize];
}
WCCLayoutSize WCCEffectiveSize(void) {
    // One process-wide snapshot shared by container size and content geometry.
    static WCCLayoutSize size; static dispatch_once_t once;
    dispatch_once(&once, ^{
        size=(WCCLayoutSize){4,1};
        if ([WCCPrefs() boolForKey:@"customSize"]) {
            NSArray *parts=[WCCSelectedSize() componentsSeparatedByString:@"x"];
            size=(WCCLayoutSize){[parts[0] integerValue],[parts[1] integerValue]};
        }
    });
    return size;
}
BOOL WCCAllowedRoot(NSString *path) {
    if (![path isKindOfClass:NSString.class] || !path.isAbsolutePath) return NO;
    NSString *p = path.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    NSString *base = @"/var/mobile/Documents".stringByResolvingSymlinksInPath;
    NSString *icons = [base stringByAppendingPathComponent:@"CCWeatherModule/Icons"];
    // Permit the platform /var alias, not a user symlink redirect outside Icons.
    return [p isEqual:icons];
}
NSString *WCCRoot(void) {
    // One public import location; stale legacy `root` preferences must not redirect the gallery.
    return @"/var/mobile/Documents/CCWeatherModule/Icons";
}
NSString *WCCCheckedPath(NSString *root, NSString *name, NSString **reason) {
    if (reason) *reason = nil;
    if (!WCCAllowedRoot(root)) { if (reason) *reason = @"素材目录不在约定位置（或目录符号链接指向外部）"; return nil; }
    char resolved[PATH_MAX];
    WCCFileResult result = WCCValidateFile(root.fileSystemRepresentation,
        [name isKindOfClass:NSString.class] ? name.fileSystemRepresentation : NULL, resolved, sizeof(resolved));
    if (result == WCCFileOK) return [NSFileManager.defaultManager stringWithFileSystemRepresentation:resolved length:strlen(resolved)];
    NSArray *reasons = @[@"", @"文件名无效", @"目录不存在或无法读取", @"符号链接越出素材目录", @"不支持的扩展名（支持 PNG/JPG/JPEG/GIF/MP4）", @"文件不存在、链接失效或无法取得属性", @"不是普通文件（不递归子目录）", @"空文件", @"文件超过8MB", @"文件读取失败，请检查权限"];
    if (reason) *reason = reasons[result];
    return nil;
}
NSString *WCCSafePath(NSString *root, NSString *name) { return WCCCheckedPath(root, name, NULL); }

// Old `icon` is deliberately neither read nor migrated: keep files, require explicit binding.
NSString *WCCAssetKey(NSInteger code, BOOL night) {
    char key[128]; WCCAssetBasename((int)code, night, key, sizeof(key));
    return [NSString stringWithUTF8String:key];
}
NSArray<NSString *> *WCCAssetKeys(void) {
    static NSArray *keys; static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableOrderedSet *set=[NSMutableOrderedSet orderedSet];
        for (NSInteger code=0; code<48; code++) for (NSInteger night=0; night<2; night++) [set addObject:WCCAssetKey(code,night)];
        keys=set.array;
    }); return keys;
}
NSString *WCCMappedNameForKey(NSDictionary *mappings, NSString *key) {
    if (![key isKindOfClass:NSString.class] || ![WCCAssetKeys() containsObject:key] || ![mappings isKindOfClass:NSDictionary.class]) return nil;
    id name=mappings[key]; return [name isKindOfClass:NSString.class] && [name length] ? name : nil;
}
NSString *WCCMappedName(NSString *key) { return WCCMappedNameForKey([WCCPrefs() objectForKey:@"weatherIconMappings"],key); }
BOOL WCCSetMappedName(NSString *key, NSString *name) {
    if (![key isKindOfClass:NSString.class] || ![WCCAssetKeys() containsObject:key]) return NO;
    if (name && !WCCSafePath(WCCRoot(),name)) return NO;
    id stored=[WCCPrefs() objectForKey:@"weatherIconMappings"];
    NSMutableDictionary *map=[stored isKindOfClass:NSDictionary.class] ? [stored mutableCopy] : [NSMutableDictionary dictionary];
    if (name) map[key]=name; else [map removeObjectForKey:key];
    [WCCPrefs() setObject:map forKey:@"weatherIconMappings"];
    return [WCCPrefs() synchronize];
}
