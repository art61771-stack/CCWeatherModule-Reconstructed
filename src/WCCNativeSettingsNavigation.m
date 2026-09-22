#import "WCCFloatingPanel.h"
#import "WCCPreferences.h"

@protocol WCCPanelPageStyle <NSObject>
- (void)applySettingsPanelStyle;
@end
// UIKit owns presentation containment. No child is ever attached to UIWindow.
@interface WCCFixedPresentation : UIPresentationController
@end
@implementation WCCFixedPresentation
- (BOOL)shouldRemovePresentersView { return NO; }
- (CGRect)frameOfPresentedViewInContainerView {
    CGRect r=UIEdgeInsetsInsetRect(self.containerView.bounds,self.containerView.safeAreaInsets);
    CGFloat w=MIN(350,MAX(1,r.size.width-16)),h=MIN(540,MAX(1,r.size.height-16));
    return CGRectMake(CGRectGetMidX(r)-w/2,CGRectGetMidY(r)-h/2,w,h);
}
- (void)containerViewWillLayoutSubviews { [super containerViewWillLayoutSubviews]; self.presentedView.frame=self.frameOfPresentedViewInContainerView; }
@end
@interface WCCNativeSettingsNavigation () <UIViewControllerTransitioningDelegate,UINavigationControllerDelegate>
@property(nonatomic,strong) UISwitch *transparencySwitch;
@end
@implementation WCCNativeSettingsNavigation
- (instancetype)initWithRootViewController:(UIViewController *)root {
    if((self=[super initWithRootViewController:root])) { self.modalPresentationStyle=UIModalPresentationCustom;self.transitioningDelegate=self;self.delegate=self; }
    return self;
}
- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[WCCFixedPresentation alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}
- (void)viewDidLoad {
    [super viewDidLoad];self.view.layer.cornerRadius=16;self.view.clipsToBounds=YES;
    self.transparencySwitch=[UISwitch new];self.transparencySwitch.on=WCCPanelTransparent();
    self.transparencySwitch.accessibilityLabel=@"设置调参面板透明背景";
    [self.transparencySwitch addTarget:self action:@selector(transparencyChanged:) forControlEvents:UIControlEventValueChanged];
    [self setToolbarHidden:NO animated:NO];[self applyPanelStyle];
}
- (void)transparencyChanged:(UISwitch *)sender {
    [WCCPrefs() setBool:sender.on forKey:@"settingsPanelTransparent"];[WCCPrefs() synchronize];[self applyPanelStyle];
}
- (void)applyPanelStyle {
    BOOL transparent=WCCPanelTransparent();
    UIColor *background=transparent?UIColor.clearColor:UIColor.systemGroupedBackgroundColor;
    self.view.backgroundColor=background;
    UINavigationBarAppearance *bar=[UINavigationBarAppearance new];
    if(transparent)[bar configureWithTransparentBackground];else [bar configureWithDefaultBackground];
    bar.titleTextAttributes=@{NSForegroundColorAttributeName:transparent?UIColor.whiteColor:UIColor.labelColor};
    self.navigationBar.standardAppearance=bar;self.navigationBar.scrollEdgeAppearance=bar;self.navigationBar.compactAppearance=bar;
    UIToolbarAppearance *tool=[UIToolbarAppearance new];
    if(transparent)[tool configureWithTransparentBackground];else [tool configureWithDefaultBackground];
    self.toolbar.standardAppearance=tool;self.toolbar.compactAppearance=tool;
    if (@available(iOS 15.0, *)) self.toolbar.scrollEdgeAppearance=tool;
    for(UIViewController *vc in self.viewControllers) {
        vc.view.backgroundColor=background;
        // Only direct, app-owned labels; never walk UIKit private subviews.
        for(UIView *view in vc.view.subviews) if([view isKindOfClass:UILabel.class]) ((UILabel *)view).textColor=transparent?UIColor.whiteColor:UIColor.labelColor;
        if([vc respondsToSelector:@selector(applySettingsPanelStyle)]) [(id<WCCPanelPageStyle>)vc applySettingsPanelStyle];
        UILabel *label=[UILabel new];label.text=@"调参面板透明（固定位置）";label.font=[UIFont systemFontOfSize:12];label.textColor=transparent?UIColor.whiteColor:UIColor.labelColor;[label sizeToFit];
        vc.toolbarItems=@[[[UIBarButtonItem alloc] initWithCustomView:label],[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],[[UIBarButtonItem alloc] initWithCustomView:self.transparencySwitch]];
        if([vc isKindOfClass:UITableViewController.class]) { UITableView *table=((UITableViewController *)vc).tableView;table.backgroundView=nil;[table reloadData]; }
    }
}
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated { [self applyPanelStyle]; }
@end
