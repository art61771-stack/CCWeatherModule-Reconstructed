#import "PrivateInterfaces.h"
@interface WCCModule : NSObject <CCUIContentModule>
@property(nonatomic,readonly,strong) UIViewController *contentViewController;
@end
