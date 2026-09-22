#import <UIKit/UIKit.h>
FOUNDATION_EXPORT UIImage *WCCDecode(NSString *path);
FOUNDATION_EXPORT NSData *WCCPreview(NSString *path);
@interface WCCMediaView : UIView
@property(nonatomic) BOOL active;
@property(nonatomic,readonly) BOOL hasMedia;
@property(nonatomic,copy) void (^mediaChanged)(void);
@property(nonatomic,copy) void (^mediaFailed)(NSString *reason);
- (void)loadPath:(NSString *)path;
@end
