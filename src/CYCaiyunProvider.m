#import "CYCaiyunProvider.h"
#import <Security/Security.h>
#import <math.h>
NSString * const CYErrorDomain = @"CYCaiyunProvider";
#ifndef CY_TESTING
typedef void (^CYWireReply)(NSData *, NSInteger, NSDictionary *, NSError *);
typedef dispatch_block_t (^CYTransport)(NSURLRequest *, CYWireReply);
@protocol CYTokenStore <NSObject>
- (NSString *)readToken:(NSError **)error;
- (BOOL)writeToken:(NSString *)token error:(NSError **)error;
- (BOOL)removeToken:(NSError **)error;
@end
#endif
static NSError *CYError(CYErrorCode code) {
    NSArray *messages=@[@"",@"请配置彩云 Token 和经纬度",@"Token 或经纬度格式无效",@"安全存储不可用，请解锁设备或检查权限",@"天气连接失败",@"天气响应不可用",@"天气请求或配置被拒绝",@"Token 无相应权限",@"天气访问受限制",@"天气额度或请求频率受限",@"天气服务暂不可用",@"请稍后刷新",@"请求已取消"];
    return [NSError errorWithDomain:CYErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:messages[code]}];
}
static NSDictionary *D(id x) { return [x isKindOfClass:NSDictionary.class]?x:@{}; }
static NSArray *A(id x) { return [x isKindOfClass:NSArray.class]?x:@[]; }
static NSString *S(id x) { return [x isKindOfClass:NSString.class]?x:nil; }
static NSNumber *N(id x) {
    if (![x isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)x)==CFBooleanGetTypeID() || !isfinite([x doubleValue])) return nil;
    return x;
}
static NSDictionary *OK(id x) { NSDictionary *d=D(x); return [S(d[@"status"]) isEqual:@"ok"]?d:@{}; }
@interface CYCondition ()
@property(nonatomic,copy,readwrite) NSString *skycon,*text,*basename,*symbol;
@end
@implementation CYCondition
@end
@interface CYHour ()
@property(nonatomic,strong,readwrite) NSDate *date;
@property(nonatomic,strong,readwrite) NSNumber *temperature,*probability;
@property(nonatomic,strong,readwrite) CYCondition *condition;
@end
@implementation CYHour
@end
@interface CYSnapshot ()
@property(nonatomic,copy,readwrite) NSString *source;
@property(nonatomic,readwrite) NSUInteger configGeneration;
@property(nonatomic,strong,readwrite) NSDate *timestamp,*serverTimestamp;
@property(nonatomic,strong,readwrite) NSTimeZone *timezone;
@property(nonatomic,strong,readwrite) NSNumber *currentTemperature,*maximum,*minimum;
@property(nonatomic,strong,readwrite) CYCondition *condition;
@property(nonatomic,copy,readwrite) NSArray<CYHour *> *hours;
@end
@implementation CYSnapshot
@end
@interface CYResult ()
@property(nonatomic,strong,readwrite) CYSnapshot *snapshot;
@property(nonatomic,strong,readwrite) NSError *error;
@property(nonatomic,readwrite) BOOL stale;
@property(nonatomic,readwrite) NSUInteger configGeneration;
@property(nonatomic,strong,readwrite) NSDate *nextAllowedRefresh;
@end
@implementation CYResult
@end

@interface CYKeychain : NSObject <CYTokenStore>
@end
@implementation CYKeychain
- (NSMutableDictionary *)query {
    // Deliberately no access-group and no synchronizable/iCloud sharing.
    return [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService:@"CCWeatherModule.Caiyun.v1",
              (__bridge id)kSecAttrAccount:@"user-token",
              (__bridge id)kSecAttrSynchronizable:@NO} mutableCopy];
}
- (NSString *)readToken:(NSError **)error {
    NSMutableDictionary *q=[self query];
    q[(__bridge id)kSecReturnData]=@YES;
    q[(__bridge id)kSecMatchLimit]=(__bridge id)kSecMatchLimitOne;
    CFTypeRef raw=NULL; OSStatus status=SecItemCopyMatching((__bridge CFDictionaryRef)q,&raw);
    id data=CFBridgingRelease(raw);
    if (status==errSecItemNotFound) return nil;
    if (status!=errSecSuccess || ![data isKindOfClass:NSData.class]) { if(error)*error=CYError(CYKeychainFailure); return nil; }
    NSString *token=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!token && error) *error=CYError(CYKeychainFailure);
    return token;
}
- (BOOL)writeToken:(NSString *)token error:(NSError **)error {
    NSDictionary *attrs=@{(__bridge id)kSecValueData:[token dataUsingEncoding:NSUTF8StringEncoding],
                          (__bridge id)kSecAttrAccessible:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly};
    NSMutableDictionary *q=[self query];
    OSStatus status=SecItemUpdate((__bridge CFDictionaryRef)q,(__bridge CFDictionaryRef)attrs);
    if (status==errSecItemNotFound) { [q addEntriesFromDictionary:attrs]; status=SecItemAdd((__bridge CFDictionaryRef)q,NULL); }
    if(status!=errSecSuccess && error)*error=CYError(CYKeychainFailure);
    return status==errSecSuccess;
}
- (BOOL)removeToken:(NSError **)error {
    OSStatus status=SecItemDelete((__bridge CFDictionaryRef)[self query]);
    BOOL ok=status==errSecSuccess || status==errSecItemNotFound;
    if(!ok && error)*error=CYError(CYKeychainFailure); return ok;
}
@end

// Strict ISO datetime with explicit offset; seconds and fractional seconds optional.
static NSDate *ISO(id value) {
    NSString *s=S(value); if (!s) return nil;
    NSString *pattern=@"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]{1,9})?)?(Z|[+-][0-9]{2}:[0-9]{2})$";
    if ([s rangeOfString:pattern options:NSRegularExpressionSearch].location==NSNotFound) return nil;
    NSDateFormatter *f=[NSDateFormatter new]; f.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    f.calendar=[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; f.lenient=NO;
    NSArray *formats=@[@"yyyy-MM-dd'T'HH:mmXXXXX",@"yyyy-MM-dd'T'HH:mm:ssXXXXX",@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSXXXXX"];
    for (NSString *format in formats) { f.dateFormat=format; NSDate *date=[f dateFromString:s]; if(date)return date; }
    return nil;
}
static NSDateFormatter *DayFormatter(NSTimeZone *tz) {
    NSDateFormatter *f=[NSDateFormatter new]; f.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    f.calendar=[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; f.timeZone=tz; f.lenient=NO; f.dateFormat=@"yyyy-MM-dd"; return f;
}
static NSString *DayKey(id input, NSTimeZone *tz) {
    if(!tz)return nil;
    NSDate *d=ISO(input); if(d)return [DayFormatter(tz) stringFromDate:d];
    NSString *s=S(input); NSDateFormatter *f=DayFormatter(tz);
    if(s.length==10 && [f dateFromString:s] && [[f stringFromDate:[f dateFromString:s]] isEqual:s])return s;
    return nil;
}
static NSInteger Daylight(NSDate *date,NSTimeZone *tz,NSArray *astro) {
    if(!date || !tz)return -1;
    NSString *key=[DayFormatter(tz) stringFromDate:date];
    for(id raw in astro) {
        NSDictionary *row=D(raw); if(![DayKey(row[@"date"],tz) isEqual:key])continue;
        NSString *rise=S(D(row[@"sunrise"])[@"time"]),*set=S(D(row[@"sunset"])[@"time"]);
        NSString *pattern=@"^([01][0-9]|2[0-3]):[0-5][0-9]$";
        if(!rise || !set || [rise rangeOfString:pattern options:NSRegularExpressionSearch].location==NSNotFound || [set rangeOfString:pattern options:NSRegularExpressionSearch].location==NSNotFound)return -1;
        NSDateFormatter *f=DayFormatter(tz); f.dateFormat=@"yyyy-MM-dd HH:mm";
        NSDate *a=[f dateFromString:[NSString stringWithFormat:@"%@ %@",key,rise]],*b=[f dateFromString:[NSString stringWithFormat:@"%@ %@",key,set]];
        if(!a || !b || [a compare:b]!=NSOrderedAscending)return -1;
        return [date compare:a]!=NSOrderedAscending && [date compare:b]==NSOrderedAscending;
    }
    return -1;
}
static CYCondition *Condition(id value,NSDate *date,NSTimeZone *tz,NSArray *astro) {
    static NSDictionary *table; static dispatch_once_t once;
    dispatch_once(&once, ^{
        // text, exact binding basename (empty means none), SF symbol.
        table=@{
        @"CLEAR_DAY":@[@"晴（昼）",@"晴天-白天",@"sun.max.fill"],
        @"CLEAR_NIGHT":@[@"晴（夜）",@"晴天-夜间",@"moon.stars.fill"],
        @"PARTLY_CLOUDY_DAY":@[@"多云（昼）",@"多云-白天",@"cloud.sun.fill"],
        @"PARTLY_CLOUDY_NIGHT":@[@"多云（夜）",@"多云-夜间",@"cloud.moon.fill"],
        @"CLOUDY":@[@"阴",@"阴天",@"cloud.fill"],
        @"LIGHT_HAZE":@[@"轻度雾霾",@"轻度雾霾",@"cloud.fog.fill"],
        @"MODERATE_HAZE":@[@"中度雾霾",@"中度雾霾",@"cloud.fog.fill"],
        @"HEAVY_HAZE":@[@"重度雾霾",@"",@"cloud.fog.fill"],
        @"LIGHT_RAIN":@[@"小雨",@"",@"cloud.rain.fill"],
        @"MODERATE_RAIN":@[@"中雨",@"中雨",@"cloud.rain.fill"],
        @"HEAVY_RAIN":@[@"大雨",@"",@"cloud.heavyrain.fill"],
        @"STORM_RAIN":@[@"暴雨",@"",@"cloud.heavyrain.fill"],
        @"FOG":@[@"雾",@"雾",@"cloud.fog.fill"],
        @"LIGHT_SNOW":@[@"小雪",@"",@"cloud.snow.fill"],
        @"MODERATE_SNOW":@[@"中雪",@"中雪",@"cloud.snow.fill"],
        @"HEAVY_SNOW":@[@"大雪",@"大雪",@"cloud.snow.fill"],
        @"STORM_SNOW":@[@"暴雪",@"",@"cloud.snow.fill"],
        @"DUST":@[@"浮尘",@"浮尘",@"sun.dust.fill"],
        @"SAND":@[@"沙尘",@"",@"wind"],@"WIND":@[@"大风",@"大风",@"wind"]};
    });
    CYCondition *c=[CYCondition new]; c.skycon=S(value);
    NSArray *row=c.skycon?table[c.skycon]:nil;
    c.text=row?row[0]:@"未知"; c.basename=row && [row[1] length]?row[1]:nil; c.symbol=row?row[2]:@"cloud.fill";
    if([c.skycon isEqual:@"LIGHT_RAIN"] || [c.skycon isEqual:@"LIGHT_SNOW"]) {
        NSInteger day=Daylight(date,tz,astro);
        if(day>=0)c.basename=[NSString stringWithFormat:@"%@-%@",[c.skycon isEqual:@"LIGHT_RAIN"]?@"小雨":@"小雪",day?@"白天":@"夜间"];
    }
    return c;
}
static CYSnapshot *Parse(NSDictionary *json,NSDate *now,NSUInteger generation) {
    if(![S(json[@"status"]) isEqual:@"ok"])return nil;
    NSDictionary *r=D(json[@"result"]),*real=OK(r[@"realtime"]),*hour=OK(r[@"hourly"]),*daily=OK(r[@"daily"]);
    CYSnapshot *s=[CYSnapshot new]; s.source=@"caiyun"; s.configGeneration=generation; s.timestamp=now;
    NSString *zone=S(json[@"timezone"]); if(zone)s.timezone=[NSTimeZone timeZoneWithName:zone];
    NSNumber *shift=N(json[@"tzshift"]);
    if(!s.timezone && shift && fabs(shift.doubleValue)<=18*3600 && floor(shift.doubleValue)==shift.doubleValue)s.timezone=[NSTimeZone timeZoneForSecondsFromGMT:shift.integerValue];
    NSNumber *server=N(json[@"server_time"]); if(server && server.doubleValue>=0 && server.doubleValue<=253402300799.0)s.serverTimestamp=[NSDate dateWithTimeIntervalSince1970:server.doubleValue];
    NSArray *astro=A(daily[@"astro"]);
    s.currentTemperature=N(real[@"temperature"]); s.condition=Condition(real[@"skycon"],now,s.timezone,astro);
    NSString *today=s.timezone?[DayFormatter(s.timezone) stringFromDate:now]:nil;
    for(id raw in A(daily[@"temperature"])) { NSDictionary *row=D(raw); if(today && [DayKey(row[@"date"],s.timezone) isEqual:today]) { s.maximum=N(row[@"max"]); s.minimum=N(row[@"min"]); break; } }
    NSMutableDictionary<NSDate *,NSMutableDictionary *> *joined=[NSMutableDictionary new];
    for(NSString *field in @[@"temperature",@"skycon",@"precipitation"]) {
        for(id raw in A(hour[field])) { NSDictionary *row=D(raw); NSDate *date=ISO(row[@"datetime"]); if(!date)continue;
            NSMutableDictionary *v=joined[date]; if(!v)joined[date]=v=[NSMutableDictionary new];
            id x=[field isEqual:@"skycon"]?S(row[@"value"]):N(row[[field isEqual:@"precipitation"]?@"probability":@"value"]);
            if([field isEqual:@"precipitation"] && x && ([x doubleValue]<0 || [x doubleValue]>100))x=nil;
            if(x)v[field]=x;
        }
    }
    NSMutableArray *hours=[NSMutableArray new];
    for(NSDate *date in [[joined allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSDictionary *v=joined[date]; if(!v.count)continue;
        CYHour *h=[CYHour new]; h.date=date; h.temperature=v[@"temperature"]; h.probability=v[@"precipitation"]; h.condition=Condition(v[@"skycon"],date,s.timezone,astro); [hours addObject:h];
    }
    s.hours=hours;
    // No usable weather must not become a fake successful empty/zero snapshot.
    return s.currentTemperature || s.condition.skycon || s.maximum || s.minimum || s.hours.count?s:nil;
}

// A per-request delegate: session retains delegate until invalidation, delegate never retains provider.
@interface CYWire : NSObject <NSURLSessionDataDelegate>
@property(nonatomic,copy) CYWireReply reply;
@property(nonatomic,strong) NSMutableData *body;
@property(nonatomic) BOOL rejected, oversized;
@property(nonatomic,strong) NSHTTPURLResponse *response;
@end
@implementation CYWire
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    self.rejected=YES; completionHandler(nil); // Reject ALL redirects, including same host.
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.response=[response isKindOfClass:NSHTTPURLResponse.class]?(id)response:nil;
    self.oversized=response.expectedContentLength>2*1024*1024;
    completionHandler(self.oversized?NSURLSessionResponseCancel:NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data {
    if(self.body.length+data.length>2*1024*1024) { self.oversized=YES; [task cancel]; return; }
    [self.body appendData:data];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    CYWireReply reply=self.reply; self.reply=nil;
    // Discard raw transport error, which may contain the credential-bearing URL.
    NSError *safe=self.rejected || self.oversized?CYError(CYInvalidResponse):(error?CYError(CYNetworkFailure):nil);
    if(reply)reply(self.body,self.response.statusCode,self.response.allHeaderFields?:@{},safe);
    [session finishTasksAndInvalidate];
}
@end
static dispatch_block_t StartWire(NSURLRequest *request,CYWireReply reply) {
    NSURLSessionConfiguration *c=NSURLSessionConfiguration.ephemeralSessionConfiguration;
    c.URLCache=nil; c.HTTPCookieStorage=nil; c.URLCredentialStorage=nil;
    c.HTTPShouldSetCookies=NO; c.requestCachePolicy=NSURLRequestReloadIgnoringLocalCacheData;
    c.timeoutIntervalForRequest=20; c.timeoutIntervalForResource=30;
    CYWire *wire=[CYWire new]; wire.reply=reply; wire.body=[NSMutableData new];
    NSURLSession *session=[NSURLSession sessionWithConfiguration:c delegate:wire delegateQueue:nil];
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request]; [task resume];
    return ^{ [task cancel]; [session invalidateAndCancel]; };
}
static NSURLRequest *Request(NSString *token,NSNumber *lon,NSNumber *lat) {
    NSURLComponents *u=[NSURLComponents new]; u.scheme=@"https"; u.host=@"api.caiyunapp.com";
    NSCharacterSet *safe=[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"];
    NSString *encoded=[token stringByAddingPercentEncodingWithAllowedCharacters:safe];
    // NSNumber descriptionWithLocale avoids the device's comma decimal separator.
    NSString *coordinate=[NSString stringWithFormat:@"%@,%@",[lon descriptionWithLocale:@{NSLocaleDecimalSeparator:@"."}],[lat descriptionWithLocale:@{NSLocaleDecimalSeparator:@"."}]];
    u.percentEncodedPath=[NSString stringWithFormat:@"/v2.6/%@/%@/weather",encoded,coordinate];
    NSMutableArray *query=[NSMutableArray new];
    for(NSArray *pair in @[@[@"lang",@"zh_CN"],@[@"unit",@"metric:v2"],@[@"hourlysteps",@"24"],@[@"dailysteps",@"5"],@[@"dailystart",@"0"],@[@"alert",@"false"]]) [query addObject:[NSURLQueryItem queryItemWithName:pair[0] value:pair[1]]];
    u.queryItems=query;
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:u.URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
    [r setValue:@"application/json" forHTTPHeaderField:@"Accept"]; [r setValue:@"no-store" forHTTPHeaderField:@"Cache-Control"]; return r;
}
static NSTimeInterval RetryAfter(NSDictionary *headers,NSDate *now) {
    NSString *value=nil; for(id key in headers)if([S(key) caseInsensitiveCompare:@"Retry-After"]==NSOrderedSame) { value=S(headers[key]); break; }
    if(!value)return 0;
    NSScanner *scanner=[NSScanner scannerWithString:value]; double seconds=0;
    if(!([scanner scanDouble:&seconds] && scanner.isAtEnd && isfinite(seconds) && seconds>=0)) {
        NSDateFormatter *f=[NSDateFormatter new]; f.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]; f.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0]; f.dateFormat=@"EEE, dd MMM yyyy HH:mm:ss 'GMT'";
        NSDate *date=[f dateFromString:value]; if(!date)return 0; seconds=[date timeIntervalSinceDate:now];
    }
    return fmin(3600,fmax(60,seconds));
}
@interface CYCaiyunProvider ()
@property(nonatomic,strong) id<CYTokenStore> store;
@property(nonatomic,copy) CYTransport transport;
@property(nonatomic,copy) NSDate *(^clock)(void);
@property(nonatomic,strong) NSNumber *longitude,*latitude;
@property(nonatomic,strong) CYSnapshot *cache;
@property(nonatomic,strong) NSError *lastError;
@property(nonatomic,strong) NSDate *lastAttempt,*nextAllowed;
@property(nonatomic) NSUInteger generation, requestSerial, failures;
@property(nonatomic) BOOL busy, blocked, credentialBlocked;
@property(nonatomic,strong) NSMutableArray *waiters;
@property(nonatomic,copy) dispatch_block_t cancelWire;
@property(nonatomic,strong) dispatch_queue_t parseQueue;
@end
@implementation CYCaiyunProvider
- (instancetype)init { return [self initInternalWithStore:[CYKeychain new] transport:^dispatch_block_t(NSURLRequest *r,CYWireReply reply){ return StartWire(r,reply); } clock:^{ return [NSDate date]; }]; }
- (instancetype)initInternalWithStore:(id<CYTokenStore>)store transport:(CYTransport)transport clock:(NSDate *(^)(void))clock {
    if((self=[super init])) { _store=store; _transport=[transport copy]; _clock=[clock copy]; _generation=1; _waiters=[NSMutableArray new]; _parseQueue=dispatch_queue_create("weather.caiyun.parse",DISPATCH_QUEUE_SERIAL); }
    return self;
}
#ifdef CY_TESTING
- (instancetype)initWithStore:(id<CYTokenStore>)store transport:(CYTransport)transport clock:(NSDate *(^)(void))clock { return [self initInternalWithStore:store transport:transport clock:clock]; }
+ (CYSnapshot *)parseFixture:(NSDictionary *)json now:(NSDate *)now generation:(NSUInteger)generation { return Parse(D(json),now,generation); }
#endif
- (void)dealloc { if(_cancelWire)_cancelWire(); }
+ (BOOL)validateLongitude:(NSNumber *)longitude latitude:(NSNumber *)latitude {
    return N(longitude) && N(latitude) && fabs(longitude.doubleValue)<=180 && fabs(latitude.doubleValue)<=90;
}
+ (BOOL)validateToken:(NSString *)token {
    // Conservative segment alphabet. Reject slash, dot, percent, backslash, controls,
    // whitespace, query delimiters and Unicode; never trim/normalize a secret silently.
    if(!S(token) || token.length<1 || token.length>512)return NO;
    return [token rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"] invertedSet]].location==NSNotFound;
}
- (void)assertMain { NSAssert(NSThread.isMainThread,@"Caiyun API must be used on main thread"); }
- (CYResult *)resultWithError:(NSError *)error {
    CYResult *r=[CYResult new]; r.snapshot=self.cache; r.error=error; r.configGeneration=self.generation; r.nextAllowedRefresh=self.nextAllowed;
    NSTimeInterval age=self.cache?[self.clock() timeIntervalSinceDate:self.cache.timestamp]:0;
    r.stale=self.cache && (error!=nil || age<0 || age>=900); return r;
}
- (void)deliver:(NSArray *)waiters result:(CYResult *)result {
    __weak typeof(self) weakSelf=self; NSUInteger serial=self.requestSerial;
    for(void (^callback)(CYResult *) in waiters)dispatch_async(dispatch_get_main_queue(),^{
        CYCaiyunProvider *p=weakSelf;
        if(p && (result.configGeneration!=p.generation || serial!=p.requestSerial))callback([p resultWithError:CYError(CYCancelled)]);
        else callback(result);
    });
}
- (CYResult *)currentResult { [self assertMain]; return [self resultWithError:self.lastError?:(!self.cache && (!self.longitude || !self.latitude)?CYError(CYNotConfigured):nil)]; }
- (void)cancel {
    [self assertMain]; ++self.requestSerial; if(self.cancelWire)self.cancelWire(); self.cancelWire=nil; self.busy=NO;
    NSArray *waiters=[self.waiters copy]; [self.waiters removeAllObjects];
    [self deliver:waiters result:[self resultWithError:CYError(CYCancelled)]];
}
- (void)clearCache { [self assertMain]; [self cancel]; ++self.generation; self.cache=nil; if(!self.blocked && !self.credentialBlocked)self.lastError=nil; }
- (void)invalidateConfiguration {
    [self clearCache]; self.blocked=NO; self.failures=0; self.lastError=nil;
    // Keep lastAttempt/nextAllowed across edits to avoid bypassing rate limits via settings.
}
- (BOOL)hasToken:(NSError **)error {
    [self assertMain]; if(error)*error=nil; NSError *e=nil; NSString *token=[self.store readToken:&e];
    if(e) { if(error)*error=CYError(CYKeychainFailure); return NO; }
    if(token && ![CYCaiyunProvider validateToken:token]) { if(error)*error=CYError(CYInvalidInput); return NO; }
    return token.length>0;
}
- (BOOL)saveToken:(NSString *)token error:(NSError **)error {
    [self assertMain]; if(error)*error=nil; [self invalidateConfiguration]; self.credentialBlocked=YES;
    if(![CYCaiyunProvider validateToken:token]) { self.lastError=CYError(CYInvalidInput); if(error)*error=self.lastError; return NO; }
    NSError *e=nil; BOOL ok=[self.store writeToken:token error:&e]; self.credentialBlocked=!ok;
    if(!ok) { self.lastError=CYError(CYKeychainFailure); if(error)*error=self.lastError; } return ok;
}
- (BOOL)deleteToken:(NSError **)error {
    [self assertMain]; if(error)*error=nil; [self invalidateConfiguration]; NSError *e=nil;
    BOOL ok=[self.store removeToken:&e]; self.credentialBlocked=!ok;
    self.lastError=CYError(ok?CYNotConfigured:CYKeychainFailure); if(!ok && error)*error=self.lastError; return ok;
}
- (BOOL)setLongitude:(NSNumber *)longitude latitude:(NSNumber *)latitude error:(NSError **)error {
    [self assertMain]; if(error)*error=nil;
    BOOL missing=!longitude && !latitude, valid=[CYCaiyunProvider validateLongitude:longitude latitude:latitude];
    if(valid && [self.longitude isEqual:longitude] && [self.latitude isEqual:latitude])return YES;
    [self invalidateConfiguration]; self.longitude=valid?[longitude copy]:nil; self.latitude=valid?[latitude copy]:nil;
    if(!valid)self.lastError=CYError(missing?CYNotConfigured:CYInvalidInput);
    if(!valid && !missing && error)*error=self.lastError; return valid || missing;
}
- (void)refreshManual:(BOOL)manual completion:(void (^)(CYResult *))completion {
    [self assertMain]; if(!completion)return;
    if(self.busy) { [self.waiters addObject:[completion copy]]; return; }
    NSError *error=nil; NSString *token=nil;
    if(self.credentialBlocked)error=self.lastError?:CYError(CYKeychainFailure);
    else if(![CYCaiyunProvider validateLongitude:self.longitude latitude:self.latitude])error=CYError(CYNotConfigured);
    else { NSError *keyError=nil; token=[self.store readToken:&keyError]; if(keyError)error=CYError(CYKeychainFailure); else if(!token.length)error=CYError(CYNotConfigured); else if(![CYCaiyunProvider validateToken:token])error=CYError(CYInvalidInput); }
    if(error) { self.lastError=error; [self deliver:@[[completion copy]] result:[self resultWithError:error]]; return; }
    NSDate *now=self.clock(); NSTimeInterval age=self.cache?[now timeIntervalSinceDate:self.cache.timestamp]:INFINITY;
    if(!manual && self.cache && age>=0 && age<900 && !self.lastError) { [self deliver:@[[completion copy]] result:[self resultWithError:nil]]; return; }
    if(self.blocked) { [self deliver:@[[completion copy]] result:[self resultWithError:self.lastError]]; return; }
    if((self.lastAttempt && [now timeIntervalSinceDate:self.lastAttempt]<60) || (self.nextAllowed && [now compare:self.nextAllowed]==NSOrderedAscending)) {
        [self deliver:@[[completion copy]] result:[self resultWithError:self.lastError?:CYError(CYThrottled)]]; return;
    }
    self.lastAttempt=now; self.nextAllowed=[now dateByAddingTimeInterval:60]; self.busy=YES; [self.waiters addObject:[completion copy]];
    NSUInteger generation=self.generation,serial=++self.requestSerial;
    NSURLRequest *request=Request(token,self.longitude,self.latitude);
    dispatch_queue_t queue=self.parseQueue; __weak typeof(self) weakSelf=self;
    // Even a synchronous test transport is marshalled to the serial parser and main thread.
    self.cancelWire=self.transport(request,^(NSData *data,NSInteger status,NSDictionary *headers,NSError *wireError){
        dispatch_async(queue,^{
            NSError *safe=nil; CYSnapshot *snapshot=nil;
            if(wireError)safe=CYError(CYNetworkFailure);
            else if(status==400 || status==422)safe=CYError(CYRequestRejected);
            else if(status==401)safe=CYError(CYPermissionDenied);
            else if(status==403)safe=CYError(CYAccessRestricted);
            else if(status==429)safe=CYError(CYRateLimited);
            else if(status>=500)safe=CYError(CYServerFailure);
            else if(status!=200)safe=CYError(CYInvalidResponse);
            else if(!data || data.length>2*1024*1024)safe=CYError(CYInvalidResponse);
            else {
                id json=[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                snapshot=Parse(D(json),now,generation); if(!snapshot)safe=CYError(CYInvalidResponse);
            }
            dispatch_async(dispatch_get_main_queue(),^{
                CYCaiyunProvider *p=weakSelf; if(!p || !p.busy || p.generation!=generation || p.requestSerial!=serial)return;
                NSDate *received=p.clock(); p.cancelWire=nil; p.busy=NO;
                if(snapshot) { snapshot.timestamp=received; p.cache=snapshot; p.failures=0; p.lastError=nil; p.nextAllowed=[p.lastAttempt dateByAddingTimeInterval:60]; }
                else {
                    p.lastError=safe?:CYError(CYInvalidResponse); p.failures=MIN(p.failures+1,7u);
                    p.blocked=safe.code==CYRequestRejected || safe.code==CYPermissionDenied || safe.code==CYAccessRestricted;
                    double delay=fmin(3600,60*pow(2,p.failures-1))*(0.9+(arc4random_uniform(2001)/10000.0));
                    delay=fmin(3600,fmax(60,delay));
                    if(safe.code==CYRateLimited)delay=fmax(delay,RetryAfter(headers,received));
                    p.nextAllowed=[received dateByAddingTimeInterval:delay];
                }
                NSArray *waiters=[p.waiters copy]; [p.waiters removeAllObjects]; [p deliver:waiters result:[p resultWithError:p.lastError]];
            });
        });
    });
}
@end
