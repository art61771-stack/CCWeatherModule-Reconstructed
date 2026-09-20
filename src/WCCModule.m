#import "WCCModule.h"
#import "WCCContentViewController.h"
#import "WCCPreferences.h"
#import <dlfcn.h>
// Keep handles open for the lifetime of SpringBoard. Missing APIs fail closed.
static void WCCLoadWeatherFrameworks(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dlopen("/System/Library/PrivateFrameworks/Weather.framework/Weather", RTLD_LAZY | RTLD_GLOBAL);
        dlopen("/System/Library/PrivateFrameworks/WeatherUI.framework/WeatherUI", RTLD_LAZY | RTLD_GLOBAL);
    });
}
// CCSupport DynamicSizeModule ABI: two NSUInteger fields, orientation is int.
typedef struct { NSUInteger width; NSUInteger height; } WCCLayoutSize;
@implementation WCCModule
- (WCCLayoutSize)moduleSizeForOrientation:(int)orientation {
    static NSUInteger columns;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSInteger requested = [WCCPrefs() integerForKey:@"columns"];
        columns = [WCCPrefs() boolForKey:@"customSize"] && requested >= 2 && requested <= 4 ? requested : 4;
    });
    return (WCCLayoutSize){columns, 1};
}
- (instancetype)init {
    if ((self = [super init])) {
        WCCLoadWeatherFrameworks();
        if (!NSClassFromString(@"WALockscreenWidgetViewController")) return nil;
        WCCContentViewController *controller = [WCCContentViewController new];
        if (!controller || !controller.isInitialized) return nil;
        _contentViewController = controller;
    }
    return self;
}
@end
