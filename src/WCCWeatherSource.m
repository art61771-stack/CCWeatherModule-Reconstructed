#import "WCCWeatherSource.h"
#import "CYCaiyunProvider.h"
#import "WCCPreferences.h"
#include <math.h>
#import "WCCRefreshPolicy.h"
NSString * const WCCWeatherSourceChanged=@"WCCWeatherSourceChanged";
NSNumber *WCCParseCoordinate(NSString *text, BOOL longitude) {
    if (![text isKindOfClass:NSString.class]) return nil;
    NSString *s=[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    // Entire input, ASCII decimal only. Reject commas, NaN, infinity and partial scans.
    NSRegularExpression *re=[NSRegularExpression regularExpressionWithPattern:@"^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$" options:0 error:nil];
    if (!s.length || [re numberOfMatchesInString:s options:0 range:NSMakeRange(0,s.length)]!=1) return nil;
    double d=s.doubleValue; double bound=longitude?180:90;
    return isfinite(d) && fabs(d)<=bound ? @(d) : nil;
}
static NSString *WCCTemp(NSNumber *n) { return n ? [NSString stringWithFormat:@"%.0f°",n.doubleValue] : @"--°"; }
static NSDictionary *WCCCondition(CYCondition *c) {
    return @{@"text":c.text?:@"未知",@"basename":c.basename?:@"",@"symbol":c.symbol?:@"cloud.fill"};
}
NSDictionary *WCCRenderCaiyunSnapshot(CYSnapshot *s, NSString *alias, BOOL stale) {
    NSMutableArray *hours=[NSMutableArray array];
    NSDateFormatter *f=[NSDateFormatter new]; f.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    f.timeZone=s.timezone; f.dateFormat=@"HH:mm";
    for (CYHour *h in s.hours) {
        [hours addObject:@{@"time":s.timezone ? [f stringFromDate:h.date] : @"--",@"temperature":WCCTemp(h.temperature),@"condition":WCCCondition(h.condition)}];
    }
    NSNumber *p=s.hours.firstObject.probability;
    return @{@"source":@"caiyun",@"city":alias.length?alias:@"彩云地点",@"temperature":WCCTemp(s.currentTemperature),
      @"highLow":[NSString stringWithFormat:@"%@ / %@",WCCTemp(s.maximum),WCCTemp(s.minimum)],
      @"precipitation":p?[NSString stringWithFormat:@"降水概率: %.0f%%",p.doubleValue]:@"降水概率: --",
      @"condition":WCCCondition(s.condition),@"hours":[hours copy],@"stale":@(stale),@"ready":@(s!=nil)};
}
@interface WCCWeatherSource ()
@property(nonatomic,strong) CYCaiyunProvider *provider;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic) BOOL automaticActive;
@property(nonatomic) NSUInteger generation;
@property(nonatomic) NSUInteger requestEpoch;
@property(nonatomic,copy) NSString *status;
@property(nonatomic,strong) CYSnapshot *snapshot;
@property(nonatomic) BOOL stale;
@end
@implementation WCCWeatherSource
+ (instancetype)shared { static id source; static dispatch_once_t once; dispatch_once(&once,^{source=[self new];}); return source; }
- (instancetype)init {
    if ((self=[super init])) {
        _provider=[CYCaiyunProvider new]; _generation=1; _status=@"未请求";
        if (self.caiyun) [_provider setLongitude:[WCCPrefs() objectForKey:@"caiyunLongitude"] latitude:[WCCPrefs() objectForKey:@"caiyunLatitude"] error:nil];
    } return self;
}
- (NSTimeInterval)refreshTTL { return WCCRefreshTTL((int)[WCCPrefs() integerForKey:@"caiyunRefreshHours124"]); }
- (void)stopTimer { [self.refreshTimer invalidate];self.refreshTimer=nil; }
- (void)setAutomaticActive:(BOOL)active {
    NSAssert(NSThread.isMainThread,@"main thread only");
    if(!active){_automaticActive=NO;[self cancel];return;}
    if(self.automaticActive)return;
    _automaticActive=YES;[self refreshManual:NO];
}
- (BOOL)setRefreshHours:(NSInteger)hours {
    if(!WCCSetCaiyunRefreshHours(hours))return NO;
    self.provider.cacheTTL=self.refreshTTL;
    [self stopTimer];if(self.automaticActive)[self refreshManual:NO];return YES;
}
- (void)scheduleResult:(CYResult *)r {
    [self stopTimer];if(!self.automaticActive || !self.caiyun)return;
    double age=r.snapshot ? -[r.snapshot.timestamp timeIntervalSinceNow] : INFINITY;
    double retry=r.nextAllowedRefresh ? [r.nextAllowedRefresh timeIntervalSinceNow] : 0;
    // Failed/no-credential results retry at TTL, never once per second.
    if(!r || r.error)retry=fmax(retry,self.refreshTTL);
    double delay=WCCRefreshDelay(age,self.refreshTTL,retry);
    __weak typeof(self) weak=self;
    self.refreshTimer=[NSTimer scheduledTimerWithTimeInterval:delay repeats:NO block:^(NSTimer *timer){ [weak refreshManual:NO]; }];
}
- (BOOL)caiyun { return [[WCCPrefs() stringForKey:@"weatherProvider"] isEqual:@"caiyun"]; }
- (void)notify { [NSNotificationCenter.defaultCenter postNotificationName:WCCWeatherSourceChanged object:self]; }
- (BOOL)hasToken { NSError *e=nil; BOOL yes=[self.provider hasToken:&e]; if(e)self.status=@"Keychain 无法访问；不会使用明文存储"; return yes; }
- (void)invalidate {
    [self stopTimer]; ++self.generation; [self.provider clearCache]; self.snapshot=nil; self.stale=NO;
}
- (BOOL)applyCaiyun:(BOOL)enabled longitude:(NSNumber *)lon latitude:(NSNumber *)lat alias:(NSString *)alias token:(NSString *)token {
    NSAssert(NSThread.isMainThread,@"main thread only");
    alias=alias?:@"";
    [self invalidate];
    if ((enabled && ![CYCaiyunProvider validateLongitude:lon latitude:lat]) || alias.length>80 ||
        [alias rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound ||
        (token.length && ![CYCaiyunProvider validateToken:token])) {
        self.status=@"输入无效：请检查经纬度、别名及 Token"; [self notify]; return NO;
    }
    // Cancel old callbacks before Keychain mutation, including failed attempts.
    NSError *e=nil;
    if (enabled && token.length && ![self.provider saveToken:token error:&e]) {
        self.status=@"Token 未保存：Keychain 失败（禁止明文降级）"; [self notify]; return NO;
    }
    // A failed prefs commit never exposes partially selected provider/location.
    NSArray *keys=@[@"weatherProvider",@"caiyunLongitude",@"caiyunLatitude",@"caiyunAlias"];
    NSMutableDictionary *old=[NSMutableDictionary dictionary];
    for(NSString *k in keys) old[k]=[WCCPrefs() objectForKey:k]?:NSNull.null;
    [WCCPrefs() setObject:enabled?@"caiyun":@"system" forKey:keys[0]];
    if(lon && lat) { [WCCPrefs() setObject:lon forKey:keys[1]]; [WCCPrefs() setObject:lat forKey:keys[2]]; }
    [WCCPrefs() setObject:alias?:@"" forKey:keys[3]];
    if(![WCCPrefs() synchronize]) {
        for(NSString *k in keys) { if(old[k]==NSNull.null)[WCCPrefs() removeObjectForKey:k]; else [WCCPrefs() setObject:old[k] forKey:k]; }
        [WCCPrefs() synchronize]; self.status=token.length?@"偏好保存失败；Token 已更新，请重试应用":@"偏好保存失败，已恢复原配置";
        [self notify]; return NO;
    }
    [self.provider setLongitude:enabled?lon:nil latitude:enabled?lat:nil error:nil];
    self.status=enabled?@"已应用，等待刷新（未请求）":@"系统天气";
    [self notify]; [self scheduleResult:nil]; return YES;
}
- (BOOL)deleteToken {
    [self invalidate]; NSError *e=nil; BOOL ok=[self.provider deleteToken:&e];
    self.status=ok?@"Token 已删除，彩云未就绪":@"删除失败：Keychain 无法访问"; [self notify]; return ok;
}
- (void)cancel {
    [self stopTimer]; ++self.requestEpoch; [self.provider cancel];
    if(self.caiyun) { self.status=@"已暂停请求（保留同配置缓存）"; [self notify]; }
}
- (void)refreshManual:(BOOL)manual {
    [self stopTimer];self.provider.cacheTTL=self.refreshTTL;
    if(!self.caiyun) { self.status=@"系统天气：彩云未请求"; [self notify]; return; }
    NSUInteger generation=self.generation, epoch=self.requestEpoch;
    self.status=@"正在检查 / 请求彩云…"; [self notify];
    __weak typeof(self) weak=self;
    [self.provider refreshManual:manual completion:^(CYResult *r) {
        typeof(self) self=weak; if(!self || generation!=self.generation || epoch!=self.requestEpoch || !self.caiyun) return;
        self.snapshot=r.snapshot; self.stale=r.stale;
        NSString *date=@"尚无成功更新";
        if(r.snapshot.timestamp) {
            NSDateFormatter *f=[NSDateFormatter new]; f.dateFormat=@"yyyy-MM-dd HH:mm:ss";
            date=[@"上次更新 " stringByAppendingString:[f stringFromDate:r.snapshot.timestamp]];
        }
        // Component guarantees local sanitized errors; never use userInfo / URL.
        NSString *error=r.error ? r.error.localizedDescription : @"";
        self.status=[NSString stringWithFormat:@"%@%@%@%@",date,r.stale?@" · 数据已过期":@"",error.length?@"\n":@"",error];
        if(r.nextAllowedRefresh && [r.nextAllowedRefresh timeIntervalSinceNow]>0) {
            NSDateFormatter *f=[NSDateFormatter new]; f.dateFormat=@"HH:mm:ss";
            self.status=[self.status stringByAppendingFormat:@"\n最早下次请求 %@",[f stringFromDate:r.nextAllowedRefresh]];
        }
        [self notify];[self scheduleResult:r];
    }];
}
@end
