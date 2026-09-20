#import "WCCPreferences.h"
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
    if (![WCCPrefs() boolForKey:@"customSize"]) return (WCCLayoutSize){4, 1};
    NSArray *parts = [WCCSelectedSize() componentsSeparatedByString:@"x"];
    return (WCCLayoutSize){[parts[0] integerValue], [parts[1] integerValue]};
}
BOOL WCCAllowedRoot(NSString *path) {
    if (![path isKindOfClass:NSString.class] || !path.isAbsolutePath) return NO;
    NSString *p = path.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    NSString *base = @"/var/mobile/Documents".stringByResolvingSymlinksInPath;
    return [p hasPrefix:[base stringByAppendingString:@"/"]];
}
NSString *WCCRoot(void) { NSString *p = [WCCPrefs() stringForKey:@"root"] ?: @"/var/mobile/Documents/CCWeatherModule/Icons"; return WCCAllowedRoot(p) ? p.stringByStandardizingPath.stringByResolvingSymlinksInPath : @"/var/mobile/Documents/CCWeatherModule/Icons"; }
NSString *WCCSafePath(NSString *root, NSString *name) {
    if (!WCCAllowedRoot(root) || ![name isKindOfClass:NSString.class] || !name.length || ![name.lastPathComponent isEqual:name] || [name isEqual:@"."] || [name isEqual:@".."]) return nil;
    NSString *base = root.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    NSString *p = [[base stringByAppendingPathComponent:name] stringByResolvingSymlinksInPath];
    if (![p.stringByDeletingLastPathComponent isEqual:base]) return nil;
    if (![@[@"png",@"jpg",@"jpeg",@"gif",@"mp4"] containsObject:p.pathExtension.lowercaseString]) return nil;
    NSDictionary *a = [NSFileManager.defaultManager attributesOfItemAtPath:p error:nil];
    if (![a[NSFileType] isEqual:NSFileTypeRegular] || [a[NSFileSize] unsignedLongLongValue] > 8*1024*1024) return nil;
    return p;
}
