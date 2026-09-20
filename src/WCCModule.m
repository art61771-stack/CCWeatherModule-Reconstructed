#import "WCCModule.h"
#import "WCCContentViewController.h"
@implementation WCCModule
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
