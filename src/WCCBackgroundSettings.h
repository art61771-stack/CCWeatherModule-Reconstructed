#import <UIKit/UIKit.h>
@interface WCCBackgroundSettings : UITableViewController
@property(nonatomic,copy) void (^onDone)(void);
@property(nonatomic,copy) BOOL (^ownerValid)(void);
- (void)cancelPicker;
@end
