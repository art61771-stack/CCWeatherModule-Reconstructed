#import "WCCContentViewController.h"
#import <dlfcn.h>
#import "WCCPreferences.h"
#import "WCCSettings.h"
#import "WCCMedia.h"
#import "WCCRuntime.h"
#import "WCCHostObserver.h"
#import "WCCHourly.h"
#import "WCCABI.h"
#import "WCCWeatherSource.h"
#import <objc/runtime.h>
#import <objc/message.h>
#include <stdbool.h>
// Hourly replacements use the exact original bundled-image resolver below.
// No additional forecast getter (or device-clock daylight guess) gates mapping.
@interface WCCHourlyItem : UIView
@property(nonatomic,strong) UIImageView *originalIcon;
@property(nonatomic,strong) UILabel *timeLabel;
@property(nonatomic,strong) UILabel *temperatureLabel;
@property(nonatomic,strong) WCCMediaView *media;
@property(nonatomic,copy) NSString *assetKey;
@property(nonatomic,copy) NSString *cachedPath;
@property(nonatomic,copy) NSString *cachedIdentity;
@property(nonatomic,copy) NSString *boundIdentity;
@property(nonatomic) BOOL animatedAsset;
@end
@implementation WCCHourlyItem
@end
static CGRect WCCCGRect(WCCRect r) { return CGRectMake(r.x,r.y,r.w,r.h); }
static CGFloat WCCTextWidth(UILabel *label, CGFloat size, UIFontWeight weight) {
    return ceil([(label.text ?: @"") sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:MAX(1,size) weight:weight]}].width);
}
@interface WCCContentViewController () <UIScrollViewDelegate>
@property(nonatomic,strong) NSMutableArray<WCCHourlyItem *> *hourlyItems;
@property(nonatomic) NSUInteger hourlyLayoutGeneration;
@property(nonatomic) BOOL hourlyRefreshing;
@property(nonatomic,copy) NSDictionary *caiyunRender;
@property(nonatomic) NSUInteger sourceGeneration;
- (void)weatherSourceChanged;
- (void)bindCaiyunSnapshot;
- (UIImage *)caiyunImage:(NSDictionary *)condition;
- (void)stopSystemWeather;
- (void)scheduleHourlyLayoutValidation;
- (void)layoutMainCustomMedia;
- (void)mainIconScaleChanged;
- (void)resetRegionTransforms;
- (void)applyRegionPositions;
- (void)regionPositionChanged;
- (void)applyTextShadows;
- (void)refreshHourlyMedia;
- (void)cacheHourlyMediaPaths;
- (void)clearHourlyItems;
@property(nonatomic,strong) UILabel *greetingLabel;
@property(nonatomic) WCCModuleSession moduleSession;
@property(nonatomic,strong) NSArray *originalExpandedConstraints;
@property(nonatomic) WCCGreetingState greetingState;
@property(nonatomic) BOOL customGreetingWasEnabled;
@property(nonatomic) WCCLayoutSize layoutSize;
@property(nonatomic,strong) WCCMediaView *customMedia;
@property(nonatomic) BOOL mediaVisible;
@property(nonatomic) BOOL mediaSuspended;
@property(nonatomic,copy) NSString *mediaAssetKey;
@end
// Auto Layout can resolve scroll bounds after the controller's layout callback.
// Observe the actual scroll view, not just its parent controller.
@interface WCCHourlyScrollView : UIScrollView
@property(nonatomic,copy) void (^geometryReady)(void);
@end
@implementation WCCHourlyScrollView
- (void)layoutSubviews { [super layoutSubviews]; if (self.geometryReady) self.geometryReady(); }
- (void)didMoveToWindow { [super didMoveToWindow]; if (self.geometryReady) self.geometryReady(); }
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
        _layoutSize = WCCEffectiveSize();
        _customLocationName = nil;
        if (!WCCWeatherSource.shared.caiyun) [self initializeWeatherModel];
        // UI remains available when Apple's private Weather framework is absent.
        _isInitialized = YES;
        _sourceGeneration=WCCWeatherSource.shared.generation;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(weatherSourceChanged) name:WCCWeatherSourceChanged object:nil];
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
    WCCModuleSession session=self.moduleSession;
    if (WCCConsumeExpansion(&session,expanded)) [self drawGreeting];
    self.moduleSession=session;
    _isExpanded = expanded;
    if (expanded) [self updateHourlyForecast]; else [self clearHourlyItems];
    _hourlyContainer.alpha = expanded ? 1 : 0;
    [self.view setNeedsLayout];
}
- (void)didTransitionToExpandedContentMode:(BOOL)expanded {
    _isExpanded = expanded;
    if (expanded) { [self.view layoutIfNeeded]; [self refreshHourlyMedia]; [self scheduleHourlyLayoutValidation]; }
    else { ++self.hourlyLayoutGeneration; [self refreshHourlyMedia]; }
}
- (void)scheduleHourlyLayoutValidation {
    NSUInteger generation=++self.hourlyLayoutGeneration;
    __weak typeof(self) weak=self;
    // One event-driven next-turn check, never a retry loop or delayed timer.
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) self=weak;
        if (!self || generation!=self.hourlyLayoutGeneration || !self->_isExpanded) return;
        [self.view layoutIfNeeded]; [self->_hourlyContainer layoutIfNeeded];
        [self refreshHourlyMedia];
    });
}
- (void)willBecomeActive {  [self consumeHostSession]; self.mediaVisible=YES; [self preferencesChanged]; [self refreshWeatherData]; }
- (void)consumeHostSession {
    WCCObserveHostForModule(self);
    WCCModuleSession session=self.moduleSession;
    if (WCCConsumeModuleHost(&session,WCCCurrentHostState())) {
        self.moduleSession=session; [self drawGreeting];
    }
}
- (void)hostVisibilityChanged:(NSNotification *)note {
    [self consumeHostSession];
    self.mediaVisible=WCCCurrentHostState().visible;
    if(!self.mediaVisible) [WCCWeatherSource.shared cancel];
    self.customMedia.active=self.mediaVisible && !self.presentedViewController;
    [self refreshHourlyMedia];
}
- (void)drawGreeting {
    if(WCCCustomGreetingEnabled()){[self bindGreetingText];return;}
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = NSTimeZone.localTimeZone;
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:NSDate.date];
    WCCGreetingState state=self.greetingState;
    WCCPresentGreeting(&state,(int)hour,arc4random_uniform(840)); self.greetingState=state;
    [self bindGreetingText];
}
- (void)bindGreetingText {
    if(WCCCustomGreetingEnabled()) {
        self.customGreetingWasEnabled=YES;
        self.greetingLabel.text=WCCCustomGreetingText();
        self.greetingLabel.hidden=NO;self.greetingLabel.alpha=1;return;
    }
    if(self.customGreetingWasEnabled) {
        self.customGreetingWasEnabled=NO;
        [self drawGreeting];return;
    }
    int index=self.greetingState.index;
    // Always bind, including a session that began before UILabel creation.
    self.greetingLabel.text=[NSString stringWithFormat:@"%@，%@",[NSString stringWithUTF8String:WCCGreetingPrefix(index)],[NSString stringWithUTF8String:WCCGreetingSuffix(index)]];
    self.greetingLabel.hidden=NO; self.greetingLabel.alpha=1;
}
- (void)endGreetingSession { WCCGreetingState state=self.greetingState; WCCEndGreeting(&state); self.greetingState=state; }
- (void)loadView {
    WCCVisibilityView *view=[WCCVisibilityView new]; __weak typeof(self) weak=self;
    view.visibilityChanged=^(BOOL visible) {
        typeof(self) self=weak; if (!self) return;
        if (visible) { [self consumeHostSession]; self.mediaVisible=YES; [self preferencesChanged]; }
        else if (!self.presentedViewController) {  self.mediaVisible=NO; self.customMedia.active=NO; [self refreshHourlyMedia]; }
    }; self.view=view;
}
- (void)controlCenterWillPresent {
    // Module callback is NOT a whole-Control-Center presentation edge.
    [self consumeHostSession]; self.mediaVisible=YES; [self preferencesChanged]; [self refreshWeatherData];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(hostVisibilityChanged:) name:WCCHostVisibilityChanged object:self];
    [self consumeHostSession];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(preferencesChanged) name:WCCPreferencesChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(regionPositionChanged) name:WCCRegionPositionChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(mainIconScaleChanged) name:WCCMainIconScaleChanged object:nil];
    self.view.backgroundColor = UIColor.clearColor;
    [self setupHeaderView]; [self setupHourlyContainer];
    [self preferencesChanged]; [self updateWeatherDisplay]; [self forceCityUpdate];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self refreshWeatherData]; });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self refreshWeatherData]; });
}
- (void)forceCityUpdate {
    if (WCCWeatherSource.shared.caiyun) return;
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
    [self resetRegionTransforms];
    CGSize size = self.view.bounds.size;
    WCCGeometry g = WCCComputeModuleGeometry(size.width, size.height, _isExpanded, (int)self.layoutSize.width, (int)self.layoutSize.height);
    if (_isExpanded) {
        [self layoutOriginalExpanded:size]; return;
    }
    if (self.layoutSize.width==3 && self.layoutSize.height==1) {
        [self bindGreetingText];
        g=WCCBalanceMeasuredStrip(g,size.width,size.height,
            WCCTextWidth(_tempLabel,g.tempFont,UIFontWeightLight),
            WCCTextWidth(_highLowLabel,g.detailFont,UIFontWeightRegular),
            WCCTextWidth(_cityLabel,g.cityFont,UIFontWeightSemibold),
            WCCTextWidth(_conditionLabel,g.detailFont,UIFontWeightRegular),
            WCCTextWidth(_precipLabel,g.detailFont,UIFontWeightRegular),
            WCCTextWidth(self.greetingLabel,g.greetingFont,UIFontWeightRegular));
    }
    [NSLayoutConstraint deactivateConstraints:self.originalExpandedConstraints ?: @[]];
    for (UIView *v in @[_iconView,_cityLabel,_conditionLabel,_precipLabel,_tempLabel,_highLowLabel]) v.translatesAutoresizingMaskIntoConstraints=YES;
    BOOL rightAligned = !_isExpanded && self.layoutSize.width!=3 && self.layoutSize.width>=2 && self.layoutSize.width<=4 && self.layoutSize.height==1;
    _cityLabel.textAlignment = _conditionLabel.textAlignment = _precipLabel.textAlignment = self.greetingLabel.textAlignment = rightAligned ? NSTextAlignmentRight : NSTextAlignmentLeft;
    _headerView.clipsToBounds=YES;
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
    self.greetingLabel.adjustsFontSizeToFitWidth=YES;
    self.greetingLabel.font = [UIFont systemFontOfSize:MAX(1,g.greetingFont) weight:UIFontWeightRegular];
    _tempLabel.textAlignment = NSTextAlignmentLeft;
    _highLowLabel.textAlignment = NSTextAlignmentLeft;
    self.greetingLabel.hidden=NO; self.greetingLabel.alpha=1;
    [_headerView bringSubviewToFront:self.greetingLabel];
    [self bindGreetingText]; // Layout must never draw a new suffix.
    _hourlyContainer.frame = CGRectMake(0, g.headerHeight, size.width, MAX(0,size.height-g.headerHeight));
    _hourlyContainer.hidden = !_isExpanded;
}
- (void)layoutOriginalExpanded:(CGSize)size {
    _headerView.clipsToBounds=NO;
    _headerView.transform=CGAffineTransformIdentity;
    _headerView.frame=CGRectMake(0,0,size.width,85);
    _hourlyContainer.frame=CGRectMake(0,85,size.width,size.height-85);
    _hourlyContainer.hidden=NO;
    self.greetingLabel.hidden=NO;
    self.greetingLabel.alpha=1;
    self.greetingLabel.font=[UIFont systemFontOfSize:8 weight:UIFontWeightRegular];
    self.greetingLabel.adjustsFontSizeToFitWidth=NO;
    self.greetingLabel.textAlignment=NSTextAlignmentLeft;
    self.greetingLabel.lineBreakMode=NSLineBreakByTruncatingTail;
    _precipLabel.hidden=_highLowLabel.hidden=NO;
    _iconView.transform=CGAffineTransformIdentity;
    _cityLabel.font=[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _conditionLabel.font=_highLowLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    _precipLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _tempLabel.font=[UIFont systemFontOfSize:38 weight:UIFontWeightLight];
    _cityLabel.textAlignment=_conditionLabel.textAlignment=_precipLabel.textAlignment=NSTextAlignmentLeft;
    _tempLabel.textAlignment=_highLowLabel.textAlignment=NSTextAlignmentRight;
    for (UIView *v in @[_iconView,_cityLabel,_conditionLabel,_precipLabel,_tempLabel,_highLowLabel]) v.translatesAutoresizingMaskIntoConstraints=NO;
    if (!self.originalExpandedConstraints) {
    self.originalExpandedConstraints=@[
        [_iconView.leadingAnchor constraintEqualToAnchor:_headerView.leadingAnchor constant:16],
        [_iconView.centerYAnchor constraintEqualToAnchor:_headerView.centerYAnchor],
        [_iconView.widthAnchor constraintEqualToConstant:55],
        [_iconView.heightAnchor constraintEqualToConstant:55],
        [_cityLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:18],
        [_cityLabel.topAnchor constraintEqualToAnchor:_headerView.topAnchor constant:12],
        [_conditionLabel.leadingAnchor constraintEqualToAnchor:_cityLabel.leadingAnchor],
        [_conditionLabel.topAnchor constraintEqualToAnchor:_cityLabel.bottomAnchor constant:2],
        [_precipLabel.leadingAnchor constraintEqualToAnchor:_cityLabel.leadingAnchor],
        [_precipLabel.topAnchor constraintEqualToAnchor:_conditionLabel.bottomAnchor constant:2],
        [_tempLabel.trailingAnchor constraintEqualToAnchor:_headerView.trailingAnchor constant:-16],
        [_tempLabel.topAnchor constraintEqualToAnchor:_headerView.topAnchor constant:10],
        [_highLowLabel.trailingAnchor constraintEqualToAnchor:_tempLabel.trailingAnchor],
        [_highLowLabel.topAnchor constraintEqualToAnchor:_tempLabel.bottomAnchor constant:0]
    ];
    }
    [NSLayoutConstraint activateConstraints:self.originalExpandedConstraints];
    [_headerView layoutIfNeeded];
    WCCRect occupied[6]; int n=0;
    for (UIView *v in @[_iconView,_cityLabel,_conditionLabel,_precipLabel,_tempLabel,_highLowLabel]) {
        CGRect r=v.frame; occupied[n++]=WCCR(r.origin.x,r.origin.y,r.size.width,r.size.height);
    }
    self.greetingLabel.frame=WCCCGRect(WCCExpandedGreeting(size.width,occupied,n));
    [self bindGreetingText];
    self.customMedia.frame=_iconView.bounds;
}
- (void)refreshWeatherData {
    if (WCCWeatherSource.shared.caiyun) { if(self.mediaVisible) [WCCWeatherSource.shared refreshManual:NO]; return; }
    if (!_weatherModel) [self initializeWeatherModel];
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
    [self bindGreetingText];
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
    self.customMedia.mediaChanged = ^{ [weak renderWeatherIcon]; };
}
- (void)setupHourlyContainer {
    _hourlyContainer = [UIView new]; _hourlyContainer.backgroundColor = UIColor.clearColor;
    _hourlyContainer.alpha = 0; [self.view addSubview:_hourlyContainer];
    _dividerLine = [UIView new]; _dividerLine.backgroundColor = [UIColor colorWithWhite:1 alpha:.3];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO; [_hourlyContainer addSubview:_dividerLine];
    WCCHourlyScrollView *scroll=[WCCHourlyScrollView new];
    __weak typeof(self) weak=self;
    scroll.geometryReady=^{ [weak refreshHourlyMedia]; };
    _hourlyScrollView = scroll; _hourlyScrollView.showsHorizontalScrollIndicator = NO;
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
    self.mediaSuspended=YES; self.customMedia.active = NO; [self refreshHourlyMedia];
    __weak typeof(self) weak = self;
    [WCCSettings presentFrom:self completion:^{ weak.mediaSuspended=NO; [weak preferencesChanged]; }];
}
- (void)showCustomNameAlert {
    if (self.presentedViewController) return;
    self.mediaSuspended=YES; self.customMedia.active = NO; [self refreshHourlyMedia];
    __weak typeof(self) weak = self;
    [WCCSettings editLandmarkFrom:self completion:^{ weak.mediaSuspended=NO; [weak preferencesChanged]; }];
}
- (void)preferencesChanged {
    _displayMode = MAX(0, MIN(2, [WCCPrefs() integerForKey:@"displayMode"]));
    _customLocationName = [WCCPrefs() stringForKey:@"landmark"];
    if (_displayMode == 2 && !_customLocationName.length) _displayMode = 0;
    [self updateCityLabel]; [self updateWeatherIcon]; [self cacheHourlyMediaPaths]; [self refreshHourlyMedia];
    self.customMedia.active = self.mediaVisible && !self.presentedViewController;
}
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; [self consumeHostSession]; self.mediaVisible = YES; [self preferencesChanged]; }
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated]; self.mediaVisible = NO; self.customMedia.active = NO; [self refreshHourlyMedia]; }
- (void)viewDidDisappear:(BOOL)animated { [super viewDidDisappear:animated]; }
- (void)controlCenterDidDismiss { [WCCWeatherSource.shared cancel]; self.mediaVisible = NO; self.customMedia.active = NO; [self refreshHourlyMedia]; }
- (void)willResignActive { if (!self.presentedViewController)  self.mediaVisible = NO; self.customMedia.active = NO; [self refreshHourlyMedia]; }
- (void)stopSystemWeather {
    @try {
        [_weatherModel removeObserver:self];
        for (NSString *name in @[@"setIsLocationTrackingEnabled:",@"setLocationServicesActive:"]) {
            SEL sel=NSSelectorFromString(name);
            if ([_weatherModel respondsToSelector:sel]) ((void (*)(id,SEL,id))objc_msgSend)(_weatherModel,sel,@NO);
        }
    } @catch(NSException *e) {}
    _weatherModel=nil; _lockscreenController=nil; _currentCity=nil;
}
- (void)weatherSourceChanged {
    WCCWeatherSource *s=WCCWeatherSource.shared;
    if(self.sourceGeneration!=s.generation) {
        self.sourceGeneration=s.generation;
        [self clearHourlyItems]; [self.customMedia loadPath:nil]; self.mediaAssetKey=nil;
        self.caiyunRender=nil; _currentCity=nil; _cachedSubLocality=nil; _cachedLocationID=nil;
        _cityLabel.text=@"未就绪"; _conditionLabel.text=@"未就绪"; _tempLabel.text=@"--°";
        _highLowLabel.text=@"-- / --"; _precipLabel.text=@"降水概率: --";
        if(s.caiyun) [self stopSystemWeather];
        else if(!_weatherModel) [self initializeWeatherModel];
    }
    if(self.isViewLoaded) [self updateWeatherDisplay];
}
- (UIImage *)caiyunImage:(NSDictionary *)condition {
    NSString *key=condition[@"basename"];
    UIImage *image=key.length?[UIImage imageNamed:key inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]:nil;
    return image ?: [UIImage systemImageNamed:condition[@"symbol"]?:@"cloud.fill"] ?: [UIImage systemImageNamed:@"cloud.fill"];
}
- (void)bindCaiyunSnapshot {
    WCCWeatherSource *s=WCCWeatherSource.shared;
    self.caiyunRender=WCCRenderCaiyunSnapshot(s.snapshot,[WCCPrefs() stringForKey:@"caiyunAlias"],s.stale);
    NSDictionary *r=self.caiyunRender;
    _cityLabel.text=r[@"city"]; _tempLabel.text=r[@"temperature"]; _highLowLabel.text=r[@"highLow"];
    _precipLabel.text=r[@"precipitation"];
    _conditionLabel.text=![r[@"ready"] boolValue]?@"未就绪": [NSString stringWithFormat:@"%@%@",r[@"condition"][@"text"],s.stale?@" · 已过期":@""];
    [self updateWeatherIcon]; if(_isExpanded)[self updateHourlyForecast];
}
- (void)updateWeatherDisplay {
    if(WCCWeatherSource.shared.caiyun) { [self bindCaiyunSnapshot]; return; }
    if (!_weatherModel) {
        _cityLabel.text=@"系统天气未就绪"; _conditionLabel.text=@"未就绪"; _tempLabel.text=@"--°";
        _highLowLabel.text=@"-- / --"; _precipLabel.text=@"降水概率: --"; [self updateWeatherIcon]; return;
    }
    @try {
        _currentCity = [[_weatherModel forecastModel] city];
        if (!_currentCity) { [self updateWeatherIcon]; return; }
        [self updateWeatherIcon];
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
            [self updateWeatherIcon];
        }
    } @catch (NSException *exception) {}
}
- (void)updateCityLabel {
    if(WCCWeatherSource.shared.caiyun) { _cityLabel.text=self.caiyunRender[@"city"]?:@"彩云地点"; return; }
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
            NSUInteger sourceGeneration=self.sourceGeneration;
            CLGeocoder *geocoder = [CLGeocoder new];
            [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> *places, NSError *error) {
                if (error || !places.count || WCCWeatherSource.shared.caiyun || sourceGeneration!=self.sourceGeneration) return;
                CLPlacemark *place = places[0];
                NSString *name = place.subLocality;
                if (!name.length) name = place.subAdministrativeArea;
                if (!name.length) return;
                self->_cachedSubLocality = name; self->_cachedLocationID = locationID;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!WCCWeatherSource.shared.caiyun && sourceGeneration==self.sourceGeneration && self->_displayMode == 0) self->_cityLabel.text = name;
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
    return [self systemWeatherImageForConditionCode:code selectedAssetKey:NULL];
}
// Single production selection point for native image AND its replacement key.
// Preserve original104 resolver semantics, including its current-city day/night
// choice for ambiguous templates; this is resource parity, not a claim of a
// newly determined future-hour astronomical daylight value.
- (UIImage *)systemWeatherImageForConditionCode:(NSInteger)code selectedAssetKey:(NSString * __autoreleasing *)selectedKey {
    if (selectedKey) *selectedKey=nil;
    @try {
        NSString *name = [self imageNameForConditionCode:code];
        if (selectedKey && code>=0 && code<48) *selectedKey=name;
        UIImage *image = [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil];
        if (image) return image;
        return [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/WeatherUI.framework"] compatibleWithTraitCollection:nil];
    } @catch (NSException *exception) { return nil; }
}
- (void)updateWeatherIcon {
    NSString *key = WCCWeatherSource.shared.caiyun ? self.caiyunRender[@"condition"][@"basename"] : (_currentCity ? [self imageNameForConditionCode:[_currentCity conditionCode]] : nil);
    if(!key.length) key=nil;
    if (![self.mediaAssetKey isEqual:key]) {
        [self.customMedia loadPath:nil]; self.mediaAssetKey=key;
    }
    NSString *path = [WCCPrefs() boolForKey:@"customIcon"] ? WCCSafePath(WCCRoot(), WCCMappedName(key)) : nil;
    [self.customMedia loadPath:path];
    self.customMedia.active = self.mediaVisible && !self.presentedViewController && path != nil;
    [self renderWeatherIcon];
}
- (void)renderWeatherIcon {
    [self layoutMainCustomMedia];
    self.customMedia.hidden = ![WCCPrefs() boolForKey:@"customIcon"];
    if (!self.customMedia.hidden && self.customMedia.hasMedia) { _iconView.image = nil; return; }
    if(WCCWeatherSource.shared.caiyun) { _iconView.image=[self caiyunImage:self.caiyunRender[@"condition"]]; return; }
    NSInteger code = [_currentCity conditionCode];
    if ([_currentCity temperature]) {
        UIImage *image = [self systemWeatherImageForConditionCode:code];
        _iconView.image = image ?: [UIImage systemImageNamed:[self systemSymbolForConditionCode:code] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:42 weight:UIImageSymbolWeightRegular]];
    } else {
        _iconView.image = [UIImage systemImageNamed:@"cloud.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:42 weight:UIImageSymbolWeightRegular]];
    }
}
- (void)clearHourlyItems {
    ++self.hourlyLayoutGeneration;
    for (WCCHourlyItem *item in self.hourlyItems) {
        item.media.active=NO; [item.media loadPath:nil]; [item removeFromSuperview];
    }
    [self.hourlyItems removeAllObjects]; _hourlyScrollView.contentSize=CGSizeZero;
}
- (void)cacheHourlyMediaPaths {
    // Only configuration/forecast events touch the filesystem. Cache missing
    // mappings too; layout and scrolling never resolve names or stat files.
    BOOL enabled=[WCCPrefs() boolForKey:@"customIcon"];
    NSMutableDictionary *resolved=[NSMutableDictionary dictionary];
    for (WCCHourlyItem *item in self.hourlyItems) {
        NSString *key=item.assetKey ?: @"";
        NSArray *binding=resolved[key];
        if (!binding) {
            NSString *path=enabled && key.length ? WCCSafePath(WCCRoot(),WCCMappedName(key)) : nil;
            struct stat st; NSString *identity=nil;
            if (path && stat(path.fileSystemRepresentation,&st)==0 && S_ISREG(st.st_mode))
                identity=[NSString stringWithFormat:@"%@:%llu:%llu:%lld:%lld:%ld:%lld:%ld",path,(unsigned long long)st.st_dev,(unsigned long long)st.st_ino,(long long)st.st_size,(long long)st.st_mtimespec.tv_sec,st.st_mtimespec.tv_nsec,(long long)st.st_ctimespec.tv_sec,st.st_ctimespec.tv_nsec];
            binding=@[identity ? path : @"",identity ?: @""];
            resolved[key]=binding;
        }
        item.cachedPath=[binding[0] length] ? binding[0] : nil;
        item.cachedIdentity=[binding[1] length] ? binding[1] : nil;
        NSString *extension=item.cachedPath.pathExtension.lowercaseString;
        item.animatedAsset=[extension isEqual:@"gif"] || [extension isEqual:@"mp4"];
    }
}
- (void)refreshHourlyMedia {
    if (self.hourlyRefreshing) return;
    self.hourlyRefreshing=YES;
    BOOL available=WCCHourlyLayoutReady(_isExpanded,self.mediaVisible,self.mediaSuspended,
        self.view.window!=nil,_hourlyScrollView.window!=nil,self.presentedViewController!=nil,
        _hourlyScrollView.bounds.size.width,_hourlyScrollView.bounds.size.height);
    // Release obsolete/offscreen bindings first, then admit EVERY visible item.
    // Preparation is serialized in WCCMedia; playback has no three-item quota.
    NSMutableArray<WCCHourlyItem *> *admitted=[NSMutableArray array];
    for (WCCHourlyItem *item in self.hourlyItems) {
        BOOL visible=available && WCCHourlyIntersects(item.frame.origin.x,item.frame.size.width,_hourlyScrollView.contentOffset.x,_hourlyScrollView.bounds.size.width);
        BOOL wanted=WCCHourlyAdmit(visible,item.cachedPath!=nil);
        NSString *identity=wanted ? item.cachedIdentity : nil;
        if (item.boundIdentity && ![item.boundIdentity isEqual:identity]) {
            item.media.active=NO; [item.media loadPath:nil]; item.boundIdentity=nil;
        }
        if (wanted) [admitted addObject:item];
    }
    for (WCCHourlyItem *item in admitted) {
        if (!item.boundIdentity) {
            item.boundIdentity=item.cachedIdentity;
            [item.media loadPath:item.cachedPath];
        }
        item.media.active=YES;
    }
    self.hourlyRefreshing=NO;
}
// These methods never query weather, draw greetings, bind/load media or touch hours.
- (NSArray<NSArray<UIView *> *> *)positionRegions {
    return @[@[_tempLabel,_highLowLabel],@[_iconView],
             @[_cityLabel,_conditionLabel,_precipLabel],@[self.greetingLabel]];
}
- (void)resetRegionTransforms {
    for (NSArray<UIView *> *group in [self positionRegions])
        for (UIView *view in group) view.transform=CGAffineTransformIdentity;
}
- (void)applyRegionPositions {
    [self resetRegionTransforms];
    // Position preferences affect only the collapsed main page. Never discard them.
    if (_isExpanded) return;
    NSInteger region=0;
    for (NSArray<UIView *> *group in [self positionRegions]) {
        // Icon uses the same unscaled slot but combines offset and scale once.
        if (region==1) { region++; continue; }
        CGRect baseline=CGRectNull;
        for (UIView *view in group) if (!view.hidden && !CGRectIsEmpty(view.frame))
            baseline=CGRectIsNull(baseline)?view.frame:CGRectUnion(baseline,view.frame);
        if (!CGRectIsNull(baseline)) {
            WCCRect delta=WCCRegionTranslation(WCCR(baseline.origin.x,baseline.origin.y,baseline.size.width,baseline.size.height),
                _headerView.bounds.size.width,_headerView.bounds.size.height,WCCRegionOffset(region*2),WCCRegionOffset(region*2+1));
            for (UIView *view in group) view.transform=CGAffineTransformMakeTranslation(delta.x,delta.y);
        }
        region++;
    }
}
- (void)applyTextShadows {
    // Main header labels only: never style hourly labels or the whole layer.
    NSArray<NSArray<UILabel *> *> *groups=@[@[_tempLabel,_highLowLabel],
        @[_cityLabel,_conditionLabel,_precipLabel],@[self.greetingLabel]];
    NSInteger index=0;
    for (NSArray<UILabel *> *group in groups) {
        BOOL enabled=WCCTextShadowEnabled(index++);
        for (UILabel *label in group) {
            // Dynamic contrast also works if a future host uses dark text.
            UIColor *textColor=label.textColor ?: UIColor.whiteColor;
            UIColor *color=[UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
                CGFloat r=1,g=1,b=1,a=1;
                [[textColor resolvedColorWithTraitCollection:traits] getRed:&r green:&g blue:&b alpha:&a];
                return (r*.2126+g*.7152+b*.0722)>.5 ? [UIColor colorWithWhite:0 alpha:.55] : [UIColor colorWithWhite:1 alpha:.65];
            }];
            label.shadowColor=enabled ? color : nil;
            label.shadowOffset=enabled ? CGSizeMake(0,.5) : CGSizeZero;
        }
    }
}
- (void)regionPositionChanged {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(),^{ [self regionPositionChanged]; }); return; }
    if (!self.isViewLoaded) return;
    [self bindGreetingText];
    [self applyTextShadows];
    [self applyRegionPositions];
    [self layoutMainCustomMedia];
}
- (void)mainIconScaleChanged {
    // Scale-only notifications never recache bindings or restart hourly media.
    [self layoutMainCustomMedia];
}
- (void)layoutMainCustomMedia {
    if (!self.isViewLoaded || !_iconView) return;
    // Never read a scaled frame as baseline, or resize an Auto Layout slot.
    // Identity recovers the original 118 center/bounds in both display modes.
    _iconView.transform=CGAffineTransformIdentity;
    CGRect slot=_iconView.frame;
    WCCRect target=WCCMainIconTarget(WCCR(slot.origin.x,slot.origin.y,slot.size.width,slot.size.height),
        _headerView.bounds.size.width,_headerView.bounds.size.height,_isExpanded,
        WCCRegionOffset(2),WCCRegionOffset(3),WCCMainIconPercentForMode(_isExpanded));
    CGFloat sx=slot.size.width>0?target.w/slot.size.width:1;
    CGFloat sy=slot.size.height>0?target.h/slot.size.height:1;
    self.customMedia.transform=CGAffineTransformIdentity;
    self.customMedia.autoresizingMask=UIViewAutoresizingNone;
    self.customMedia.frame=_iconView.bounds;
    // Native image, PNG/GIF/MP4 and failed-media fallback share this transform.
    _iconView.transform=CGAffineTransformMake(sx,0,0,sy,
        target.x+target.w/2-CGRectGetMidX(slot),target.y+target.h/2-CGRectGetMidY(slot));
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Auto Layout has resolved original expanded constraints before translation.
    [self bindGreetingText];
    [self applyTextShadows];
    [self applyRegionPositions];
    [self layoutMainCustomMedia];
    if (_isExpanded) [self refreshHourlyMedia];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView==_hourlyScrollView) [self refreshHourlyMedia];
}
- (void)updateHourlyForecast {
    if (!_isExpanded) { [self clearHourlyItems]; return; }
    if (!self.hourlyItems) self.hourlyItems=[NSMutableArray array];
    _hourlyScrollView.delegate=self;
    @try {
        NSArray *hours = WCCWeatherSource.shared.caiyun ? self.caiyunRender[@"hours"] : [_currentCity hourlyForecasts];
        if (!hours.count) { [self clearHourlyItems]; return; }
        NSDateFormatter *formatter = [NSDateFormatter new]; formatter.locale = NSLocale.currentLocale;
        NSUInteger count = MIN(hours.count, 12);
        NSArray<WCCHourlyItem *> *previous=[self.hourlyItems copy];
        self.hourlyItems=[NSMutableArray array];
        for (NSUInteger i = 0; i < count; i++) {
            WCCHourlyItem *item=(WCCHourlyItem *)[self createHourlyItemWithForecast:hours[i] isNow:i == 0 formatter:formatter];
            WCCHourlyItem *old=i<previous.count ? previous[i] : nil;
            if (old && ((old.assetKey==nil && item.assetKey==nil) || [old.assetKey isEqual:item.assetKey])) {
                old.timeLabel.text=item.timeLabel.text;
                old.temperatureLabel.text=item.temperatureLabel.text;
                old.originalIcon.image=item.originalIcon.image;
                [self.hourlyItems removeLastObject]; [self.hourlyItems addObject:old]; item=old;
            } else if (old) {
                old.media.active=NO; [old.media loadPath:nil]; [old removeFromSuperview];
            }
            item.frame = CGRectMake(12 + i * 55, 0, 55, 80);
            if (!item.superview) [_hourlyScrollView addSubview:item];
        }
        for (NSUInteger i=count;i<previous.count;i++) {
            WCCHourlyItem *old=previous[i]; old.media.active=NO; [old.media loadPath:nil]; [old removeFromSuperview];
        }
        _hourlyScrollView.contentSize = CGSizeMake(24 + count * 55, 80);
    } @catch (NSException *exception) {}
    [self cacheHourlyMediaPaths];
    [_hourlyContainer layoutIfNeeded]; [self refreshHourlyMedia];
    [self scheduleHourlyLayoutValidation];
}
- (UIView *)createHourlyItemWithForecast:(id)forecast isNow:(BOOL)isNow formatter:(NSDateFormatter *)formatter {
    WCCHourlyItem *item = [WCCHourlyItem new];
    UILabel *time = WCCLabel(13, UIFontWeightMedium, 1); time.textAlignment = NSTextAlignmentCenter;
    @try {
        if (WCCWeatherSource.shared.caiyun) time.text=forecast[@"time"];
        else if (isNow) time.text = @"现在";
        else if ([forecast time]) time.text = [forecast time];
        else if ([forecast date]) { formatter.dateFormat = @"ah时"; time.text = [formatter stringFromDate:[forecast date]]; }
        else time.text = @"--";
    } @catch (NSException *exception) { time.text = @"--"; }
    time.frame = CGRectMake(0, 0, 55, 18); [item addSubview:time];
    UIImageView *icon = [UIImageView new]; icon.contentMode = UIViewContentModeScaleAspectFit; icon.tintColor = UIColor.whiteColor;
    @try {
        if(WCCWeatherSource.shared.caiyun) {
            NSDictionary *condition=forecast[@"condition"];
            item.assetKey=[condition[@"basename"] length]?condition[@"basename"]:nil;
            icon.image=[self caiyunImage:condition];
        } else {
        NSInteger code = [forecast conditionCode];
        NSString *selectedKey=nil;
        UIImage *native=[self systemWeatherImageForConditionCode:code selectedAssetKey:&selectedKey];
        item.assetKey=selectedKey; // record this item's actual original resource, never the main icon's key
        icon.image = native ?: [UIImage systemImageNamed:[self systemSymbolForConditionCode:code] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular]];
        }
    } @catch (NSException *exception) {}
    icon.frame = CGRectMake(12, 22, 30, 30); [item addSubview:icon];
    item.originalIcon=icon;
    item.media=[[WCCMediaView alloc] initWithFrame:icon.frame]; [item addSubview:item.media];
    __weak WCCHourlyItem *weakItem=item;
    item.media.mediaChanged=^{ WCCHourlyItem *current=weakItem; current.originalIcon.hidden=current.media.hasMedia;  };
    item.media.mediaFailed=^(NSString *reason) { WCCHourlyItem *current=weakItem; current.originalIcon.hidden=NO;  };
    [self.hourlyItems addObject:item];
    UILabel *temperature = WCCLabel(15, UIFontWeightMedium, 1); temperature.textAlignment = NSTextAlignmentCenter;
    @try { temperature.text = WCCWeatherSource.shared.caiyun ? forecast[@"temperature"] : [self temperatureString:[forecast temperature]]; }
    @catch (NSException *exception) { temperature.text = @"--"; }
    item.timeLabel=time; item.temperatureLabel=temperature;
    temperature.frame = CGRectMake(0, 56, 55, 20); [item addSubview:temperature];
    return item;
}
@end
