#import "WCCConfigurations.h"
#import <CoreFoundation/CoreFoundation.h>
#import "WCCPreferences.h"
#import "WCCRuntime.h"
#include <sys/stat.h>
#include <errno.h>
static NSString * const WCCBackupID=@"00000000-0000-0000-0000-000000000000";
#ifdef WCC_TESTING
static NSString *WCCTestDirectory;
void WCCTestUseConfigurationDirectory(NSString *directory) { WCCTestDirectory=[directory copy]; }
#endif
NSString *WCCConfigurationDirectory(void) {
#ifdef WCC_TESTING
    if (WCCTestDirectory) return WCCTestDirectory;
#endif
    return @"/var/mobile/Documents/CCWeatherModule/Configurations";
}
static NSError *WCCConfigError(NSString *message) { return [NSError errorWithDomain:@"WCCConfiguration" code:1 userInfo:@{NSLocalizedDescriptionKey:message}]; }
static BOOL WCCSafeConfigurationDirectory(NSError **error) {
    NSString *base=@"/var/mobile/Documents";
    NSString *expected=[base.stringByResolvingSymlinksInPath stringByAppendingPathComponent:@"CCWeatherModule/Configurations"];
#ifdef WCC_TESTING
    if (WCCTestDirectory) expected=WCCTestDirectory.stringByStandardizingPath;
#endif
    if (![WCCConfigurationDirectory().stringByResolvingSymlinksInPath isEqual:expected]) {
        if(error)*error=WCCConfigError(@"配置目录符号链接不安全，操作已取消。"); return NO;
    }
    return YES;
}
static BOOL WCCSafeConfigurationFile(NSString *path,BOOL mustExist,NSError **error) {
    if(!WCCSafeConfigurationDirectory(error))return NO;
    struct stat st; if(lstat(path.fileSystemRepresentation,&st)!=0) {
        if(!mustExist && errno==ENOENT)return YES;
        if(error)*error=WCCConfigError(@"无法访问配置文件。"); return NO;
    }
    if(!S_ISREG(st.st_mode) || st.st_size<1) {
        if(error)*error=WCCConfigError(@"配置须为非空普通文件，不允许符号链接。");return NO;
    }
    return YES;
}
static NSString *WCCConfigPath(NSString *identifier) {
    if (![identifier isKindOfClass:NSString.class] || ![[NSUUID alloc] initWithUUIDString:identifier]) return nil;
    return [WCCConfigurationDirectory() stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"json"]];
}
static NSDictionary *WCCValidatedConfiguration(id object,NSError **error) {
    if (![object isKindOfClass:NSDictionary.class] || ![object[@"schema"] isEqual:@"CCWeatherSliderConfiguration"] || ![object[@"version"] isKindOfClass:NSNumber.class] || ([object[@"version"] doubleValue]!=1 && [object[@"version"] doubleValue]!=2 && [object[@"version"] doubleValue]!=3) || ![object[@"values"] isKindOfClass:NSDictionary.class] || ![object[@"name"] isKindOfClass:NSString.class] || ![object[@"modified"] isKindOfClass:NSNumber.class] || !isfinite([object[@"modified"] doubleValue])) {
        if(error)*error=WCCConfigError(@"方案格式或版本不受支持，当前设置未更改。"); return nil;
    }
    if (CFGetTypeID((__bridge CFTypeRef)object[@"version"])==CFBooleanGetTypeID() || CFGetTypeID((__bridge CFTypeRef)object[@"modified"])==CFBooleanGetTypeID()) { if(error)*error=WCCConfigError(@"版本和时间须为数值，不接受布尔值。"); return nil; }
    NSArray *allowed=@[@"schema",@"version",@"name",@"modified",@"values"];
    NSString *name=object[@"name"];
    if([object count]!=5 || !name.length || name.length>40 || ![name isEqual:[name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]] || [name rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound) {
        if(error)*error=WCCConfigError(@"方案名称或字段无效。");return nil;
    }
    for(id key in object)if(![allowed containsObject:key]){if(error)*error=WCCConfigError(@"方案含未知字段。");return nil;}
    NSDictionary *values=WCCNormalizePresentationValues(object[@"values"],[object[@"version"] integerValue]);
    if(!values){if(error)*error=WCCConfigError(@"方案含无效数值、布尔、问候文本或未知字段；当前设置未更改。");return nil;}
    NSMutableDictionary *result=[object mutableCopy]; result[@"values"]=values; return result;
}
static NSDictionary *WCCReadConfiguration(NSString *identifier,NSError **error) {
    NSString *path=WCCConfigPath(identifier);
    if (!path) { if(error)*error=WCCConfigError(@"方案标识无效。"); return nil; }
    if(!WCCSafeConfigurationFile(path,YES,error))return nil;
    NSData *data=[NSData dataWithContentsOfFile:path options:0 error:error]; if (!data) return nil;
    if (!data.length) { if(error)*error=WCCConfigError(@"方案读取大小超出限额。"); return nil; }
    id json=[NSJSONSerialization JSONObjectWithData:data options:0 error:error]; if(!json)return nil;
    if([json isKindOfClass:NSDictionary.class] && [json[@"version"] isEqual:@1] && data.length>16384)return nil;
    if([json isKindOfClass:NSDictionary.class] && [json[@"version"] isEqual:@2] && data.length>16384)return nil;
    return WCCValidatedConfiguration(json,error);
}
NSDictionary *WCCCurrentSliderValues(void) {
    NSMutableDictionary *values=[NSMutableDictionary dictionary];
    for(NSInteger i=0;i<8;i++)values[WCCRegionPositionKeys()[i]]=@(WCCRegionOffset(i));
    values[@"mainIconCollapsedPercent"]=@(WCCMainIconPercentForMode(NO));
    values[@"mainIconExpandedPercent"]=@(WCCMainIconPercentForMode(YES));
    values[@"temperatureShadow"]=@(WCCTextShadowEnabled(0));
    values[@"informationShadow"]=@(WCCTextShadowEnabled(1));
    values[@"greetingShadow"]=@(WCCTextShadowEnabled(2));
    values[@"customGreetingEnabled"]=@(WCCCustomGreetingEnabled());
    values[@"customGreetingText"]=WCCCustomGreetingText();
    values[@"greetingEntries122"]=WCCGreetingEntries();values[@"randomGreeting122"]=@(WCCRandomGreetingEnabled());
    NSArray *glowKeys=@[@"temperatureGlow122",@"informationGlow122",@"greetingGlow122"];
    for(NSInteger i=0;i<3;i++)values[glowKeys[i]]=@(WCCTextGlowEnabled(i));
    return values;
}
NSArray<NSDictionary *> *WCCConfigurations(NSError **error) {
    NSFileManager *fm=NSFileManager.defaultManager;
    if (!WCCSafeConfigurationDirectory(error)) return nil;
    if (![fm fileExistsAtPath:WCCConfigurationDirectory()]) return @[];
    NSArray *files=[fm contentsOfDirectoryAtPath:WCCConfigurationDirectory() error:error]; if(!files)return nil;
    NSMutableArray *list=[NSMutableArray array];
    for(NSString *file in files) {
        if(![file.pathExtension isEqual:@"json"] || !WCCConfigPath(file.stringByDeletingPathExtension))continue;
        NSError *readError=nil; NSDictionary *data=WCCReadConfiguration(file.stringByDeletingPathExtension,&readError);
        [list addObject:@{@"id":file.stringByDeletingPathExtension,@"name":data[@"name"]?:@"损坏的方案（可删除）",@"modified":data[@"modified"]?:@0,@"valid":@(data!=nil)}];
    }
    return [list sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"modified" ascending:NO]]];
}
static BOOL WCCWriteConfiguration(NSString *identifier,NSString *name,NSDictionary *values,NSError **error) {
    NSString *path=WCCConfigPath(identifier); if(!path)return NO;
    NSDictionary *document=@{@"schema":@"CCWeatherSliderConfiguration",@"version":@3,@"name":name,@"modified":@(NSDate.date.timeIntervalSince1970),@"values":values};
    if(!WCCValidatedConfiguration(document,error) || !WCCSafeConfigurationDirectory(error))return NO;
    if(![NSFileManager.defaultManager createDirectoryAtPath:WCCConfigurationDirectory() withIntermediateDirectories:YES attributes:nil error:error])return NO;
    if(!WCCSafeConfigurationFile(path,NO,error))return NO;
    NSData *data=[NSJSONSerialization dataWithJSONObject:document options:NSJSONWritingPrettyPrinted error:error];
    return data && [data writeToFile:path options:NSDataWritingAtomic error:error];
}
BOOL WCCSaveConfiguration(NSString *name,NSString *overwriteID,NSError **error) {
    name=[name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSMutableCharacterSet *bad=[NSCharacterSet.controlCharacterSet mutableCopy]; [bad addCharactersInString:@"/\\:*?\"<>|"];
    if(!name.length || name.length>40 || [name rangeOfCharacterFromSet:bad].location!=NSNotFound || [name isEqual:@"自动备份（读取前）"]) { if(error)*error=WCCConfigError(@"名称须为1–40字，不能含路径符号或控制字符，也不能使用自动备份名称。"); return NO; }
    if(overwriteID && (!WCCConfigPath(overwriteID) || [overwriteID isEqual:WCCBackupID])) { if(error)*error=WCCConfigError(@"不能覆盖此方案。"); return NO; }
    NSError *listError=nil; NSArray *list=WCCConfigurations(&listError);
    if(!list){if(error)*error=listError;return NO;}
    for(NSDictionary *item in list) if([item[@"name"] caseInsensitiveCompare:name]==NSOrderedSame && ![item[@"id"] isEqual:overwriteID]) { if(error)*error=WCCConfigError(@"已有同名方案，请在列表选择该方案并确认覆盖。"); return NO; }
    return WCCWriteConfiguration(overwriteID?:NSUUID.UUID.UUIDString,name,WCCCurrentSliderValues(),error);
}
BOOL WCCLoadConfiguration(NSString *identifier,NSError **error) {
    if(!NSThread.isMainThread){if(error)*error=WCCConfigError(@"请在主线程读取方案。");return NO;}
    NSDictionary *document=WCCReadConfiguration(identifier,error); if(!document)return NO;
    // Validate/read first; backup failure must not modify a single preference.
    if(!WCCWriteConfiguration(WCCBackupID,@"自动备份（读取前）",WCCCurrentSliderValues(),error))return NO;
    NSDictionary *values=document[@"values"];
    if (!WCCCommitSliderValues(values)) { if(error)*error=WCCConfigError(@"偏好提交失败，已恢复读取前设置；未应用方案。"); return NO; }
    // A single position notification lays out all eight values AND the scale.
    [NSNotificationCenter.defaultCenter postNotificationName:WCCRegionPositionChanged object:nil];
    return YES;
}
BOOL WCCDeleteConfiguration(NSString *identifier,NSError **error) {
    NSString *path=WCCConfigPath(identifier); if(!path){if(error)*error=WCCConfigError(@"方案标识无效。");return NO;}
    if(!WCCSafeConfigurationDirectory(error))return NO;
    struct stat st;
    if(lstat(path.fileSystemRepresentation,&st)!=0 || !S_ISREG(st.st_mode)) { if(error)*error=WCCConfigError(@"删除目标不是普通方案文件。"); return NO; }
    return [NSFileManager.defaultManager removeItemAtPath:path error:error];
}
