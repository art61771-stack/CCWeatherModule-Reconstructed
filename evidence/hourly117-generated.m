#import <Foundation/Foundation.h>
#include <assert.h>
#import "../src/WCCRuntime.h"
#import "../src/WCCHourly.h"
#import <CoreGraphics/CoreGraphics.h>
enum { NSTextAlignmentCenter, UIViewContentModeScaleAspectFit, UIFontWeightMedium, UIImageSymbolWeightRegular };
static NSString *loadedName;
@interface UIView:NSObject
@property CGRect frame;
@property CGRect bounds;
@property BOOL hidden;
@property id window;
-(instancetype)initWithFrame:(CGRect)f;
-(void)addSubview:(id)v;
@end
@implementation UIView
-(instancetype)initWithFrame:(CGRect)f { if((self=[super init]))self.frame=f;return self; }
-(void)addSubview:(id)v {}
@end
@interface UIScrollView:UIView
@property CGPoint contentOffset;
@end
@implementation UIScrollView @end
@interface UILabel:UIView
@property NSString *text;
@property int textAlignment;
@end
@implementation UILabel @end
static UILabel *WCCLabel(double s,int w,double a){return [UILabel new];}
@interface UIColor:NSObject
+(id)whiteColor;
@end
@implementation UIColor
+(id)whiteColor{return nil;}
@end
@interface UIImageSymbolConfiguration:NSObject
+(id)configurationWithPointSize:(double)s weight:(int)w;
@end
@implementation UIImageSymbolConfiguration
+(id)configurationWithPointSize:(double)s weight:(int)w{return nil;}
@end
@interface UIImage:NSObject
+(id)imageNamed:(NSString*)n inBundle:(id)b compatibleWithTraitCollection:(id)c;
+(id)systemImageNamed:(NSString*)n withConfiguration:(id)c;
@end
@implementation UIImage
+(id)imageNamed:(NSString*)n inBundle:(id)b compatibleWithTraitCollection:(id)c{loadedName=n;return [self new];}
+(id)systemImageNamed:(NSString*)n withConfiguration:(id)c{return [self new];}
@end
@interface UIImageView:UIView
@property int contentMode;
@property id tintColor;
@property UIImage *image;
@end
@implementation UIImageView @end
@interface WCCMediaView:UIView
@property BOOL active;
@property BOOL hasMedia;
@property(copy) void(^mediaChanged)(void);
@property(copy) void(^mediaFailed)(NSString*);
@property int loads;
-(void)loadPath:(NSString*)p;
@end
@implementation WCCMediaView
-(void)loadPath:(NSString*)p{self.loads++;self.hasMedia=p!=nil;if(self.mediaChanged)self.mediaChanged();}
@end
@interface WCCHourlyItem:UIView
@property UIImageView *originalIcon;
@property UILabel *timeLabel,*temperatureLabel;
@property WCCMediaView *media;
@property NSString *assetKey,*cachedPath,*cachedIdentity,*boundIdentity;
@end
@implementation WCCHourlyItem @end
@interface City:NSObject
@property BOOL isDay;
@end
@implementation City @end
// Intentionally no isDaylight getter on forecast.
@interface Forecast:NSObject
@property NSInteger conditionCode;
@property NSString *time;
@property NSDate *date;
@property id temperature;
@end
@implementation Forecast @end
static void WCCDiagnosticCount(NSString *s){}
static NSString *WCCAssetKey(NSInteger code,BOOL night){char b[128];WCCAssetBasename((int)code,night,b,sizeof b);return @(b);}
@interface Harness:NSObject {
@public City *_currentCity;
@public BOOL _isExpanded;
@public UIScrollView *_hourlyScrollView;
}
@property NSMutableArray *hourlyItems;
@property BOOL mediaVisible,mediaSuspended;
@property UIView *view;
@property id presentedViewController;
-(UIView*)createHourlyItemWithForecast:(id)f isNow:(BOOL)n formatter:(NSDateFormatter*)fmt;
-(void)refreshHourlyMedia;
@end
@implementation Harness
-(NSString*)temperatureString:(id)t{return @"26°";}
-(NSString*)systemSymbolForConditionCode:(NSInteger)c{return @"cloud.fill";}

- (NSString *)imageNameForConditionCode:(NSInteger)code {
    BOOL night = _currentCity && [_currentCity respondsToSelector:@selector(isDay)] && ![_currentCity isDay];
    return WCCAssetKey(code, night);
}
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
- (UIView *)createHourlyItemWithForecast:(id)forecast isNow:(BOOL)isNow formatter:(NSDateFormatter *)formatter {
    WCCDiagnosticCount(@"hourly.enumerated");
    WCCHourlyItem *item = [WCCHourlyItem new];
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
        NSString *selectedKey=nil;
        UIImage *native=[self systemWeatherImageForConditionCode:code selectedAssetKey:&selectedKey];
        item.assetKey=selectedKey; // record this item's actual original resource, never the main icon's key
        WCCDiagnosticCount(selectedKey ? @"hourly.key.selected" : @"hourly.key.unknownCode");
        icon.image = native ?: [UIImage systemImageNamed:[self systemSymbolForConditionCode:code] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular]];
    } @catch (NSException *exception) {}
    icon.frame = CGRectMake(12, 22, 30, 30); [item addSubview:icon];
    item.originalIcon=icon;
    item.media=[[WCCMediaView alloc] initWithFrame:icon.frame]; [item addSubview:item.media];
    __weak WCCHourlyItem *weakItem=item;
    item.media.mediaChanged=^{ WCCHourlyItem *current=weakItem; current.originalIcon.hidden=current.media.hasMedia; if (current.media.hasMedia) WCCDiagnosticCount(@"hourly.load.success"); };
    item.media.mediaFailed=^(NSString *reason) { WCCHourlyItem *current=weakItem; current.originalIcon.hidden=NO; WCCDiagnosticCount(@"hourly.load.failed"); };
    [self.hourlyItems addObject:item];
    UILabel *temperature = WCCLabel(15, UIFontWeightMedium, 1); temperature.textAlignment = NSTextAlignmentCenter;
    @try { temperature.text = [self temperatureString:[forecast temperature]]; }
    @catch (NSException *exception) { temperature.text = @"--"; }
    item.timeLabel=time; item.temperatureLabel=temperature;
    temperature.frame = CGRectMake(0, 56, 55, 20); [item addSubview:temperature];
    return item;
}
- (void)refreshHourlyMedia {
    BOOL available=_isExpanded && self.mediaVisible && !self.mediaSuspended && self.view.window && !self.presentedViewController;
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
            WCCDiagnosticCount(@"hourly.visible.admitted");
            item.boundIdentity=item.cachedIdentity;
            [item.media loadPath:item.cachedPath]; item.media.active=YES;
        }
    }
}
@end
int main(void){@autoreleasepool{
 Harness *h=[Harness new]; h->_currentCity=[City new];h.hourlyItems=[NSMutableArray array];
 h->_hourlyScrollView=[UIScrollView new];h->_hourlyScrollView.bounds=CGRectMake(0,0,200,80);
 h.view=[UIView new];h.view.window=[NSObject new];h.mediaVisible=YES;h->_isExpanded=YES;
 for(int night=0;night<2;night++)for(int code=0;code<48;code++){
  h->_currentCity.isDay=!night;Forecast*f=[Forecast new];f.conditionCode=code;
  assert(![f respondsToSelector:NSSelectorFromString(@"isDaylight")]);
  WCCHourlyItem*i=(id)[h createHourlyItemWithForecast:f isNow:NO formatter:[NSDateFormatter new]];
  assert([i.assetKey isEqual:loadedName]);assert([i.assetKey isEqual:WCCAssetKey(code,night)]);
  assert(i.originalIcon.image && !i.originalIcon.hidden);
  assert(i.media.frame.origin.x==12 && i.media.frame.origin.y==22 && i.media.frame.size.width==30);
 }
 [h.hourlyItems removeAllObjects];
 for(int code=9;code<15;code++){
  Forecast*f=[Forecast new];f.conditionCode=code;WCCHourlyItem*i=(id)[h createHourlyItemWithForecast:f isNow:YES formatter:[NSDateFormatter new]];
  i.frame=CGRectMake((code-9)*55,0,55,80);i.cachedPath=@"fixture.png";i.cachedIdentity=[NSString stringWithFormat:@"%d",code];
 }
 h->_hourlyScrollView.contentOffset=(CGPoint){54,0};[h refreshHourlyMedia];
 for(int j=0;j<6;j++){WCCHourlyItem*i=h.hourlyItems[j];assert(i.media.active==(j<5));assert(i.originalIcon.hidden==(j<5));}
 [h refreshHourlyMedia];assert(((WCCHourlyItem*)h.hourlyItems[0]).media.loads==1);
 h->_hourlyScrollView.contentOffset=(CGPoint){275,0};[h refreshHourlyMedia];
 assert(!((WCCHourlyItem*)h.hourlyItems[0]).media.active);assert(!((WCCHourlyItem*)h.hourlyItems[0]).originalIcon.hidden);
 h->_hourlyScrollView.contentOffset=(CGPoint){54,0};[h refreshHourlyMedia];
 assert(((WCCHourlyItem*)h.hourlyItems[0]).media.active);
 h.mediaVisible=NO;[h refreshHourlyMedia];for(WCCHourlyItem*i in h.hourlyItems)assert(!i.media.active);
 Forecast*unknown=[Forecast new];unknown.conditionCode=99;WCCHourlyItem*u=(id)[h createHourlyItemWithForecast:unknown isNow:NO formatter:[NSDateFormatter new]];assert(!u.assetKey && u.originalIcon.image);
 puts("PASS exact production ObjC resolver + hourly creation + admission: 96 resource selections, no daylight getter, five partial/full visible static items, reuse, offscreen release/return, parent gate, unknown fallback. UIKit/decoder/iOS16 NOT RUN.");
}return 0;}
