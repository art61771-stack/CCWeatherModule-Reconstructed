#import <Foundation/Foundation.h>
#import "../src/WCCWeatherSource.h"
#import "../src/CYCaiyunProvider.h"
#import "../src/WCCPreferences.h"
#include <assert.h>
@interface SourceStore : NSObject <CYTokenStore>
@property(nonatomic,copy) NSString *token;
@end
@implementation SourceStore
- (NSString *)readToken:(NSError **)e { return self.token; }
- (BOOL)writeToken:(NSString *)s error:(NSError **)e { self.token=s; return YES; }
- (BOOL)removeToken:(NSError **)e { self.token=nil; return YES; }
@end
static void Drain(void) { NSDate *end=[NSDate dateWithTimeIntervalSinceNow:.15]; while([end timeIntervalSinceNow]>0) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]]; }
int main(int argc,char **argv) { @autoreleasepool {
    assert(NSThread.isMainThread); assert(argc==2);
    NSString *suite=[@"weather120.offline." stringByAppendingString:NSUUID.UUID.UUIDString]; WCCTestUsePreferences(suite);
    assert([WCCParseCoordinate(@"0",YES) isEqual:@0]); assert([WCCParseCoordinate(@"-90",NO) isEqual:@(-90)]);
    for(NSString *s in @[@"",@"NaN",@"Inf",@"0garbage",@"1,2",@"181",@"1e999"])assert(!WCCParseCoordinate(s,YES));
    assert(!WCCParseCoordinate(@"90.01",NO));
    NSDictionary *empty=WCCRenderCaiyunSnapshot(nil,@"",NO);
    assert([empty[@"temperature"] isEqual:@"--°"]); assert(![empty[@"ready"] boolValue]); assert([empty[@"hours"] count]==0);
    NSData *data=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
    NSDictionary *json=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]; assert(json);
    CYSnapshot *snapshot=[CYCaiyunProvider parseFixture:json now:[NSDate dateWithTimeIntervalSince1970:1790049600] generation:7]; assert(snapshot);
    NSDictionary *r=WCCRenderCaiyunSnapshot(snapshot,@"离线夹具",YES);
    assert([r[@"source"] isEqual:@"caiyun"]); assert([r[@"city"] isEqual:@"离线夹具"]); assert([r[@"stale"] boolValue]);
    assert([r[@"hours"] count]==snapshot.hours.count);
    assert([r[@"temperature"] isEqual:@"0°"]);
    assert([r[@"precipitation"] isEqual:@"降水概率: 0%"]);
    assert([r[@"hours"][2][@"temperature"] isEqual:@"--°"]);
    assert([r[@"hours"][3][@"temperature"] isEqual:@"--°"]);
    assert([r[@"condition"][@"basename"] isEqual:@"晴天-夜间"]);
    for(NSUInteger i=0;i<snapshot.hours.count;i++) {
        CYHour *hour=snapshot.hours[i]; NSDictionary *condition=r[@"hours"][i][@"condition"];
        assert([condition[@"basename"] isEqual:hour.condition.basename?:@""]);
        if([hour.condition.skycon isEqual:@"CLEAR_NIGHT"])assert([condition[@"basename"] isEqual:@"晴天-夜间"]);
    }
    WCCWeatherSource *source=[WCCWeatherSource new]; assert(!source.caiyun);
    SourceStore *store=[SourceStore new]; __block NSUInteger requests=0; __block CYWireReply pending;
    NSDate *clock=[NSDate dateWithTimeIntervalSince1970:1790049600];
    CYCaiyunProvider *provider=[[CYCaiyunProvider alloc] initWithStore:store transport:^dispatch_block_t(NSURLRequest *request,CYWireReply reply) { requests++; pending=[reply copy]; return ^{}; } clock:^{return clock;}];
    [source setValue:provider forKey:@"provider"];
    [source refreshManual:YES]; assert(requests==0);
    assert([source applyCaiyun:YES longitude:@0 latitude:@0 alias:@"A" token:@"OFFLINE_DUMMY_NOT_A_REAL_TOKEN"]);
    assert(!source.snapshot && requests==0);
    [source refreshManual:NO]; assert(requests==1); CYWireReply old=pending;
    NSUInteger generation=source.generation;
    assert([source applyCaiyun:YES longitude:@1 latitude:@2 alias:@"B" token:@""]);
    assert(source.generation>generation && !source.snapshot); old(data,200,@{},nil); Drain(); assert(!source.snapshot);
    assert([source applyCaiyun:NO longitude:nil latitude:nil alias:@"" token:@""]);
    [source refreshManual:YES]; assert(requests==1 && !source.caiyun && !source.snapshot);
    assert([source applyCaiyun:YES longitude:@0 latitude:@0 alias:@"C" token:@"OFFLINE_SECOND_DUMMY"]);
    assert(!source.snapshot); assert([source deleteToken]); assert(!store.token && !source.snapshot);
    [WCCPrefs() removePersistentDomainForName:suite];
    puts("PASS production Foundation render/source switch/config generation tests (offline)");
} return 0; }
