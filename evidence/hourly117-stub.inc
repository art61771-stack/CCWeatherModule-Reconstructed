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
