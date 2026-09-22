#import <UIKit/UIKit.h>
@interface WCCWeatherSettings : UITableViewController <UIPopoverPresentationControllerDelegate>
@property(nonatomic,copy) void (^onDone)(void);
@end
