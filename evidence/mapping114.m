#import "../src/WCCPreferences.h"
#include <assert.h>
int main(void) { @autoreleasepool {
 NSUserDefaults *p=WCCPrefs(); [p removePersistentDomainForName:@"com.simon.ccweathermodule.custom"];
 [p setObject:@"legacy.gif" forKey:@"icon"]; assert(WCCMappedName(WCCAssetKey(32,NO))==nil);
 NSDictionary *map=@{@"小雨-白天":@"rain.gif",@"小雨-夜间":@"night.mp4",@"晴天-白天":@"sun.png"};
 [p setObject:map forKey:@"weatherIconMappings"];
 assert([WCCMappedName(WCCAssetKey(9,NO)) isEqual:@"rain.gif"]);
 assert([WCCMappedName(WCCAssetKey(9,YES)) isEqual:@"night.mp4"]);
 assert([WCCMappedName(WCCAssetKey(32,NO)) isEqual:@"sun.png"]);
 assert(!WCCMappedName(WCCAssetKey(31,YES)));
 assert(!WCCSafePath(WCCRoot(),@"nonexistent-file114.gif"));
 assert(!WCCMappedNameForKey((id)@"invalid",@"晴天-白天"));
 assert(!WCCMappedNameForKey(@{@"晴天-白天":@42},@"晴天-白天"));
 assert(!WCCMappedNameForKey(map,@"晴朗"));
 WCCSetMappedName(@"小雨-白天",nil);
 assert(!WCCMappedName(@"小雨-白天")); assert([WCCMappedName(@"小雨-夜间") isEqual:@"night.mp4"]);
 assert([p stringForKey:@"icon"]); [p removePersistentDomainForName:@"com.simon.ccweathermodule.custom"];
 puts("PASS production Foundation mappings: rain day/night, rain-to-sun, absent/invalid/legacy fallback, per-class clear; real UIKit playback NOT RUN.");
 } return 0; }
