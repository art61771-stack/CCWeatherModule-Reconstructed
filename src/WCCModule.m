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
@implementation WCCModule
- (WCCLayoutSize)moduleSizeForOrientation:(int)orientation {
    // Snapshot BOTH axes until manual respring: never mix new module geometry
    // with the current Control Center layout cache. Respring resets this cache.
    static WCCLayoutSize size;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ size = WCCEffectiveSize(); });
    return size;
}
- (instancetype)init {
    if ((self = [super init])) {
        WCCLoadWeatherFrameworks();
        // Missing system APIs must not prevent the independent Caiyun path or settings UI.
        WCCContentViewController *controller = [WCCContentViewController new];
        if (!controller || !controller.isInitialized) return nil;
        _contentViewController = controller;
    }
    return self;
}
@end
