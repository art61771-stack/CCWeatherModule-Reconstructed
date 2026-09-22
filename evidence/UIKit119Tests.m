// Add this file and src/*.m to an iOS XCTest target; do not run in SpringBoard.
// Apple UIKit/XCTest required. Uses real production layout methods and constraints.
#import <XCTest/XCTest.h>
#import "../src/WCCContentViewController.h"
#import "../src/WCCPreferences.h"
#import "../src/WCCConfigurations.h"
#import "../src/WCCMedia.h"
@interface WCCContentViewController (Tests119)
- (void)applyRegionPositions;
- (void)layoutMainCustomMedia;
- (void)regionPositionChanged;
- (void)mainIconScaleChanged;
- (NSArray<NSArray<UIView *> *> *)positionRegions;
@end
@interface WCC119Controller : WCCContentViewController
@property NSUInteger draws, weatherUpdates, hourlyUpdates;
- (void)expanded:(BOOL)value;
@end
@implementation WCC119Controller
- (BOOL)initializeWeatherModel { return NO; }
- (void)loadView { self.view=[[UIView alloc] initWithFrame:CGRectMake(0,0,320,160)]; }
- (void)viewDidLoad { [self setupHeaderView]; [self setupHourlyContainer]; }
- (void)drawGreeting { self.draws++; }
- (void)updateWeatherIcon { self.weatherUpdates++; }
- (void)updateHourlyForecast { self.hourlyUpdates++; }
- (void)expanded:(BOOL)value { _isExpanded=value; }
@end
@interface WCC119Media : WCCMediaView
@property NSUInteger loads;
@end
@implementation WCC119Media
- (void)loadPath:(NSString *)path { self.loads++; }
@end
@interface UIKit119Tests : XCTestCase @end
@implementation UIKit119Tests
- (void)testProductionRepeatedGeometryAndModeIsolation {
 XCTAssertTrue(NSThread.isMainThread);
 NSString *suite=[@"test.weather119.ui." stringByAppendingString:NSUUID.UUID.UUIDString];
 WCCTestUsePreferences(suite);
 NSString *tmp=[NSTemporaryDirectory().stringByResolvingSymlinksInPath stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
 WCCTestUseConfigurationDirectory(tmp);
 WCC119Controller *c=[WCC119Controller new];[c loadViewIfNeeded];
 [NSNotificationCenter.defaultCenter addObserver:c selector:@selector(regionPositionChanged) name:WCCRegionPositionChanged object:nil];
 NSArray *groups=[c positionRegions];UIImageView *icon=groups[1][0];
 WCC119Media *media=[WCC119Media new];[[c valueForKey:@"customMedia"] removeFromSuperview];
 [c setValue:media forKey:@"customMedia"];[icon addSubview:media];
 NSArray *sizes=@[@[@2,@1],@[@3,@1],@[@4,@1],@[@2,@2],@[@3,@3]];
 for(NSArray *size in sizes){
  WCCLayoutSize layout={[size[0] unsignedIntegerValue],[size[1] unsignedIntegerValue]};
  [c setValue:[NSValue value:&layout withObjCType:@encode(WCCLayoutSize)] forKey:@"layoutSize"];
  [c expanded:NO];c.view.frame=CGRectMake(0,0,layout.width*78,layout.height*76);
  WCCResetRegionOffsets(-1);WCCSetMainIconPercent(100);
  [c viewWillLayoutSubviews];[c viewDidLayoutSubviews];
  NSMutableArray *baseline=[NSMutableArray array];for(NSArray *g in groups)for(UIView *v in g)[baseline addObject:[NSValue valueWithCGRect:v.frame]];
  for(NSInteger k=0;k<8;k++){
   WCCResetRegionOffsets(-1);WCCSetRegionOffset(k,17);[c regionPositionChanged];
   NSUInteger j=0;for(NSUInteger group=0;group<4;group++)for(UIView *v in groups[group]){if(group!=k/2)XCTAssertTrue(CGRectEqualToRect(v.frame,[baseline[j] CGRectValue]));j++;}
  }
  for(NSInteger k=0;k<8;k++)WCCSetRegionOffset(k,k%2?-9:17);
  for(NSNumber *percent in @[@50,@100,@150]){
   WCCSetMainIconPercent(percent.doubleValue);[c regionPositionChanged];CGRect target=icon.frame;
   for(int repeat=0;repeat<20;repeat++){
    [c viewWillLayoutSubviews];[c viewDidLayoutSubviews];XCTAssertTrue(CGRectEqualToRect(target,icon.frame));
    // Toggle image/fallback and media visibility without changing the layout slot.
    for(int type=0;type<3;type++){media.hidden=type!=1;icon.image=type==1?nil:[UIImage systemImageNamed:@"cloud.fill"];[c mainIconScaleChanged];XCTAssertTrue(CGRectEqualToRect(target,icon.frame));XCTAssertTrue(CGRectEqualToRect(media.frame,icon.bounds));}
   }
   [c expanded:YES];c.view.frame=CGRectMake(0,0,320,180);[c viewWillLayoutSubviews];[c viewDidLayoutSubviews];
   NSMutableArray *expanded=[NSMutableArray array];for(NSArray *g in groups)for(UIView *v in g)[expanded addObject:[NSValue valueWithCGRect:v.frame]];
   NSError *error=nil;NSString *name=NSUUID.UUID.UUIDString;
   XCTAssertTrue(WCCSaveConfiguration(name,nil,&error));
   NSString *planID=nil;for(NSDictionary *item in WCCConfigurations(&error))if([item[@"name"] isEqual:name])planID=item[@"id"];
   for(NSInteger k=0;k<8;k++)WCCSetRegionOffset(k,-40);
   XCTAssertTrue(WCCLoadConfiguration(planID,&error));
   [c regionPositionChanged];NSUInteger j=0;for(NSArray *g in groups)for(UIView *v in g)XCTAssertTrue(CGRectEqualToRect(v.frame,[expanded[j++] CGRectValue]));
   for(NSInteger k=0;k<8;k++)WCCSetRegionOffset(k,k%2?-9:17);
   [c expanded:NO];c.view.frame=CGRectMake(0,0,layout.width*78,layout.height*76);[c viewWillLayoutSubviews];[c viewDidLayoutSubviews];XCTAssertTrue(CGRectEqualToRect(target,icon.frame));
  }
 }
 XCTAssertEqual(c.draws,0u);XCTAssertEqual(c.weatherUpdates,0u);XCTAssertEqual(c.hourlyUpdates,0u);XCTAssertEqual(media.loads,0u);
 [NSNotificationCenter.defaultCenter removeObserver:c];
 [WCCPrefs() removePersistentDomainForName:suite];
 [NSFileManager.defaultManager removeItemAtPath:tmp error:NULL];
}
@end
