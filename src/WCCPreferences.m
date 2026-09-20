#import "WCCPreferences.h"
NSString * const WCCPreferencesChanged = @"WCCPreferencesChanged";
NSUserDefaults *WCCPrefs(void) { static NSUserDefaults *p; static dispatch_once_t once; dispatch_once(&once, ^{ p = [[NSUserDefaults alloc] initWithSuiteName:@"com.simon.ccweathermodule.custom"]; }); return p; }
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
