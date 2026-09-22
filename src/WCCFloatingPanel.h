#import <UIKit/UIKit.h>
@interface WCCFloatingPanel : UIViewController
+ (BOOL)isOpenFor:(UIViewController *)owner;
+ (void)openFor:(UIViewController *)owner root:(UIViewController *)root completion:(void (^)(void))completion;
+ (void)closeFor:(UIViewController *)owner;
@end
void WCCPanelStyleCell(UITableViewCell *cell);
void WCCPanelStyleSection(UIView *view);
BOOL WCCPanelTransparent(void);

@interface WCCNativeSettingsNavigation : UINavigationController
@end
