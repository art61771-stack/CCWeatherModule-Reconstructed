#import "PrivateInterfaces.h"
@interface WCCContentViewController : UIViewController <CCUIContentModuleContentViewController, WATodayModelObserver> {
    UIViewController *_lockscreenController;
    UIView *_headerView;
    UIImageView *_iconView;
    UILabel *_cityLabel, *_conditionLabel, *_precipLabel, *_tempLabel, *_highLowLabel;
    UIView *_hourlyContainer, *_dividerLine;
    UIScrollView *_hourlyScrollView;
    id _currentCity;
    BOOL _isExpanded;
    NSInteger _displayMode;
    NSString *_customLocationName, *_cachedSubLocality, *_cachedLocationID;
}
@property(nonatomic,strong) id weatherModel;
@property(nonatomic,strong) id forecast;
@property(nonatomic,assign) BOOL isInitialized;
- (BOOL)initializeWeatherModel;
- (void)forceCityUpdate;
- (void)setupHeaderView;
- (void)setupHourlyContainer;
- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture;
- (void)handleTwoFingerDoubleTap:(UITapGestureRecognizer *)gesture;
- (void)showCustomNameAlert;
- (void)updateWeatherDisplay;
- (void)updateCityLabel;
- (void)updatePrecipitation;
- (NSString *)temperatureString:(id)temperature;
- (NSString *)highLowTemperatureString;
- (NSString *)conditionStringForCode:(NSInteger)code;
- (NSString *)localizedConditionForCode:(NSInteger)code;
- (void)updateWeatherIcon;
- (UIImage *)systemWeatherImageForConditionCode:(NSInteger)code;
- (NSString *)imageNameForConditionCode:(NSInteger)code;
- (NSString *)systemSymbolForConditionCode:(NSInteger)code;
- (NSString *)sfSymbolForConditionCode:(NSInteger)code;
- (void)updateHourlyForecast;
- (UIView *)createHourlyItemWithForecast:(id)forecast isNow:(BOOL)isNow formatter:(NSDateFormatter *)formatter;
- (void)refreshWeatherData;
@end
