#import "WCCModule.h"
#import "WCCContentViewController.h"
#import "WCCPreferences.h"
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
        if (!NSClassFromString(@"WALockscreenWidgetViewController")) return nil;
        WCCContentViewController *controller = [WCCContentViewController new];
        if (!controller || !controller.isInitialized) return nil;
        _contentViewController = controller;
    }
    return self;
}
@end
