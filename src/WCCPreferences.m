#import "WCCPreferences.h"
#import <CoreFoundation/CoreFoundation.h>
#import <dispatch/dispatch.h>
#import "WCCRuntime.h"
#import "WCCAssetKeys.h"
NSString * const WCCPreferencesChanged = @"WCCPreferencesChanged";
NSString * const WCCMainIconScaleChanged = @"WCCMainIconScaleChanged";
NSString * const WCCRegionPositionChanged = @"WCCRegionPositionChanged";
NSArray<NSString *> *WCCRegionPositionKeys(void) {
    return @[@"temperatureOffsetX",@"temperatureOffsetY",@"mainIconOffsetX",@"mainIconOffsetY",
             @"informationOffsetX",@"informationOffsetY",@"greetingOffsetX",@"greetingOffsetY"];
}
static BOOL WCCNumber(id v) { return [v isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID(); }
static NSArray *WCCScaleKeys(void) { return @[@"mainIconCollapsedPercent",@"mainIconExpandedPercent"]; }
static NSArray *WCCShadowKeys(void) { return @[@"temperatureShadow",@"informationShadow",@"greetingShadow"]; }
static BOOL WCCCommitPartial(NSDictionary *values);
BOOL WCCSetCaiyunRefreshHours(NSInteger hours) {
    if(hours!=1 && hours!=12 && hours!=24)return NO;
    return WCCCommitPartial(@{@"caiyunRefreshHours124":@(hours)});
}
static void WCCNotify(NSString *name) {
    void (^work)(void)=^{[NSNotificationCenter.defaultCenter postNotificationName:name object:nil];};
    if(NSThread.isMainThread)work(); else dispatch_async(dispatch_get_main_queue(),work);
}
double WCCRegionOffset(NSInteger index) {
    if(index<0 || index>=8)return 0;
    id v=[WCCPrefs() objectForKey:WCCRegionPositionKeys()[index]];
    return WCCNumber(v)?WCCNormalizePositionOffset((int)index,[v doubleValue]):0;
}
BOOL WCCSetRegionOffset(NSInteger index,double value) {
    if(index<0 || index>=8 || !isfinite(value))return NO;
    BOOL ok=WCCCommitPartial(@{WCCRegionPositionKeys()[index]:@(WCCNormalizePositionOffset((int)index,value))});
    if(ok)WCCNotify(WCCRegionPositionChanged); return ok;
}
BOOL WCCResetRegionOffsets(NSInteger region) {
    if(region < -1 || region>3)return NO;
    NSMutableDictionary *v=[NSMutableDictionary dictionary];
    for(NSInteger i=0;i<8;i++)if(region==-1 || i/2==region)v[WCCRegionPositionKeys()[i]]=@0;
    BOOL ok=WCCCommitPartial(v); if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
double WCCMainIconPercentForMode(BOOL expanded) {
    id v=[WCCPrefs() objectForKey:WCCScaleKeys()[expanded?1:0]];
    if(!v)v=[WCCPrefs() objectForKey:@"mainCustomIconPercent"];
    return WCCNumber(v)?WCCNormalizeIconPercentForMode(expanded,[v doubleValue]):100;
}
double WCCMainIconPercent(void) { return WCCMainIconPercentForMode(NO); }
BOOL WCCSetMainIconPercentForMode(BOOL expanded,double value) {
    if(!isfinite(value))return NO;
    // Materialize BOTH migration defaults atomically before editing one mode.
    NSMutableDictionary *v=[@{WCCScaleKeys()[0]:@(WCCMainIconPercentForMode(NO)),WCCScaleKeys()[1]:@(WCCMainIconPercentForMode(YES))} mutableCopy];
    v[WCCScaleKeys()[expanded?1:0]]=@(WCCNormalizeIconPercentForMode(expanded,value));
    BOOL ok=WCCCommitPartial(v);if(ok)WCCNotify(WCCMainIconScaleChanged);return ok;
}
BOOL WCCSetMainIconPercent(double value) { return WCCSetMainIconPercentForMode(NO,value); }
BOOL WCCTextShadowEnabled(NSInteger group) {
    if(group==3)return [WCCPrefs() boolForKey:@"mainIconShadow124"];
    if(group<0 || group>2)return NO;
    id v=[WCCPrefs() objectForKey:WCCShadowKeys()[group]];
    return [v isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)v)==CFBooleanGetTypeID() && [v boolValue];
}
BOOL WCCSetTextShadowEnabled(NSInteger group,BOOL enabled) {
    if(group==3){BOOL ok=WCCCommitPartial(@{@"mainIconShadow124":@(enabled)});if(ok)WCCNotify(WCCRegionPositionChanged);return ok;}
    if(group<0 || group>2)return NO;
    BOOL ok=WCCCommitPartial(@{WCCShadowKeys()[group]:@(enabled)});if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
NSString *WCCCustomGreetingText(void) {
    id v=[WCCPrefs() objectForKey:@"customGreetingText"];
    return [v isKindOfClass:NSString.class] && [v length]<=80?v:@"";
}
BOOL WCCCustomGreetingEnabled(void) {
    id v=[WCCPrefs() objectForKey:@"customGreetingEnabled"];
    return [v isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)v)==CFBooleanGetTypeID() && [v boolValue] ;
}
BOOL WCCSetCustomGreeting(BOOL enabled,NSString *text) {
    if(![text isKindOfClass:NSString.class])return NO;
    text=[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(text.length>80 || (enabled && !text.length && !WCCGreetingEntries().count) || [text rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound)return NO;
    BOOL ok=WCCCommitPartial(@{@"customGreetingEnabled":@(enabled),@"customGreetingText":text});
    if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
// A missing list is a virtual migration of the old fixed text, never a write on read.
NSArray<NSDictionary *> *WCCGreetingEntries(void) {
    id saved=[WCCPrefs() objectForKey:@"greetingEntries122"];
    if([saved isKindOfClass:NSArray.class]) {
        NSMutableArray *out=[NSMutableArray array]; NSMutableSet *ids=[NSMutableSet set];
        for(id row in saved) if([row isKindOfClass:NSDictionary.class] &&
            [row[@"id"] isKindOfClass:NSString.class] && [row[@"id"] length] &&
            [row[@"text"] isKindOfClass:NSString.class] && [row[@"text"] length] && ![ids containsObject:row[@"id"]]) {
            [out addObject:@{@"id":row[@"id"],@"text":row[@"text"]}]; [ids addObject:row[@"id"]];
        }
        return out;
    }
    NSString *old=WCCCustomGreetingText();
    return old.length?@[@{@"id":@"legacy-fixed",@"text":old}]:@[];
}
NSArray<NSString *> *WCCGreetingCandidates(void) {
    NSMutableArray *out=[NSMutableArray array];
    for(NSDictionary *row in WCCGreetingEntries()) {
        NSString *text=[row[@"text"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if(text.length && ![out containsObject:text]) [out addObject:text];
    }
    return out;
}
BOOL WCCSaveGreetingEntry(NSString *identifier,NSString *text) {
    if(![text isKindOfClass:NSString.class])return NO;
    text=[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(!text.length || [text rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound)return NO;
    NSMutableArray *rows=[WCCGreetingEntries() mutableCopy];
    if(identifier) {
        NSUInteger i=[rows indexOfObjectPassingTest:^BOOL(NSDictionary *row,NSUInteger index,BOOL *stop){return [row[@"id"] isEqual:identifier];}];
        if(i==NSNotFound)return NO;
        rows[i]=@{@"id":identifier,@"text":text};
    } else [rows addObject:@{@"id":NSUUID.UUID.UUIDString,@"text":text}];
    BOOL ok=WCCCommitPartial(@{@"greetingEntries122":rows});
    if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
BOOL WCCDeleteGreetingEntry(NSString *identifier) {
    NSMutableArray *rows=[WCCGreetingEntries() mutableCopy];
    NSUInteger i=[rows indexOfObjectPassingTest:^BOOL(NSDictionary *row,NSUInteger index,BOOL *stop){return [row[@"id"] isEqual:identifier];}];
    if(i==NSNotFound)return NO; [rows removeObjectAtIndex:i];
    BOOL ok=WCCCommitPartial(@{@"greetingEntries122":rows});
    if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
BOOL WCCRandomGreetingEnabled(void) { return [WCCPrefs() boolForKey:@"randomGreeting122"]; }
BOOL WCCSetRandomGreetingEnabled(BOOL enabled) {
    BOOL ok=WCCCommitPartial(@{@"randomGreeting122":@(enabled)});
    if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
static NSArray *WCCGlowKeys(void) { return @[@"temperatureGlow122",@"informationGlow122",@"greetingGlow122"]; }
BOOL WCCTextGlowEnabled(NSInteger group) { if(group==3)return [WCCPrefs() boolForKey:@"mainIconGlow124"]; return group>=0 && group<3 && [WCCPrefs() boolForKey:WCCGlowKeys()[group]]; }
BOOL WCCSetTextGlowEnabled(NSInteger group,BOOL enabled) {
    if(group==3){BOOL ok=WCCCommitPartial(@{@"mainIconGlow124":@(enabled)});if(ok)WCCNotify(WCCRegionPositionChanged);return ok;}
    if(group<0 || group>2)return NO;
    BOOL ok=WCCCommitPartial(@{WCCGlowKeys()[group]:@(enabled)});
    if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
// [RGBA array (empty = original automatic color), breathing flag, speed -1..1, density -1..1]
static NSString *WCCEffectKey(NSInteger group) { return [NSString stringWithFormat:@"textEffect124_%ld",(long)group]; }
static BOOL WCCValidEffect(id v) {
    if(![v isKindOfClass:NSArray.class] || ([v count]!=3 && [v count]!=4))return NO;
    id color=v[0],on=v[1],speed=v[2];
    if([v count]==4 && (!WCCNumber(v[3]) || !isfinite([v[3] doubleValue]) || fabs([v[3] doubleValue])>1))return NO;
    if(![color isKindOfClass:NSArray.class] || ([color count]!=0 && [color count]!=4))return NO;
    for(id n in color)if(!WCCNumber(n) || !isfinite([n doubleValue]) || [n doubleValue]<0 || [n doubleValue]>1)return NO;
    return [on isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)on)==CFBooleanGetTypeID() && WCCNumber(speed) && isfinite([speed doubleValue]) && fabs([speed doubleValue])<=1;
}
NSArray *WCCTextEffectSettings(NSInteger group) {
    id v=group>=0 && group<4?[WCCPrefs() objectForKey:WCCEffectKey(group)]:nil;
    return WCCValidEffect(v)?([v count]==3?[v arrayByAddingObject:@0]:v):@[@[],@NO,@0,@0];
}
BOOL WCCSetTextEffectSettings(NSInteger group,NSArray *settings) {
    if(group<0 || group>3 || !WCCValidEffect(settings))return NO;
    BOOL ok=WCCCommitPartial(@{WCCEffectKey(group):settings.count==3?[settings arrayByAddingObject:@0]:settings});
    if(ok)WCCNotify(WCCRegionPositionChanged);return ok;
}
NSDictionary *WCCNormalizePresentationValues(NSDictionary *input,NSInteger version) {
    if(![input isKindOfClass:NSDictionary.class] || (version!=1 && version!=2 && version!=3 && version!=4))return nil;
    NSArray *keys=version==1?[WCCRegionPositionKeys() arrayByAddingObject:@"mainCustomIconPercent"]:[[[WCCRegionPositionKeys() arrayByAddingObjectsFromArray:WCCScaleKeys()] arrayByAddingObjectsFromArray:WCCShadowKeys()] arrayByAddingObjectsFromArray:@[@"customGreetingEnabled",@"customGreetingText"]];
    if(version>=3)keys=[[keys arrayByAddingObjectsFromArray:WCCGlowKeys()] arrayByAddingObjectsFromArray:@[@"randomGreeting122",@"greetingEntries122"]];
    if(version==4)keys=[keys arrayByAddingObjectsFromArray:@[WCCEffectKey(0),WCCEffectKey(1),WCCEffectKey(2),WCCEffectKey(3),@"mainIconShadow124",@"mainIconGlow124"]];
    for(id key in input)if(![keys containsObject:key])return nil;
    NSMutableDictionary *out=[NSMutableDictionary dictionary];
    for(NSInteger i=0;i<8;i++) {
        id v=input[WCCRegionPositionKeys()[i]]?:@0;double n=WCCNumber(v)?[v doubleValue]:NAN;
        if(!isfinite(n) || n!=WCCNormalizePositionOffset((int)i,n) || (version==1 && fabs(n)>40))return nil;
        out[WCCRegionPositionKeys()[i]]=@(n);
    }
    for(NSString *key in WCCScaleKeys()) {
        id v=input[version==1?@"mainCustomIconPercent":key]?:@100;double n=WCCNumber(v)?[v doubleValue]:NAN;
        if(!isfinite(n) || n!=WCCNormalizeIconPercentForMode(version==1 || [key isEqual:@"mainIconExpandedPercent"],n))return nil;out[key]=@(n);
    }
    for(NSString *key in [WCCShadowKeys() arrayByAddingObject:@"customGreetingEnabled"]) {
        id v=input[key]?:@NO;
        if(![v isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID())return nil;out[key]=v;
    }
    id text=input[@"customGreetingText"]?:@"";
    if(![text isKindOfClass:NSString.class] || [text length]>80 || [text rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound)return nil;
    if(version>=3) {
        for(NSString *key in [WCCGlowKeys() arrayByAddingObject:@"randomGreeting122"]) {
            id v=input[key]?:@NO;
            if(![v isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID())return nil;
            out[key]=v;
        }
        id rows=input[@"greetingEntries122"]?:@[];
        if(![rows isKindOfClass:NSArray.class])return nil;
        NSMutableSet *ids=[NSMutableSet set];
        for(id row in rows) {
            if(![row isKindOfClass:NSDictionary.class] || [row count]!=2)return nil;
            id identifier=row[@"id"], value=row[@"text"];
            if(![identifier isKindOfClass:NSString.class] || ![identifier length] || [ids containsObject:identifier] || ![value isKindOfClass:NSString.class] || ![value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length || [value rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound)return nil;
            [ids addObject:identifier];
        }
        out[@"greetingEntries122"]=rows;
    }
    if([out[@"customGreetingEnabled"] boolValue] && ![text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length && (version<3 || [text length]>0))return nil;
    if(version==4)for(NSInteger i=0;i<4;i++){id v=input[WCCEffectKey(i)]?:@[@[],@NO,@0,@0];if(!WCCValidEffect(v))return nil;out[WCCEffectKey(i)]=[v count]==3?[v arrayByAddingObject:@0]:v;}
    if(version==4)for(NSString *key in @[@"mainIconShadow124",@"mainIconGlow124"]){id v=input[key]?:@NO;if(![v isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID())return nil;out[key]=v;}
    // v1/v2 intentionally leave new preferences untouched; v3 snapshots all.
    out[@"customGreetingText"]=text;return out;
}
static NSString *WCCPreferenceSuite=@"com.simon.ccweathermodule.custom";
static NSUserDefaults *WCCPreferenceStore;
#ifdef WCC_TESTING
static BOOL WCCCommitFailure;
void WCCTestUsePreferences(NSString *suite) { WCCPreferenceSuite=[suite copy]; WCCPreferenceStore=nil; }
void WCCTestFailCommit(BOOL fail) { WCCCommitFailure=fail; }
#endif
NSUserDefaults *WCCPrefs(void) {
    if (!WCCPreferenceStore) WCCPreferenceStore=[[NSUserDefaults alloc] initWithSuiteName:WCCPreferenceSuite];
    return WCCPreferenceStore;
}
BOOL WCCCommitSliderValues(NSDictionary *values) {
    if(![values isKindOfClass:NSDictionary.class])return NO;
    NSDictionary *normalized=WCCNormalizePresentationValues(values,values[@"mainIconShadow124"] || values[@"mainIconGlow124"] || values[@"textEffect124_3"] || values[@"textEffect124_0"] || values[@"textEffect124_1"] || values[@"textEffect124_2"]?4:values[@"mainCustomIconPercent"]?1:(values[@"greetingEntries122"] || values[@"randomGreeting122"] || values[@"temperatureGlow122"] || values[@"informationGlow122"] || values[@"greetingGlow122"]?3:2));
    return normalized && WCCCommitPartial(normalized);
}
static BOOL WCCCommitPartial(NSDictionary *values) {
    if(!NSThread.isMainThread)return NO;
    NSUserDefaults *prefs=WCCPrefs();
    NSDictionary *before=[prefs persistentDomainForName:WCCPreferenceSuite] ?: @{};
    NSMutableDictionary *after=[before mutableCopy]; [after addEntriesFromDictionary:values];
    [prefs setPersistentDomain:after forName:WCCPreferenceSuite];
    BOOL saved=[prefs synchronize];
#ifdef WCC_TESTING
    if (WCCCommitFailure) saved=NO;
#endif
    if (!saved) { [prefs setPersistentDomain:before forName:WCCPreferenceSuite]; [prefs synchronize]; return NO; }
    return YES;
}
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
