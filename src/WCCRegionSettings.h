#import <UIKit/UIKit.h>
@interface WCCRegionSettings : UITableViewController <UIPopoverPresentationControllerDelegate>
@property(nonatomic,copy) void (^onDone)(void);
@end
