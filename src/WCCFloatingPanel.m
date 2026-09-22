#import "WCCFloatingPanel.h"
#import "WCCSettings.h"
#import "WCCPreferences.h"
// Transparency applies only to our fixed custom-presented settings pages.
BOOL WCCPanelTransparent(void) { return [WCCPrefs() boolForKey:@"settingsPanelTransparent"]; }
void WCCPanelStyleCell(UITableViewCell *cell) {
    cell.backgroundColor=WCCPanelTransparent()?UIColor.clearColor:UIColor.secondarySystemGroupedBackgroundColor;
    cell.contentView.backgroundColor=UIColor.clearColor;
    for(UILabel *label in @[cell.textLabel,cell.detailTextLabel?:cell.textLabel]) {
        label.textColor=WCCPanelTransparent()?UIColor.whiteColor:UIColor.labelColor;
        label.shadowColor=WCCPanelTransparent()?UIColor.blackColor:nil;
        label.shadowOffset=CGSizeMake(0,1);
    }
}
void WCCPanelStyleSection(UIView *view) {
    if([view isKindOfClass:UITableViewHeaderFooterView.class]) {
        UITableViewHeaderFooterView *v=(id)view;
        v.backgroundConfiguration=[UIBackgroundConfiguration clearConfiguration];
        v.textLabel.textColor=WCCPanelTransparent()?UIColor.whiteColor:UIColor.secondaryLabelColor;
        v.textLabel.shadowColor=WCCPanelTransparent()?UIColor.blackColor:nil;
        v.textLabel.shadowOffset=CGSizeMake(0,1);
    }
}
// Compatibility only. No floating view/controller construction or observers.
@implementation WCCFloatingPanel
+ (BOOL)isOpenFor:(UIViewController *)owner { return NO; }
+ (void)openFor:(UIViewController *)owner root:(UIViewController *)root completion:(void (^)(void))completion { [WCCSettings presentFrom:owner completion:completion]; }
+ (void)closeFor:(UIViewController *)owner { }
@end
