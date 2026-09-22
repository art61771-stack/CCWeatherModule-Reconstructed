#import "WCCFloatingPanel.h"
#import "WCCPreferences.h"
#import "WCCPanelGeometry.h"
#import <objc/runtime.h>
@protocol WCCPanelSensitive <NSObject>
- (void)clearSensitiveInput;
@end
static char WCCPanelKey;
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
@interface WCCPanelOverlay : UIView
@property(nonatomic,copy) void (^layout)(void);
@end
@implementation WCCPanelOverlay
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)event { UIView *v=[super hitTest:p withEvent:event];return v==self?nil:v; }
- (void)layoutSubviews { [super layoutSubviews]; if(self.layout)self.layout(); }
@end
@interface WCCFloatingPanel () <UIGestureRecognizerDelegate,UINavigationControllerDelegate>
@property(nonatomic,strong) UINavigationController *nav;
@property(nonatomic,strong) UIView *surface;
@property(nonatomic,strong) UIView *header;
@property(nonatomic,strong) UISwitch *backgroundSwitch;
@property(nonatomic,copy) void (^completion)(void);
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic) CGPoint position;
@property(nonatomic) CGPoint dragOrigin;
@property(nonatomic) CGRect keyboard;
@property(nonatomic) BOOL closing;
@end
@implementation WCCFloatingPanel
+ (BOOL)isOpenFor:(UIViewController *)owner { return objc_getAssociatedObject(owner,&WCCPanelKey)!=nil; }
+ (void)openFor:(UIViewController *)owner root:(UIViewController *)root completion:(void (^)(void))completion {
    if(!owner.view.window || [self isOpenFor:owner] || owner.presentedViewController)return;
    WCCFloatingPanel *panel=[self new];panel.owner=owner;panel.completion=completion;
    panel.nav=[[UINavigationController alloc] initWithRootViewController:root];
    objc_setAssociatedObject(owner,&WCCPanelKey,panel,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [owner addChildViewController:panel];
    UIWindow *window=owner.view.window;panel.view.frame=window.bounds;
    panel.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [window addSubview:panel.view];[panel didMoveToParentViewController:owner];
}
+ (void)closeFor:(UIViewController *)owner { [(WCCFloatingPanel *)objc_getAssociatedObject(owner,&WCCPanelKey) close]; }
- (void)loadView {
    WCCPanelOverlay *overlay=[WCCPanelOverlay new];__weak typeof(self) weak=self;
    overlay.layout=^{[weak layoutPanel];};self.view=overlay;
}
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.clearColor;
    id x=[WCCPrefs() objectForKey:@"settingsPanelX"],y=[WCCPrefs() objectForKey:@"settingsPanelY"];
    self.position=CGPointMake(x?WCCPanelUnit([x doubleValue]):0.5,y?WCCPanelUnit([y doubleValue]):0.5);
    self.surface=[UIView new];self.surface.layer.cornerRadius=16;self.surface.clipsToBounds=YES;[self.view addSubview:self.surface];
    self.header=[UIView new];[self.surface addSubview:self.header];
    UILabel *title=[UILabel new];title.text=@"☰ 拖动设置";title.font=[UIFont boldSystemFontOfSize:15];title.textColor=UIColor.whiteColor;title.frame=CGRectMake(12,0,150,44);[self.header addSubview:title];
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];[close setTitle:@"关闭" forState:UIControlStateNormal];close.tintColor=UIColor.whiteColor;close.frame=CGRectMake(260,0,64,44);close.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin;[close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];[self.header addSubview:close];
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];pan.maximumNumberOfTouches=1;pan.delegate=self;[self.header addGestureRecognizer:pan];
    [self addChildViewController:self.nav];[self.surface addSubview:self.nav.view];[self.nav didMoveToParentViewController:self];self.nav.delegate=self;
    NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
    [nc addObserver:self selector:@selector(applyStyle) name:@"WCCPanelStyleChanged" object:nil];
    [nc addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(close) name:UIApplicationWillResignActiveNotification object:nil];
    [nc addObserver:self selector:@selector(close) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self applyStyle];
}
- (CGRect)available {
    CGRect r=UIEdgeInsetsInsetRect(self.view.bounds,self.view.safeAreaInsets);
    if(!CGRectIsEmpty(self.keyboard)) { CGRect k=[self.view convertRect:self.keyboard fromView:nil];if(CGRectIntersectsRect(r,k))r.size.height=MAX(44,MIN(CGRectGetMaxY(r),CGRectGetMinY(k))-r.origin.y); }
    return CGRectInset(r,6,6);
}
- (void)layoutPanel {
    if(self.closing)return;
    if(!self.owner || !self.owner.view.window) { [self close]; return; }
    CGRect r=[self available];CGFloat w=MIN(350,MAX(1,r.size.width)),h=MIN(540,MAX(44,r.size.height));
    self.surface.frame=CGRectMake(WCCPanelOrigin(r.origin.x,r.size.width,w,self.position.x),WCCPanelOrigin(r.origin.y,r.size.height,h,self.position.y),w,h);
    self.header.frame=CGRectMake(0,0,w,44);
    // Explicit close layout avoids assuming a fixed screen or panel width.
    self.header.subviews.lastObject.frame=CGRectMake(MAX(0,w-64),0,64,44);
    self.nav.view.frame=CGRectMake(0,44,w,MAX(0,h-44));
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)touch {
    UIView *v=touch.view;BOOL control=NO;for(UIView *p=v;p && p!=self.header;p=p.superview)if([p isKindOfClass:UIControl.class])control=YES;
    return WCCPanelCanDrag([v isDescendantOfView:self.header],control,1);
}
- (void)drag:(UIPanGestureRecognizer *)pan {
    if(pan.state==UIGestureRecognizerStateBegan)self.dragOrigin=self.surface.frame.origin;
    CGPoint d=[pan translationInView:self.view];CGRect r=[self available];CGSize size=self.surface.bounds.size;
    self.position=CGPointMake(WCCPanelPosition(self.dragOrigin.x+d.x,r.origin.x,r.size.width,size.width),WCCPanelPosition(self.dragOrigin.y+d.y,r.origin.y,r.size.height,size.height));
    [self layoutPanel];
    if(pan.state==UIGestureRecognizerStateEnded) { [WCCPrefs() setDouble:self.position.x forKey:@"settingsPanelX"];[WCCPrefs() setDouble:self.position.y forKey:@"settingsPanelY"];[WCCPrefs() synchronize]; }
}
- (void)keyboardChanged:(NSNotification *)note {
    self.keyboard=[note.name isEqual:UIKeyboardWillHideNotification]?CGRectZero:[note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];[self layoutPanel];
}
- (void)applyStyle {
    BOOL transparent=WCCPanelTransparent();
    self.surface.backgroundColor=transparent?UIColor.clearColor:UIColor.systemGroupedBackgroundColor;
    self.header.backgroundColor=transparent?UIColor.clearColor:[UIColor colorWithWhite:0.12 alpha:1];
    UINavigationBarAppearance *appearance=[UINavigationBarAppearance new];
    if(transparent)[appearance configureWithTransparentBackground];else [appearance configureWithDefaultBackground];
    appearance.titleTextAttributes=@{NSForegroundColorAttributeName:transparent?UIColor.whiteColor:UIColor.labelColor};
    self.nav.navigationBar.standardAppearance=appearance;self.nav.navigationBar.scrollEdgeAppearance=appearance;self.nav.navigationBar.compactAppearance=appearance;
    self.nav.view.backgroundColor=UIColor.clearColor;
    for(UIViewController *vc in self.nav.viewControllers) {
        vc.view.backgroundColor=transparent?UIColor.clearColor:UIColor.systemGroupedBackgroundColor;
        if([vc isKindOfClass:UITableViewController.class]) { UITableView *table=((UITableViewController *)vc).tableView;table.backgroundView=nil;[table reloadData]; }
    }
}
- (void)navigationController:(UINavigationController *)nav willShowViewController:(UIViewController *)vc animated:(BOOL)animated { [self applyStyle]; }
- (void)close {
    if(self.closing)return;self.closing=YES;[self.view endEditing:YES];
    for(UIViewController *vc in self.nav.viewControllers)if([vc respondsToSelector:NSSelectorFromString(@"clearSensitiveInput")])[(id<WCCPanelSensitive>)vc clearSensitiveInput];
    [self.nav dismissViewControllerAnimated:NO completion:nil];
    [self willMoveToParentViewController:nil];[self.view removeFromSuperview];[self removeFromParentViewController];
    UIViewController *owner=self.owner;void (^done)(void)=self.completion;self.completion=nil;
    objc_setAssociatedObject(owner,&WCCPanelKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);if(done)done();
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end
