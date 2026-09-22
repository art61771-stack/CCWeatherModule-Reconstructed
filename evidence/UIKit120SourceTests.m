// NOT RUN. Add to a real iOS 16.6 XCTest target with production src/*.m,
// CY_TESTING + WCC_TESTING. No live request or actual Keychain operation.
#import <XCTest/XCTest.h>
#import "../src/WCCContentViewController.h"
#import "../src/WCCWeatherSource.h"
#import "../src/WCCPreferences.h"
#import "../src/CYCaiyunProvider.h"
@interface WCCSourceTestController : WCCContentViewController @end
@implementation WCCSourceTestController
- (BOOL)initializeWeatherModel { return NO; } // prevent system location/API in test
- (void)refreshWeatherData {} // no live requests
@end
@interface UIKit120SourceTests : XCTestCase @end
@implementation UIKit120SourceTests
- (void)testAtomicMainHourlyAndSwitchWithoutSystemFramework {
    XCTAssertTrue(NSThread.isMainThread);
    NSString *suite=[@"weather.source.ui." stringByAppendingString:NSUUID.UUID.UUIDString]; WCCTestUsePreferences(suite);
    [WCCPrefs() setObject:@"caiyun" forKey:@"weatherProvider"];
    WCCWeatherSource *source=WCCWeatherSource.shared;
    NSDictionary *json=@{@"status":@"ok",@"timezone":@"Asia/Shanghai",@"result":@{
      @"realtime":@{@"status":@"ok",@"temperature":@0,@"skycon":@"CLEAR_NIGHT"},
      @"hourly":@{@"status":@"ok",@"temperature":@[@{@"datetime":@"2026-09-22T18:00+08:00",@"value":@0}],@"skycon":@[@{@"datetime":@"2026-09-22T18:00+08:00",@"value":@"CLEAR_NIGHT"}]}}};
    CYSnapshot *snapshot=[CYCaiyunProvider parseFixture:json now:[NSDate date] generation:1];
    [source setValue:snapshot forKey:@"snapshot"];
    WCCSourceTestController *c=[WCCSourceTestController new]; XCTAssertTrue(c.isInitialized); [c loadViewIfNeeded];
    [c updateWeatherDisplay]; [c willTransitionToExpandedContentMode:YES];
    XCTAssertEqualObjects([[c valueForKey:@"tempLabel"] text],@"0°");
    XCTAssertEqualObjects([c valueForKey:@"mediaAssetKey"],@"晴天-夜间");
    NSArray *hours=[c valueForKey:@"hourlyItems"]; XCTAssertEqual(hours.count,1u);
    XCTAssertEqualObjects([hours.firstObject valueForKey:@"assetKey"],@"晴天-夜间");
    [source setValue:nil forKey:@"snapshot"]; [c updateWeatherDisplay];
    XCTAssertEqualObjects([[c valueForKey:@"tempLabel"] text],@"--°");
    XCTAssertEqual([[c valueForKey:@"hourlyItems"] count],0u);
    XCTAssertTrue([source applyCaiyun:NO longitude:nil latitude:nil alias:@"" token:@""]);
    XCTAssertEqualObjects([[c valueForKey:@"conditionLabel"] text],@"未就绪");
    XCTAssertNil([c valueForKey:@"mediaAssetKey"]);
    [WCCPrefs() removePersistentDomainForName:suite];
}
@end
