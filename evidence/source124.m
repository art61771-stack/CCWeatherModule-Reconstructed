#define main source120_main
#import "source120.m"
#undef main
@interface WCCWeatherSource (Test124)
- (void)scheduleResult:(CYResult *)r;
- (NSTimeInterval)refreshTTL;
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);NSString *suite=[@"source124." stringByAppendingString:NSUUID.UUID.UUIDString];WCCTestUsePreferences(suite);
 NSData *data=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];assert(data);
 for(NSNumber *hours in @[@0,@1,@12,@24]){
  [WCCPrefs() removePersistentDomainForName:suite];
  SourceStore *store=[SourceStore new];__block NSUInteger requests=0;__block CYWireReply pending;__block NSDate *clock=[NSDate date];
  CYCaiyunProvider *provider=[[CYCaiyunProvider alloc] initWithStore:store transport:^dispatch_block_t(NSURLRequest *req,CYWireReply reply){requests++;pending=[reply copy];return ^{};} clock:^{return clock;}];
  WCCWeatherSource *source=[WCCWeatherSource new];[source setValue:provider forKey:@"provider"];
  assert([source applyCaiyun:YES longitude:@0 latitude:@0 alias:@"offline" token:@"OFFLINE_TEST_ONLY"]);assert(requests==0);
  if(hours.intValue)assert([source setRefreshHours:hours.intValue]);
  double ttl=hours.intValue?hours.intValue*3600:900;assert(source.refreshTTL==ttl);
  [source setAutomaticActive:YES];assert(requests==1);pending(data,200,@{},nil);Drain();assert(source.snapshot);
  NSTimer *timer=[source valueForKey:@"refreshTimer"];assert(timer.valid && !timer.timeInterval);double remaining=timer.fireDate.timeIntervalSinceNow;assert(remaining>ttl-2 && remaining<=ttl);
  assert(provider.cacheTTL==ttl);
  clock=[clock dateByAddingTimeInterval:ttl-1];[source refreshManual:NO];Drain();assert(requests==1 && !source.stale);
  clock=[clock dateByAddingTimeInterval:2];[source refreshManual:NO];assert(requests==2);pending(data,200,@{},nil);Drain();assert(source.snapshot);
  // Schedule actual source against a receipt 120 seconds ago, then fire once.
  [source.snapshot setValue:[NSDate dateWithTimeIntervalSinceNow:-120] forKey:@"timestamp"];
  [source scheduleResult:[provider currentResult]];timer=[source valueForKey:@"refreshTimer"];remaining=timer.fireDate.timeIntervalSinceNow;assert(remaining>ttl-122 && remaining<=ttl-120);
  NSUInteger before=requests;clock=[clock dateByAddingTimeInterval:ttl+1];[timer fire];assert(requests==before+1);
  [source setAutomaticActive:NO];assert(![source valueForKey:@"refreshTimer"]);CYWireReply late=pending;late(data,200,@{},nil);Drain();assert(![source valueForKey:@"refreshTimer"]);
  [source setAutomaticActive:YES];Drain();[source setAutomaticActive:NO];
  assert(![source setRefreshHours:2]);WCCTestFailCommit(YES);NSInteger old=[WCCPrefs() integerForKey:@"caiyunRefreshHours124"];assert(![source setRefreshHours:12]);assert([WCCPrefs() integerForKey:@"caiyunRefreshHours124"]==old);WCCTestFailCommit(NO);
 }
 [WCCPrefs() removePersistentDomainForName:suite];puts("PASS124 real Foundation source/provider: legacy 900s and 1/12/24h cache expiry with injected clock/transport, single NSTimer deadline/120s receipt age/fire/inactive cancellation/late result guard, no-network save and preference rollback. No live API/background guarantee.");
}return 0;}
