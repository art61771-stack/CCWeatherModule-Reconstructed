#import "WCCContentViewController.h"
#import <dlfcn.h>
#import "WCCPreferences.h"
#import "WCCSettings.h"
#import "WCCMedia.h"
#import "WCCRuntime.h"
static CGRect WCCCGRect(WCCRect r) { return CGRectMake(r.x,r.y,r.w,r.h); }
@interface WCCContentViewController ()
@property(nonatomic,strong) UILabel *greetingLabel;
@property(nonatomic) WCCGreetingState greetingState;
@property(nonatomic,strong) WCCMediaView *customMedia;
@property(nonatomic) BOOL mediaVisible;
@end

@interface WCCVisibilityView : UIView
@property(nonatomic,copy) void (^visibilityChanged)(BOOL visible);
@end
@implementation WCCVisibilityView
- (void)didMoveToWindow { [super didMoveToWindow]; if (self.visibilityChanged) self.visibilityChanged(self.window!=nil); }
@end

// The original passes @YES through performSelector:withObject:, not a BOOL ABI call.
static void WCCEnable(id object, SEL selector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([object respondsToSelector:selector]) [object performSelector:selector withObject:@YES];
#pragma clang diagnostic pop
}
static UILabel *WCCLabel(CGFloat size, UIFontWeight weight, CGFloat alpha) {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = [UIColor colorWithWhite:1 alpha:alpha];
    return label;
}
@implementation WCCContentViewController
- (instancetype)init {
    if ((self = [super init])) {
        _isInitialized = NO; _isExpanded = NO; _displayMode = 0; _greetingState = (WCCGreetingState){0,-1};
        _customLocationName = nil;
        _isInitialized = [self initializeWeatherModel];
    }
    return self;
}
- (BOOL)initializeWeatherModel {
    @try {
        Class cls = NSClassFromString(@"WALockscreenWidgetViewController");
        if (!cls) return NO;
        _lockscreenController = [cls new];
        if (!_lockscreenController) return NO;
        [_lockscreenController viewWillAppear:YES];
        [_lockscreenController viewDidAppear:YES];
        _weatherModel = [_lockscreenController todayModel];
        if (!_weatherModel) return NO;
        [_weatherModel addObserver:self];
        WCCEnable(_weatherModel, NSSelectorFromString(@"setIsLocationTrackingEnabled:"));
        WCCEnable(_weatherModel, NSSelectorFromString(@"setLocationServicesActive:"));
        if ([_weatherModel respondsToSelector:@selector(_kickstartLocationManager)]) [_weatherModel _kickstartLocationManager];
        if ([_weatherModel respondsToSelector:@selector(_reloadForecastData:)]) [_weatherModel _reloadForecastData:YES];
        if ([_weatherModel respondsToSelector:@selector(executeModelUpdateWithCompletion:)]) {
            [_weatherModel executeModelUpdateWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{ [self updateWeatherDisplay]; });
            }];
        }
        return YES;
    } @catch (NSException *exception) { return NO; }
}
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    @try { if (_weatherModel) [_weatherModel removeObserver:self]; }
    @catch (NSException *exception) {}
}
- (BOOL)shouldFinishTransitionToExpandedContentModule { return YES; }
- (CGFloat)preferredExpandedContentHeight { return 180; }
- (void)willTransitionToExpandedContentMode:(BOOL)expanded {
    _isExpanded = expanded;
    if (expanded) [self updateHourlyForecast];
    _hourlyContainer.alpha = expanded ? 1 : 0;
    [self.view setNeedsLayout];
}
- (void)didTransitionToExpandedContentMode:(BOOL)expanded { _isExpanded = expanded; }
- (void)willBecomeActive { [self beginGreetingSession]; self.mediaVisible=YES; [self preferencesChanged]; [self refreshWeatherData]; }
- (void)beginGreetingSession {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = NSTimeZone.localTimeZone;
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:NSDate.date];
    WCCGreetingState state=self.greetingState;
    int index=WCCBeginGreeting(&state,(int)hour,arc4random_uniform(6)); self.greetingState=state;
    // Always bind text, even when session started before UILabel creation.
    self.greetingLabel.text=[NSString stringWithUTF8String:WCCGreetingText(index)];
    self.greetingLabel.hidden=NO; self.greetingLabel.alpha=1;
}
- (void)endGreetingSession { WCCGreetingState state=self.greetingState; WCCEndGreeting(&state); self.greetingState=state; }
- (void)loadView {
    WCCVisibilityView *view=[WCCVisibilityView new]; __weak typeof(self) weak=self;
    view.visibilityChanged=^(BOOL visible) {
        typeof(self) self=weak; if (!self) return;
        if (visible) { [self beginGreetingSession]; self.mediaVisible=YES; [self preferencesChanged]; }
        else if (!self.presentedViewController) { [self endGreetingSession]; self.mediaVisible=NO; self.customMedia.active=NO; }
    }; self.view=view;
}
- (void)controlCenterWillPresent { [self beginGreetingSession]; self.mediaVisible = YES; [self preferencesChanged]; [self refreshWeatherData]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(preferencesChanged) name:WCCPreferencesChanged object:nil];
    self.view.backgroundColor = UIColor.clearColor;
    [self setupHeaderView]; [self setupHourlyContainer];
    [self preferencesChanged]; [self updateWeatherDisplay]; [self forceCityUpdate];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self refreshWeatherData]; });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self refreshWeatherData]; });
}
- (void)forceCityUpdate {
    @try {
        id city = [[_weatherModel forecastModel] city];
        WCCEnable(city, NSSelectorFromString(@"setAutoUpdate:"));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([city respondsToSelector:NSSelectorFromString(@"update")]) [city performSelector:NSSelectorFromString(@"update")];
#pragma clang diagnostic pop
    } @catch (NSException *exception) {}
}
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGSize size = self.view.bounds.size;
    WCCGeometry g = WCCComputeGeometry(size.width, size.height, _isExpanded);
    _headerView.transform = CGAffineTransformIdentity;
    _headerView.frame = CGRectMake(0, 0, size.width, g.headerHeight);
    _iconView.transform = CGAffineTransformIdentity;
    _iconView.frame = WCCCGRect(g.icon);
    self.customMedia.transform = CGAffineTransformIdentity;
    self.customMedia.frame = _iconView.bounds;
    _cityLabel.frame = WCCCGRect(g.city); _tempLabel.frame = WCCCGRect(g.temperature);
    _conditionLabel.frame = WCCCGRect(g.condition); _highLowLabel.frame = WCCCGRect(g.highLow);
    _precipLabel.frame = WCCCGRect(g.precipitation); self.greetingLabel.frame = WCCCGRect(g.greeting);
    _precipLabel.hidden = !g.details; _highLowLabel.hidden = !g.details;
    _precipLabel.font = [UIFont systemFontOfSize:MAX(1,g.detailFont) weight:UIFontWeightRegular];
    _tempLabel.font = [UIFont systemFontOfSize:MAX(1,g.tempFont) weight:UIFontWeightLight];
    _cityLabel.font = [UIFont systemFontOfSize:MAX(1,g.cityFont) weight:UIFontWeightSemibold];
    _conditionLabel.font = _highLowLabel.font = [UIFont systemFontOfSize:MAX(1,g.detailFont) weight:UIFontWeightRegular];
    self.greetingLabel.font = [UIFont systemFontOfSize:MAX(1,g.greetingFont) weight:UIFontWeightRegular];
    _tempLabel.textAlignment = NSTextAlignmentLeft;
    _highLowLabel.textAlignment = NSTextAlignmentLeft;
    self.greetingLabel.hidden=NO; self.greetingLabel.alpha=1;
    [_headerView bringSubviewToFront:self.greetingLabel];
    if (self.view.window) [self beginGreetingSession];
    _hourlyContainer.frame = CGRectMake(0, g.headerHeight, size.width, MAX(0,size.height-g.headerHeight));
    _hourlyContainer.hidden = !_isExpanded;
}
- (void)refreshWeatherData {
    if (!_weatherModel) return;
    @try {
        WCCEnable(_weatherModel, NSSelectorFromString(@"setLocationServicesActive:"));
        if ([_weatherModel respondsToSelector:@selector(_kickstartLocationManager)]) [_weatherModel _kickstartLocationManager];
        if ([_weatherModel respondsToSelector:@selector(_reloadForecastData:)]) [_weatherModel _reloadForecastData:YES];
        if ([_weatherModel respondsToSelector:@selector(executeModelUpdateWithCompletion:)]) {
            [_weatherModel executeModelUpdateWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{ [self updateWeatherDisplay]; });
            }];
        } else [self updateWeatherDisplay];
    } @catch (NSException *exception) {}
}
- (void)todayModelWantsUpdate:(id)model { /* Original 0x7888 is a bare return. */ }
- (void)todayModel:(id)model forecastWasUpdated:(id)forecast {
    dispatch_async(dispatch_get_main_queue(), ^{ [self updateWeatherDisplay]; });
}
- (void)todayModelUpdated:(id)model {
    dispatch_async(dispatch_get_main_queue(), ^{ [self updateWeatherDisplay]; });
}
- (void)modelUpdatedForCity:(id)city {
    dispatch_async(dispatch_get_main_queue(), ^{ [self updateWeatherDisplay]; });
}

- (void)setupHeaderView {
    _headerView = [UIView new]; _headerView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_headerView];
    _iconView = [UIImageView new]; _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.tintColor = UIColor.whiteColor;
    _cityLabel = WCCLabel(18, UIFontWeightSemibold, 1);
    _conditionLabel = WCCLabel(13, UIFontWeightRegular, .8);
    _precipLabel = WCCLabel(12, UIFontWeightRegular, .6);
    _tempLabel = WCCLabel(38, UIFontWeightLight, 1);
    _highLowLabel = WCCLabel(13, UIFontWeightRegular, .7);
    _tempLabel.textAlignment = _highLowLabel.textAlignment = NSTextAlignmentRight;
    self.greetingLabel = WCCLabel(11, UIFontWeightRegular, .82);
    self.greetingLabel.text=[NSString stringWithUTF8String:WCCGreetingText(self.greetingState.index)];
    self.greetingLabel.accessibilityIdentifier=@"weather.greeting";
    _headerView.clipsToBounds = YES;
    for (UIView *view in @[_iconView, _cityLabel, _conditionLabel, _precipLabel, _tempLabel, _highLowLabel, self.greetingLabel]) {
        [_headerView addSubview:view];
        if ([view isKindOfClass:UILabel.class]) {
            UILabel *label = (UILabel *)view;
            label.numberOfLines = 1; label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = .65; label.lineBreakMode = NSLineBreakByTruncatingTail;
        }
    }
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    tap.numberOfTapsRequired = 2; tap.numberOfTouchesRequired = 1;
    UITapGestureRecognizer *settingsTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerDoubleTap:)];
    settingsTap.numberOfTapsRequired = 2; settingsTap.numberOfTouchesRequired = 2;
    [tap requireGestureRecognizerToFail:settingsTap];
    [self.view addGestureRecognizer:tap];
    [self.view addGestureRecognizer:settingsTap];
    _headerView.userInteractionEnabled = YES;
    self.customMedia = [[WCCMediaView alloc] initWithFrame:_iconView.bounds];
    self.customMedia.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_iconView addSubview:self.customMedia];
    __weak typeof(self) weak = self;
    self.customMedia.mediaChanged = ^{ [weak updateWeatherIcon]; };
}
- (void)setupHourlyContainer {
    _hourlyContainer = [UIView new]; _hourlyContainer.backgroundColor = UIColor.clearColor;
    _hourlyContainer.alpha = 0; [self.view addSubview:_hourlyContainer];
    _dividerLine = [UIView new]; _dividerLine.backgroundColor = [UIColor colorWithWhite:1 alpha:.3];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO; [_hourlyContainer addSubview:_dividerLine];
    _hourlyScrollView = [UIScrollView new]; _hourlyScrollView.showsHorizontalScrollIndicator = NO;
    _hourlyScrollView.translatesAutoresizingMaskIntoConstraints = NO; [_hourlyContainer addSubview:_hourlyScrollView];
    [NSLayoutConstraint activateConstraints:@[
        [_dividerLine.leadingAnchor constraintEqualToAnchor:_hourlyContainer.leadingAnchor constant:16],
        [_dividerLine.trailingAnchor constraintEqualToAnchor:_hourlyContainer.trailingAnchor constant:-16],
        [_dividerLine.topAnchor constraintEqualToAnchor:_hourlyContainer.topAnchor],
        [_dividerLine.heightAnchor constraintEqualToConstant:.5],
        [_hourlyScrollView.leadingAnchor constraintEqualToAnchor:_hourlyContainer.leadingAnchor],
        [_hourlyScrollView.trailingAnchor constraintEqualToAnchor:_hourlyContainer.trailingAnchor],
        [_hourlyScrollView.topAnchor constraintEqualToAnchor:_dividerLine.bottomAnchor constant:8],
        [_hourlyScrollView.bottomAnchor constraintEqualToAnchor:_hourlyContainer.bottomAnchor]
    ]];
}
- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized || self.presentedViewController) return;
    // Single-finger double tap retains the original nearby/city toggle.
    _displayMode = _displayMode == 0 ? 1 : 0;
    [WCCPrefs() setInteger:_displayMode forKey:@"displayMode"];
    [WCCPrefs() synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:WCCPreferencesChanged object:nil];
    [self updateCityLabel];
}
- (void)handleTwoFingerDoubleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized || self.presentedViewController) return;
    self.customMedia.active = NO;
    __weak typeof(self) weak = self;
    [WCCSettings presentFrom:self completion:^{ [weak preferencesChanged]; }];
}
- (void)showCustomNameAlert {
    if (self.presentedViewController) return;
    self.customMedia.active = NO;
    __weak typeof(self) weak = self;
    [WCCSettings editLandmarkFrom:self completion:^{ [weak preferencesChanged]; }];
}
- (void)preferencesChanged {
    _displayMode = MAX(0, MIN(2, [WCCPrefs() integerForKey:@"displayMode"]));
    _customLocationName = [WCCPrefs() stringForKey:@"landmark"];
    if (_displayMode == 2 && !_customLocationName.length) _displayMode = 0;
    [self updateCityLabel]; [self updateWeatherIcon];
    NSString *path = [WCCPrefs() boolForKey:@"customIcon"] ? WCCSafePath(WCCRoot(), [WCCPrefs() stringForKey:@"icon"]) : nil;
    [self.customMedia loadPath:path];
    self.customMedia.active = self.mediaVisible && !self.presentedViewController;
}
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; [self beginGreetingSession]; self.mediaVisible = YES; [self preferencesChanged]; }
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated]; self.mediaVisible = NO; self.customMedia.active = NO; }
- (void)viewDidDisappear:(BOOL)animated { [super viewDidDisappear:animated]; if (!self.presentedViewController) [self endGreetingSession]; }
- (void)controlCenterDidDismiss { [self endGreetingSession]; self.mediaVisible = NO; self.customMedia.active = NO; }
- (void)willResignActive { if (!self.presentedViewController) [self endGreetingSession]; self.mediaVisible = NO; self.customMedia.active = NO; }

- (void)updateWeatherDisplay {
    if (!_weatherModel) return;
    @try {
        _currentCity = [[_weatherModel forecastModel] city];
        if (!_currentCity) return;
        [self updateCityLabel];
        if ([_currentCity temperature] || [[_currentCity dayForecasts] count]) {
            _conditionLabel.text = [self conditionStringForCode:[_currentCity conditionCode]];
            _tempLabel.text = [self temperatureString:[_currentCity temperature]];
            _highLowLabel.text = [self highLowTemperatureString];
            [self updatePrecipitation]; [self updateWeatherIcon];
            if (_isExpanded) [self updateHourlyForecast];
        } else {
            _conditionLabel.text = @"加载中..."; _tempLabel.text = @"--°";
            _highLowLabel.text = @"-- / --"; _precipLabel.text = @"";
        }
    } @catch (NSException *exception) {}
}
- (void)updateCityLabel {
    if (!_currentCity) return;
    @try {
        if (_displayMode == 2) { _cityLabel.text = _customLocationName ?: @"--"; return; }
        if (_displayMode != 0) { _cityLabel.text = [_currentCity name] ?: @"--"; return; }
        double latitude = [[_currentCity valueForKey:@"latitude"] doubleValue];
        double longitude = [[_currentCity valueForKey:@"longitude"] doubleValue];
        NSString *locationID = [NSString stringWithFormat:@"%.4f,%.4f", latitude, longitude];
        if (_cachedSubLocality && [_cachedLocationID isEqualToString:locationID]) {
            _cityLabel.text = _cachedSubLocality; return;
        }
        if (latitude != 0 && longitude != 0) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [CLGeocoder new];
            [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> *places, NSError *error) {
                if (error || !places.count) return;
                CLPlacemark *place = places[0];
                NSString *name = place.subLocality;
                if (!name.length) name = place.subAdministrativeArea;
                if (!name.length) return;
                self->_cachedSubLocality = name; self->_cachedLocationID = locationID;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self->_displayMode == 0) self->_cityLabel.text = name;
                });
            }];
        }
        _cityLabel.text = [_currentCity name];
    } @catch (NSException *exception) { _cityLabel.text = [_currentCity name]; }
}
- (void)updatePrecipitation {
    if (!_currentCity) { _precipLabel.text = @""; return; }
    @try {
        float chance = 0;
        @try { chance = [[[[_currentCity hourlyForecasts] firstObject] valueForKey:@"percentPrecipitation"] floatValue]; }
        @catch (NSException *exception) {}
        @try {
            float day = [[[[_currentCity dayForecasts] firstObject] valueForKey:@"percentPrecipitation"] floatValue];
            if (day > chance) chance = day;
        } @catch (NSException *exception) {}
        // Preserve the binary's strict <1 boundary: exactly 1 means 1%, not 100%.
        if (chance > 0 && chance < 1) chance *= 100;
        _precipLabel.text = chance > 0 ? [NSString stringWithFormat:@"降水概率: %.0f%%", (double)chance] : @"降水概率: 0%";
    } @catch (NSException *exception) { _precipLabel.text = @""; }
}
- (NSString *)temperatureString:(id)temperature {
    if (!temperature) return @"--°";
    @try {
        if ([temperature respondsToSelector:@selector(celsius)]) return [NSString stringWithFormat:@"%.0f°", [temperature celsius]];
        if ([temperature respondsToSelector:@selector(doubleValue)]) return [NSString stringWithFormat:@"%.0f°", [temperature doubleValue]];
        if ([temperature isKindOfClass:NSString.class]) return [NSString stringWithFormat:@"%.0f°", [temperature doubleValue]];
    } @catch (NSException *exception) {}
    return @"--°";
}
- (NSString *)highLowTemperatureString {
    NSString *high = @"--", *low = @"--";
    @try {
        id day = [[_currentCity dayForecasts] firstObject];
        if ([day high]) high = [self temperatureString:[day high]];
        if ([day low]) low = [self temperatureString:[day low]];
    } @catch (NSException *exception) {}
    return [NSString stringWithFormat:@"%@ / %@", high, low];
}
- (NSString *)conditionStringForCode:(NSInteger)code {
    @try {
        NSString *(*function)(NSInteger) = (void *)dlsym(RTLD_DEFAULT, "WAConditionsLineStringFromConditionCode");
        NSString *result = function ? function(code) : nil;
        if (result.length) return result;
    } @catch (NSException *exception) {}
    return [self localizedConditionForCode:code];
}
- (NSString *)systemSymbolForConditionCode:(NSInteger)code {
    @try {
        NSString *(*function)(NSInteger) = (void *)dlsym(RTLD_DEFAULT, "WASymbolGlyphFromConditionCode");
        NSString *result = function ? function(code) : nil;
        if (result.length) return result;
    } @catch (NSException *exception) {}
    return [self sfSymbolForConditionCode:code];
}
- (UIImage *)systemWeatherImageForConditionCode:(NSInteger)code {
    @try {
        NSString *name = [self imageNameForConditionCode:code];
        UIImage *image = [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil];
        if (image) return image;
        return [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/WeatherUI.framework"] compatibleWithTraitCollection:nil];
    } @catch (NSException *exception) { return nil; }
}
- (void)updateWeatherIcon {
    self.customMedia.hidden = ![WCCPrefs() boolForKey:@"customIcon"];
    if (!self.customMedia.hidden && self.customMedia.hasMedia) { _iconView.image = nil; return; }
    NSInteger code = [_currentCity conditionCode];
    if ([_currentCity temperature]) {
        UIImage *image = [self systemWeatherImageForConditionCode:code];
        _iconView.image = image ?: [UIImage systemImageNamed:[self systemSymbolForConditionCode:code] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:42 weight:UIImageSymbolWeightRegular]];
    } else {
        _iconView.image = [UIImage systemImageNamed:@"cloud.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:42 weight:UIImageSymbolWeightRegular]];
    }
}
- (void)updateHourlyForecast {
    @try {
        for (UIView *view in _hourlyScrollView.subviews) [view removeFromSuperview];
        NSArray *hours = [_currentCity hourlyForecasts];
        if (!hours.count) return;
        NSDateFormatter *formatter = [NSDateFormatter new]; formatter.locale = NSLocale.currentLocale;
        NSUInteger count = MIN(hours.count, 12);
        for (NSUInteger i = 0; i < count; i++) {
            UIView *item = [self createHourlyItemWithForecast:hours[i] isNow:i == 0 formatter:formatter];
            item.frame = CGRectMake(12 + i * 55, 0, 55, 80); [_hourlyScrollView addSubview:item];
        }
        _hourlyScrollView.contentSize = CGSizeMake(24 + count * 55, 80);
    } @catch (NSException *exception) {}
}
- (UIView *)createHourlyItemWithForecast:(id)forecast isNow:(BOOL)isNow formatter:(NSDateFormatter *)formatter {
    UIView *item = [UIView new];
    UILabel *time = WCCLabel(13, UIFontWeightMedium, 1); time.textAlignment = NSTextAlignmentCenter;
    @try {
        if (isNow) time.text = @"现在";
        else if ([forecast time]) time.text = [forecast time];
        else if ([forecast date]) { formatter.dateFormat = @"ah时"; time.text = [formatter stringFromDate:[forecast date]]; }
        else time.text = @"--";
    } @catch (NSException *exception) { time.text = @"--"; }
    time.frame = CGRectMake(0, 0, 55, 18); [item addSubview:time];
    UIImageView *icon = [UIImageView new]; icon.contentMode = UIViewContentModeScaleAspectFit; icon.tintColor = UIColor.whiteColor;
    @try {
        NSInteger code = [forecast conditionCode];
        icon.image = [self systemWeatherImageForConditionCode:code] ?: [UIImage systemImageNamed:[self systemSymbolForConditionCode:code] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular]];
    } @catch (NSException *exception) {}
    icon.frame = CGRectMake(12, 22, 30, 30); [item addSubview:icon];
    UILabel *temperature = WCCLabel(15, UIFontWeightMedium, 1); temperature.textAlignment = NSTextAlignmentCenter;
    @try { temperature.text = [self temperatureString:[forecast temperature]]; }
    @catch (NSException *exception) { temperature.text = @"--"; }
    temperature.frame = CGRectMake(0, 56, 55, 20); [item addSubview:temperature];
    return item;
}
@end
