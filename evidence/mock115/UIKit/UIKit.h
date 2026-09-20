#import <Foundation/Foundation.h>
// Test-only stand-in: no UIKit layout or iOS runtime claims.
@interface UIViewController : NSObject
@property(nonatomic,weak) UIViewController *parentViewController;
@end
