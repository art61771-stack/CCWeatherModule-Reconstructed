// NOT RUN locally: real iOS XCTest target, production src/*.m, WCC_TESTING.
#import <XCTest/XCTest.h>
#import "../src/WCCContentViewController.h"
#import "../src/WCCPreferences.h"
@interface WCC119Controller : WCCContentViewController
- (void)expanded:(BOOL)value;
- (NSArray<NSArray<UIView *> *> *)positionRegions;
- (void)drawGreeting;
- (void)regionPositionChanged;
@end
@interface UIKit120SettingsTests : XCTestCase @end
@implementation UIKit120SettingsTests
- (void)testFixedGreetingAndIndependentShadows {
 NSString *suite=[@"test.weather120.settings." stringByAppendingString:NSUUID.UUID.UUIDString];
 WCCTestUsePreferences(suite);
 WCC119Controller *c=[WCC119Controller new];[c loadViewIfNeeded];
 XCTAssertTrue(WCCSetCustomGreeting(YES,@"今天保持好心情"));
 NSArray *groups=[c positionRegions];UILabel *greeting=groups[3][0];
 for(NSNumber *expanded in @[@NO,@YES,@NO]) {
  [c expanded:expanded.boolValue];[c drawGreeting];[c regionPositionChanged];
  XCTAssertEqualObjects(greeting.text,@"今天保持好心情");
  for(NSInteger group=0;group<3;group++) {
   XCTAssertTrue(WCCSetTextShadowEnabled(group,YES));[c regionPositionChanged];
   for(NSInteger k=0;k<3;k++)for(UILabel *label in groups[k==0?0:k+1]) {
    if(k==group)XCTAssertNotNil(label.shadowColor);else XCTAssertNil(label.shadowColor);
   }
   XCTAssertTrue(WCCSetTextShadowEnabled(group,NO));
  }
 }
 XCTAssertFalse(WCCSetCustomGreeting(YES,@"   "));XCTAssertEqualObjects(greeting.text,@"今天保持好心情");
 XCTAssertTrue(WCCSetCustomGreeting(NO,WCCCustomGreetingText()));[c regionPositionChanged];
 NSString *random=[greeting.text copy];XCTAssertNotEqualObjects(random,@"今天保持好心情");
 WCCSetRegionOffset(6,1366);WCCSetTextShadowEnabled(2,YES);[c regionPositionChanged];
 XCTAssertEqualObjects(random,greeting.text);
 [WCCPrefs() removePersistentDomainForName:suite];
}
@end
