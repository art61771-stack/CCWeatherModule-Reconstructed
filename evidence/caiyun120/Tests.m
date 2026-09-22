#import "CYCaiyunProvider.h"
#import <math.h>
#define CHECK(x) do { if(!(x)) { fprintf(stderr,"FAIL line %d\n",__LINE__); exit(1); } } while(0)
@interface MockStore : NSObject <CYTokenStore>
@property(nonatomic,copy) NSString *token;
@property(nonatomic) BOOL fail;
@end
@implementation MockStore
- (NSString *)readToken:(NSError **)error { if(self.fail){ if(error)*error=[NSError errorWithDomain:@"mock" code:1 userInfo:nil]; return nil; } return self.token; }
- (BOOL)writeToken:(NSString *)token error:(NSError **)error { if(self.fail)return NO; self.token=token; return YES; }
- (BOOL)removeToken:(NSError **)error { if(self.fail)return NO; self.token=nil; return YES; }
@end
static void Spin(BOOL (^done)(void)) {
    NSDate *end=[NSDate dateWithTimeIntervalSinceNow:3];
    while(!done() && [end timeIntervalSinceNow]>0) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    CHECK(done());
}
static CYResult *Refresh(CYCaiyunProvider *p, BOOL manual) {
    __block CYResult *r=nil; [p refreshManual:manual completion:^(CYResult *v){r=v;}]; Spin(^BOOL{return r!=nil;}); return r;
}
int main(int argc,const char *argv[]) { @autoreleasepool {
    CHECK(argc==2);
    NSData *data=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]]; CHECK(data);
    NSMutableDictionary *json=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL]; CHECK(json);
    NSISO8601DateFormatter *iso=[NSISO8601DateFormatter new];
    // UTC Sep 21, but target location Sep 22: must select the Sep 22 daily row.
    __block NSDate *now=[iso dateFromString:@"2026-09-21T20:00:00Z"]; CHECK(now);
    CYSnapshot *s=[CYCaiyunProvider parseFixture:json now:now generation:8];
    CHECK(s.configGeneration==8 && [s.source isEqual:@"caiyun"]);
    CHECK(s.currentTemperature && s.currentTemperature.doubleValue==0 && s.minimum.doubleValue==0 && s.maximum.doubleValue==26);
    CHECK([s.condition.basename isEqual:@"晴天-夜间"] && s.hours.count==4);
    CHECK(s.hours[0].temperature.doubleValue==0 && [s.hours[0].condition.basename isEqual:@"小雪-白天"]);
    CHECK(s.hours[1].temperature.doubleValue==18 && s.hours[1].probability.doubleValue==1);
    CHECK(s.hours[0].probability.doubleValue==0 && [s.hours[2].condition.basename isEqual:@"小雨-夜间"]);
    CHECK(!s.hours[2].temperature && !s.hours[3].temperature && !s.hours[3].probability);
    CHECK([s.hours[3].condition.text isEqual:@"未知"] && !s.hours[3].condition.basename);
    NSMutableDictionary *daily=json[@"result"][@"daily"]; [daily removeObjectForKey:@"astro"];
    s=[CYCaiyunProvider parseFixture:json now:now generation:1];
    CHECK(!s.hours[0].condition.basename && !s.hours[2].condition.basename);
    json[@"timezone"]=@"not-a-timezone"; s=[CYCaiyunProvider parseFixture:json now:now generation:1]; CHECK(s.timezone && s.maximum.doubleValue==26);
    json[@"tzshift"]=@YES; s=[CYCaiyunProvider parseFixture:json now:now generation:1]; CHECK(!s.timezone && !s.maximum);
    json[@"result"][@"realtime"][@"temperature"]=@(NAN);
    s=[CYCaiyunProvider parseFixture:json now:now generation:1]; CHECK(!s.currentTemperature);
    CHECK([CYCaiyunProvider validateLongitude:@0 latitude:@0]);
    CHECK(![CYCaiyunProvider validateLongitude:nil latitude:@0]);
    CHECK(![CYCaiyunProvider validateLongitude:@YES latitude:@0]);
    CHECK(![CYCaiyunProvider validateLongitude:@(NAN) latitude:@0]);
    CHECK(![CYCaiyunProvider validateLongitude:@181 latitude:@0]);
    CHECK(![CYCaiyunProvider validateLongitude:@0 latitude:@91]);
    for(NSString *bad in @[@"",@"../x",@"x/y",@"x%2fy",@"x?y",@"x\ny",@"x\\y"])CHECK(![CYCaiyunProvider validateToken:bad]);
    MockStore *store=[MockStore new];
    __block NSUInteger calls=0,cancels=0; __block CYWireReply pending=nil;
    CYTransport transport=^dispatch_block_t(NSURLRequest *request,CYWireReply reply){
        ++calls; pending=[reply copy];
        NSURLComponents *u=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
        CHECK([u.scheme isEqual:@"https"] && [u.host isEqual:@"api.caiyunapp.com"]);
        CHECK([u.path hasSuffix:@"/weather"] && request.cachePolicy==NSURLRequestReloadIgnoringLocalCacheData);
        NSMutableDictionary *q=[NSMutableDictionary new]; for(NSURLQueryItem *i in u.queryItems)q[i.name]=i.value;
        CHECK([q[@"unit"] isEqual:@"metric:v2"] && [q[@"hourlysteps"] isEqual:@"24"] && [q[@"alert"] isEqual:@"false"]);
        return ^{ ++cancels; };
    };
    CYCaiyunProvider *p=[[CYCaiyunProvider alloc] initWithStore:store transport:transport clock:^{ return now; }];
    CHECK(Refresh(p,NO).error.code==CYNotConfigured && calls==0);
    CHECK([p saveToken:@"DUMMY_OFFLINE_NOT_A_REAL_CAIYUN_CREDENTIAL" error:NULL]);
    CHECK([p setLongitude:@0 latitude:@0 error:NULL]);
    __block CYResult *r1=nil,*r2=nil;
    [p refreshManual:NO completion:^(CYResult *r){r1=r;}]; [p refreshManual:YES completion:^(CYResult *r){r2=r;}];
    CHECK(calls==1); pending(data,200,@{},nil); Spin(^BOOL{return r1 && r2;}); CHECK(r1.snapshot && r2.snapshot==r1.snapshot);
    CHECK(Refresh(p,NO).snapshot && calls==1); // TTL hit
    CHECK(Refresh(p,YES).error.code==CYThrottled && calls==1);
    now=[now dateByAddingTimeInterval:61]; r1=nil;
    [p refreshManual:YES completion:^(CYResult *r){r1=r;}]; CHECK(calls==2);
    NSData *html=[@"<html>synthetic upstream failure</html>" dataUsingEncoding:NSUTF8StringEncoding];
    pending(html,429,@{@"Retry-After":@"999999"},nil); Spin(^BOOL{return r1!=nil;});
    CHECK(r1.snapshot && r1.stale && r1.error.code==CYRateLimited);
    CHECK([r1.nextAllowedRefresh timeIntervalSinceDate:now]<=3600);
    CHECK(Refresh(p,NO).error.code==CYRateLimited && calls==2);
    now=[now dateByAddingTimeInterval:3601]; r1=nil;
    [p refreshManual:NO completion:^(CYResult *r){r1=r;}]; pending(html,500,@{},nil); Spin(^BOOL{return r1!=nil;}); CHECK(r1.stale && r1.error.code==CYServerFailure);
    now=[now dateByAddingTimeInterval:3601]; r1=nil;
    [p refreshManual:NO completion:^(CYResult *r){r1=r;}]; CYWireReply old=[pending copy];
    CHECK([p setLongitude:@120 latitude:@30 error:NULL]);
    CHECK(!p.currentResult.snapshot); old(data,200,@{},nil); Spin(^BOOL{return r1!=nil;});
    CHECK(r1.error.code==CYCancelled && !p.currentResult.snapshot && cancels>0);
    now=[now dateByAddingTimeInterval:61]; r1=nil;
    [p refreshManual:NO completion:^(CYResult *r){r1=r;}]; pending(data,200,@{},nil); Spin(^BOOL{return r1!=nil;}); CHECK(r1.snapshot);
    now=[now dateByAddingTimeInterval:901]; r1=nil;
    [p refreshManual:NO completion:^(CYResult *r){r1=r;}]; pending(html,200,@{},nil); Spin(^BOOL{return r1!=nil;}); CHECK(r1.stale && r1.error.code==CYInvalidResponse);
    now=[now dateByAddingTimeInterval:3601]; r1=nil;
    [p refreshManual:NO completion:^(CYResult *r){r1=r;}];
    pending(nil,0,@{},[NSError errorWithDomain:@"synthetic-network" code:-1 userInfo:@{@"private-detail":@"do-not-propagate"}]);
    Spin(^BOOL{return r1!=nil;}); CHECK(r1.error.code==CYNetworkFailure && r1.error.userInfo.count==1);
    now=[now dateByAddingTimeInterval:3601]; r1=nil;
    [p refreshManual:NO completion:^(CYResult *r){r1=r;}]; old=[pending copy]; [p cancel]; old(data,200,@{},nil);
    Spin(^BOOL{return r1!=nil;}); CHECK(r1.error.code==CYCancelled);
    [p clearCache]; CHECK(!p.currentResult.snapshot);
    store.fail=YES; NSError *e=nil; CHECK(![p saveToken:@"DUMMY_REPLACEMENT_OFFLINE_ONLY" error:&e]);
    CHECK(e.code==CYKeychainFailure && e.userInfo.count==1 && !p.currentResult.snapshot);
    NSUInteger before=calls; CHECK(Refresh(p,YES).error && calls==before);
    CHECK(![p deleteToken:&e] && e.code==CYKeychainFailure);
    store.fail=NO; CHECK([p deleteToken:&e] && ![p hasToken:NULL]);
    CHECK(Refresh(p,NO).error.code==CYNotConfigured);
    // No assertions/logging ever print NSURLRequest, URLs, tokens, raw server errors.
    puts("PASS offline Foundation fixtures/state machine; Security mock only; live API NOT RUN");
} return 0; }
