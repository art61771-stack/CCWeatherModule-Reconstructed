#import <UIKit/UIKit.h>
#import "WCCSession.h"
FOUNDATION_EXPORT NSString *const WCCHostVisibilityChanged;
FOUNDATION_EXPORT WCCHostState WCCCurrentHostState(void);
/* Main-thread only. No UIViewController-wide hook, timers or KVO assumptions. */
FOUNDATION_EXPORT void WCCObserveHostForModule(UIViewController *module);
