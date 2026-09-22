#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

// Minimal declarations reconstructed from selectors, not Apple SDK headers.
@protocol CCUIContentModuleContentViewController <NSObject>
@optional
- (BOOL)shouldFinishTransitionToExpandedContentModule;
- (CGFloat)preferredExpandedContentHeight;
- (void)willTransitionToExpandedContentMode:(BOOL)expanded;
- (void)didTransitionToExpandedContentMode:(BOOL)expanded;
- (void)willBecomeActive;
- (void)controlCenterWillPresent;
@end
@protocol CCUIContentModule <NSObject>
@property(nonatomic, readonly) UIViewController *contentViewController;
@end
@protocol WATodayModelObserver <NSObject>
@optional
- (void)todayModelWantsUpdate:(id)model;
- (void)todayModel:(id)model forecastWasUpdated:(id)forecast;
- (void)todayModelUpdated:(id)model;
- (void)modelUpdatedForCity:(id)city;
@end
@interface NSObject (WCCWeatherPrivateSelectors)
- (id)todayModel;
- (id)forecastModel;
- (id)city;
- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;
- (void)_kickstartLocationManager;
- (void)_reloadForecastData:(BOOL)force;
- (void)executeModelUpdateWithCompletion:(void (^)(void))completion;
- (id)temperature;
- (double)celsius;
- (NSInteger)conditionCode;
- (BOOL)isDay;
- (NSString *)name;
- (NSArray *)hourlyForecasts;
- (NSArray *)dayForecasts;
- (id)high;
- (id)low;
- (NSString *)time;
- (NSDate *)date;
@end
