// NOT RUN: requires an iOS XCTest target linked with real src/*.m and WCC_TESTING.
// Include UIKit119Tests.m in the target for WCC119Controller (no host/weather I/O).
#import <XCTest/XCTest.h>
#import "../src/WCCContentViewController.h"
#import "../src/WCCPreferences.h"
@interface WCC119Controller : WCCContentViewController
- (void)expanded:(BOOL)value;
- (NSArray<NSArray<UIView *> *> *)positionRegions;
- (void)regionPositionChanged;
- (void)applyTextShadows;
@end
@interface UIKit120LayoutTests : XCTestCase @end
@implementation UIKit120LayoutTests
- (void)testRealLabelsAndCompleteRegionEndpoints {
 XCTAssertTrue(NSThread.isMainThread);
 NSString *suite=[@"test.weather120.layout." stringByAppendingString:NSUUID.UUID.UUIDString];
 WCCTestUsePreferences(suite);
 WCC119Controller *c=[WCC119Controller new]; [c loadViewIfNeeded]; [c expanded:NO];
 WCCLayoutSize layout={2,1};
 [c setValue:[NSValue value:&layout withObjCType:@encode(WCCLayoutSize)] forKey:@"layoutSize"];
 NSArray *groups=[c positionRegions];
 NSArray *texts=@[@[@"−12°",@"−8° / −19°"],@[],@[@"北京市海淀区",@"雷阵雨伴有冰雹",@"降水概率: 100%"],@[@"下午好，愿今天顺心"]];
 for(NSUInteger k=0;k<4;k++)for(NSUInteger j=0;j<[texts[k] count];j++)((UILabel *)groups[k][j]).text=texts[k][j];
 for(NSNumber *width in @[@156,@170,@180,@200]) {
  c.view.frame=CGRectMake(0,0,width.doubleValue,76);
  WCCResetRegionOffsets(-1); [c viewWillLayoutSubviews]; [c viewDidLayoutSubviews];
  for(NSArray *group in groups)for(UIView *v in group){XCTAssertFalse(v.hidden);XCTAssertFalse(CGRectIsEmpty(v.frame));XCTAssertGreaterThanOrEqual(CGRectGetMinX(v.frame),0);XCTAssertLessThanOrEqual(CGRectGetMaxX(v.frame),width.doubleValue);}
  for(NSUInteger k=0;k<4;k++)for(NSNumber *offset in @[@(-1366),@1366]) {
   WCCResetRegionOffsets(-1); XCTAssertTrue(WCCSetRegionOffset(k*2,offset.doubleValue));[c regionPositionChanged];
   CGRect frame=CGRectNull;for(UIView *v in groups[k])frame=CGRectIsNull(frame)?v.frame:CGRectUnion(frame,v.frame);
   if(offset.doubleValue<0)XCTAssertEqualWithAccuracy(CGRectGetMinX(frame),0,.01);else XCTAssertEqualWithAccuracy(CGRectGetMaxX(frame),width.doubleValue,.01);
  }
 }
 [c applyTextShadows];
 for(NSUInteger k=0;k<4;k++)if(k!=1)for(UILabel *label in groups[k]){XCTAssertNil(label.shadowColor);XCTAssertTrue(CGSizeEqualToSize(label.shadowOffset,CGSizeZero));}
 [WCCPrefs() removePersistentDomainForName:suite];
}
@end
