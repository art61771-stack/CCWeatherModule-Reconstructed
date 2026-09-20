#import <UIKit/UIKit.h>
#import "WCCSession.h"
FOUNDATION_EXPORT NSString *const WCCHostVisibilityChanged;
FOUNDATION_EXPORT WCCHostState WCCCurrentHostState(void);
/* Main-thread only. No UIViewController-wide hook, timers or KVO assumptions. */
FOUNDATION_EXPORT void WCCObserveHostForModule(UIViewController *module);
// Opt-in, local aggregate diagnostics. No weather, location or input content.
FOUNDATION_EXPORT void WCCDiagnosticCount(NSString *event);
FOUNDATION_EXPORT NSString *WCCDiagnosticExport(void);
