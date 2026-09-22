#import "WCCSettings.h"
#import "WCCFloatingPanel.h"
#import "WCCRuntime.h"
#import "WCCPreferences.h"
#import "WCCGallery.h"
#import "WCCRegionSettings.h"
#import "WCCWeatherSettings.h"
#import <objc/message.h>
#include <math.h>

static void WCCSave(void) {
    [WCCPrefs() synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:WCCPreferencesChanged object:nil];
}
// Wait for the current alert to dismiss before presenting a child alert.
static void WCCAfterAlert(UIViewController *p, void (^next)(void)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *current = p.presentedViewController;
        if (current.isBeingDismissed && current.transitionCoordinator) {
            BOOL queued = [current.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) { if (next) next(); }];
            if (queued) return;
        }
        if (current) [p dismissViewControllerAnimated:YES completion:next];
        else if (next) next();
    });
}
static UIAlertController *WCCAlert(NSString *title, NSString *message) {
    return [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
}
static void WCCAction(UIAlertController *a, NSString *title, void (^work)(void)) {
    [a addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { if (work) work(); }]];
}
static void WCCShow(UIViewController *p, UIAlertController *a) {
    if (p.view.window && !p.presentedViewController) [p presentViewController:a animated:YES completion:nil];
}

@interface WCCSettingsGallery : WCCGallery <UIPopoverPresentationControllerDelegate>
@property(nonatomic,copy) void (^onDone)(void);
@end
@implementation WCCSettingsGallery
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
}
- (void)done { [self.navigationController popViewControllerAnimated:YES]; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller { return UIModalPresentationNone; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traits { return UIModalPresentationNone; }
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popover { return NO; }
@end

// A real UIKit page, never a slider inserted into UIAlertController internals.
@interface WCCIconScaleController : UIViewController <UIPopoverPresentationControllerDelegate>
@property(nonatomic,copy) void (^onDone)(void);
@property(nonatomic,strong) UISlider *slider;
@property(nonatomic,strong) UILabel *valueLabel;
@property(nonatomic,strong) UISlider *expandedSlider;
@property(nonatomic,strong) UILabel *expandedLabel;
@end
@implementation WCCIconScaleController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"主图标大小";
    self.view.backgroundColor=UIColor.systemBackgroundColor;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.valueLabel=[UILabel new]; self.valueLabel.font=[UIFont monospacedDigitSystemFontOfSize:22 weight:UIFontWeightMedium]; self.valueLabel.textAlignment=NSTextAlignmentCenter;
    self.slider=[UISlider new]; self.slider.minimumValue=-1; self.slider.maximumValue=1;
    self.slider.value=WCCCollapsedSliderPosition(WCCMainIconPercentForMode(NO)); self.slider.enabled=YES;
    self.slider.accessibilityLabel=@"折叠主图标大小";
    self.expandedLabel=[UILabel new];self.expandedLabel.textAlignment=NSTextAlignmentCenter;
    self.expandedSlider=[UISlider new];self.expandedSlider.minimumValue=50;self.expandedSlider.maximumValue=150;self.expandedSlider.tag=1;
    self.expandedSlider.value=WCCMainIconPercentForMode(YES);self.expandedSlider.accessibilityLabel=@"展开主图标大小";
    [self.expandedSlider addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
    UILabel *range=[UILabel new]; range.text=@"折叠 50% ← 100% → 250% · 每步5%"; range.font=[UIFont systemFontOfSize:12]; range.textAlignment=NSTextAlignmentCenter;
    UILabel *note=[UILabel new]; note.numberOfLines=0; note.font=[UIFont systemFontOfSize:13]; note.textColor=UIColor.secondaryLabelColor;
    note.text=@"原系统天气主图、自定义 PNG/GIF/MP4 及失败回退原图共用大小与中心，关闭自定义图标仍可调节。折叠主页面与展开头部各自独立调节，一个滑块不会影响另一个。旧版大小作为两个滑块的初值。小时图标固定 30pt 不受影响。100% 为 1.1.8 原始大小；折叠50–250%、展开50–150%，每步5%。100%均在滑条中心；折叠右半为100–250%。仅容器边界限幅，大图可能遮挡自行配置的文字。八个区域位置偏移仅作用折叠页面，与本设置不同。";
    UIScrollView *scroll=[UIScrollView new];scroll.frame=self.view.bounds;scroll.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.view addSubview:scroll];
    UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[self.valueLabel,self.slider,self.expandedLabel,self.expandedSlider,range,note]];
    stack.axis=UILayoutConstraintAxisVertical; stack.spacing=14; stack.translatesAutoresizingMaskIntoConstraints=NO; [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20],[stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20],[stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:18],[stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-18],[stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40]]];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(syncScale) name:WCCRegionPositionChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(syncScale) name:WCCMainIconScaleChanged object:nil];
    [self showValue];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)syncScale { self.slider.value=WCCCollapsedSliderPosition(WCCMainIconPercentForMode(NO)); self.expandedSlider.value=WCCMainIconPercentForMode(YES); [self showValue]; }
- (void)showValue {
    self.expandedLabel.text=[NSString stringWithFormat:@"展开 %.0f%%",self.expandedSlider.value];
    self.expandedSlider.accessibilityValue=[NSString stringWithFormat:@"%.0f%%",self.expandedSlider.value];
    self.valueLabel.text=[NSString stringWithFormat:@"折叠 %.0f%%",WCCCollapsedSliderPercent(self.slider.value)];
    self.slider.accessibilityValue=[NSString stringWithFormat:@"%.0f%%",WCCCollapsedSliderPercent(self.slider.value)];
}
- (void)changed:(UISlider *)slider {
    double percent=slider.tag==1?roundf(slider.value/5)*5:WCCCollapsedSliderPercent(slider.value);
    BOOL ok=WCCSetMainIconPercentForMode(slider.tag==1,percent); [self syncScale];
    if(!ok){UIAlertController *a=WCCAlert(@"保存失败",@"已保留原设置，请重试。");[a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];}
}
- (void)done { [self.navigationController popViewControllerAnimated:YES]; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller { return UIModalPresentationNone; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traits { return UIModalPresentationNone; }
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popover { return NO; }
@end

// Compact original-asset category page. No localized-condition substring matching.
@interface WCCWeatherMappings : UITableViewController <UIPopoverPresentationControllerDelegate>
@property(nonatomic,copy) void (^onDone)(void);
@end
@implementation WCCWeatherMappings
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"选择原天气图标";
    self.tableView.rowHeight=64;
    self.tableView.estimatedRowHeight=64;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (void)done { [self.navigationController popViewControllerAnimated:YES]; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller { return UIModalPresentationNone; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traits { return UIModalPresentationNone; }
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section { return WCCAssetKeys().count; }
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section { return @"先选原天气名称，再选任意文件名的素材；仅替换该类天气。左滑清除该类绑定，不删除文件。旧版全局选图不再应用，须逐类重新绑定。总开关独立控制。"; }
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell=[table dequeueReusableCellWithIdentifier:@"weather"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"weather"];
    NSString *key=WCCAssetKeys()[index.row], *name=WCCMappedName(key);
    // Always resolve the original basename in this module's resource bundle.
    // Never use the user's mapping/root for the category thumbnail.
    cell.imageView.image=nil;
    NSString *path=[[NSBundle bundleForClass:WCCWeatherMappings.class] pathForResource:key ofType:@"png"];
    UIImage *original=path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (original) {
        // A fixed transparent canvas keeps differently sized originals compact.
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(36,36),NO,0);
        CGFloat scale=MIN(36.0/MAX(original.size.width,1),36.0/MAX(original.size.height,1));
        CGSize size=CGSizeMake(original.size.width*scale,original.size.height*scale);
        [original drawInRect:CGRectMake((36-size.width)/2,(36-size.height)/2,size.width,size.height)];
        cell.imageView.image=[UIGraphicsGetImageFromCurrentImageContext() imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIGraphicsEndImageContext();
    }
    cell.imageView.contentMode=UIViewContentModeScaleAspectFit;
    cell.textLabel.text=key; cell.detailTextLabel.numberOfLines=2;
    cell.detailTextLabel.text=name ? [NSString stringWithFormat:@"%@%@ · 左滑清除",name,WCCSafePath(WCCRoot(),name)?@"":@"（失效，使用原图）"] : @"未绑定 · 使用原天气图标";
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator; WCCPanelStyleCell(cell);return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index {
    [table deselectRowAtIndexPath:index animated:YES];
    WCCGallery *gallery=[WCCGallery new]; gallery.targetKey=WCCAssetKeys()[index.row];
    [self.navigationController pushViewController:gallery animated:YES];
}
- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)index { return WCCMappedName(WCCAssetKeys()[index.row])!=nil; }
- (NSString *)tableView:(UITableView *)table titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)index { return @"清除绑定"; }
- (void)tableView:(UITableView *)table commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)index {
    if (style==UITableViewCellEditingStyleDelete) { WCCSetMappedName(WCCAssetKeys()[index.row],nil); WCCSave(); [table reloadData]; }
}
@end

// The menu and all continuous tuning pages share one child navigation stack.
@interface WCCSettings (PanelActions)
+ (void)sizesFrom:(UIViewController *)p completion:(void (^)(void))completion;
+ (void)modesFrom:(UIViewController *)p completion:(void (^)(void))completion;
+ (void)openFilzaFrom:(UIViewController *)p completion:(void (^)(void))completion;
@end
@interface WCCPanelMenu : UITableViewController
@end
@implementation WCCPanelMenu
- (void)viewDidLoad { [super viewDidLoad];self.title=@"天气 · 设置";self.tableView.rowHeight=56; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)section { return 9; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)section { return @"只拖动顶部标题栏；面板外仍可操作控制中心。透明只影响设置面板背景，不改变天气模块。位置和透明偏好不写入布局方案。"; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text=@[@"天气来源 / 彩云 / 连接状态",@"位置 / 阴影 / 问候 / 方案",@"主图标大小",@"按天气名称管理绑定",@"自定义图标",@"设置面板背景",@"模块尺寸（列 × 行）",@"地标显示",@"用 Filza 打开素材目录"][index.row];
    if(index.row==4 || index.row==5) {
        UISwitch *toggle=[UISwitch new];toggle.tag=index.row;
        toggle.on=index.row==5?WCCPanelTransparent():[WCCPrefs() boolForKey:@"customIcon"];
        [toggle addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=toggle;
        if(index.row==5)cell.detailTextLabel.text=@"关闭：原背景 · 开启：透明背景";
    } else cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    WCCPanelStyleCell(cell);return cell;
}
- (void)toggle:(UISwitch *)toggle {
    [WCCPrefs() setBool:toggle.on forKey:toggle.tag==5?@"settingsPanelTransparent":@"customIcon"];[WCCPrefs() synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:toggle.tag==5?@"WCCPanelStyleChanged":WCCPreferencesChanged object:nil];
}
- (void)tableView:(UITableView *)t willDisplayHeaderView:(UIView *)v forSection:(NSInteger)section { WCCPanelStyleSection(v); }
- (void)tableView:(UITableView *)t willDisplayFooterView:(UIView *)v forSection:(NSInteger)section { WCCPanelStyleSection(v); }
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)index {
    [t deselectRowAtIndexPath:index animated:YES];UIViewController *page=nil;
    if(index.row==0)page=[[WCCWeatherSettings alloc] initWithStyle:UITableViewStyleInsetGrouped];
    if(index.row==1)page=[[WCCRegionSettings alloc] initWithStyle:UITableViewStyleInsetGrouped];
    if(index.row==2)page=[WCCIconScaleController new];
    if(index.row==3)page=[[WCCWeatherMappings alloc] initWithStyle:UITableViewStylePlain];
    if(page){[self.navigationController pushViewController:page animated:YES];return;}
    if(index.row==6)[WCCSettings sizesFrom:self completion:nil];
    if(index.row==7)[WCCSettings modesFrom:self completion:nil];
    if(index.row==8)[WCCSettings openFilzaFrom:self completion:nil];
}
@end
@implementation WCCSettings
+ (void)presentFrom:(UIViewController *)p completion:(void (^)(void))completion {
    if([p isKindOfClass:WCCPanelMenu.class])return;
    [WCCFloatingPanel openFor:p root:[[WCCPanelMenu alloc] initWithStyle:UITableViewStyleInsetGrouped] completion:completion];
}
+ (void)back:(UIAlertController *)a from:(UIViewController *)p completion:(void (^)(void))completion {
    [a addAction:[UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        WCCAfterAlert(p, ^{ [self presentFrom:p completion:completion]; });
    }]];
}
+ (void)sizesFrom:(UIViewController *)p completion:(void (^)(void))completion {
    BOOL enabled = [WCCPrefs() boolForKey:@"customSize"];
    UIAlertController *a = WCCAlert(@"模块尺寸", @"列宽 × 行高。选择保存后手动注销 SpringBoard 生效，以刷新模块和控制中心布局缓存。不会自动注销；关闭恢复 4×1。");
    WCCAction(a, enabled ? @"关闭自定义尺寸" : @"开启自定义尺寸", ^{
        [WCCPrefs() setBool:!enabled forKey:@"customSize"]; WCCSave();
        WCCAfterAlert(p, ^{ [self sizesFrom:p completion:completion]; });
    });
    for (NSString *size in WCCSizeOptions()) {
        NSString *label = [size stringByReplacingOccurrencesOfString:@"x" withString:@"×"];
        if ([size isEqual:WCCSelectedSize()]) label = [@"✓ " stringByAppendingString:label];
        WCCAction(a, label, ^{
            BOOL saved = WCCSetSelectedSize(size); WCCSave();
            WCCAfterAlert(p, ^{
                UIAlertController *notice = WCCAlert(saved ? @"尺寸已保存" : @"保存尚未确认", saved ? @"自定义尺寸开关保持不变。开启后请手动注销 SpringBoard（不是重启手机）；本次会话仍使用旧布局。" : @"系统未确认偏好同步，请重选并在注销后检查。");
                WCCAction(notice, @"好", ^{ WCCAfterAlert(p, ^{ [self sizesFrom:p completion:completion]; }); }); WCCShow(p, notice);
            });
        });
    }
    [self back:a from:p completion:completion]; WCCShow(p, a);
}
+ (void)modesFrom:(UIViewController *)p completion:(void (^)(void))completion {
    UIAlertController *a = WCCAlert(@"地标显示", @"显示方式立即保存；自定义地标留空恢复附近。");
    NSArray *modes = @[@"附近", @"城市", @"自定义地标"];
    for (NSInteger i = 0; i < 3; i++) {
        WCCAction(a, modes[i], ^{
            if (i == 2) { WCCAfterAlert(p, ^{ [self editLandmarkFrom:p completion:^{ [self modesFrom:p completion:completion]; }]; }); return; }
            [WCCPrefs() setInteger:i forKey:@"displayMode"]; WCCSave();
            WCCAfterAlert(p, ^{ [self modesFrom:p completion:completion]; });
        });
    }
    [self back:a from:p completion:completion]; WCCShow(p, a);
}
+ (void)editLandmarkFrom:(UIViewController *)p completion:(void (^)(void))completion {
    UIAlertController *a = WCCAlert(@"自定义地标", @"留空恢复附近地标，最多80字。");
    [a addTextFieldWithConfigurationHandler:^(UITextField *field) { field.text = [WCCPrefs() stringForKey:@"landmark"]; field.placeholder = @"例如：我的家"; }];
    WCCAction(a, @"保存", ^{
        NSString *name = [a.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
        if (name.length > 80) name = [name substringToIndex:80];
        [WCCPrefs() setObject:name forKey:@"landmark"]; [WCCPrefs() setInteger:name.length ? 2 : 0 forKey:@"displayMode"]; WCCSave(); WCCAfterAlert(p, completion);
    });
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { WCCAfterAlert(p, completion); }]];
    WCCShow(p, a);
}
+ (void)iconsFrom:(UIViewController *)p completion:(void (^)(void))completion {
    BOOL enabled = [WCCPrefs() boolForKey:@"customIcon"];
    UIAlertController *a = WCCAlert(@"自定义图标", @"按实时天气及昼夜分别替换原资源图标；关闭立即恢复原图。旧版全局选图请按天气重新绑定，文件保持不变。PNG/JPG/JPEG/GIF/MP4 请直接放入 /var/mobile/Documents/CCWeatherModule/Icons（不扫描子目录）。导入后打开图库并点右上角刷新；读取失败和过滤原因会显示在图库中。");
    WCCAction(a, enabled ? @"关闭自定义图标" : @"开启自定义图标", ^{
        [WCCPrefs() setBool:!enabled forKey:@"customIcon"]; WCCSave(); WCCAfterAlert(p, ^{ [self iconsFrom:p completion:completion]; });
    });
    WCCAction(a, @"主图标大小", ^{ WCCAfterAlert(p, ^{
        WCCIconScaleController *page=[WCCIconScaleController new];
        page.onDone=^{ [self iconsFrom:p completion:completion]; };
        UINavigationController *nav=[[UINavigationController alloc] initWithRootViewController:page];
        nav.modalPresentationStyle=UIModalPresentationPopover; nav.preferredContentSize=CGSizeMake(320,330);
        UIPopoverPresentationController *pop=nav.popoverPresentationController;
        pop.sourceView=p.view; pop.sourceRect=CGRectMake(CGRectGetMidX(p.view.bounds),CGRectGetMidY(p.view.bounds),1,1);
        pop.permittedArrowDirections=0; pop.delegate=page;
        if (p.view.window && !p.presentedViewController) [p presentViewController:nav animated:YES completion:nil];
    }); });
    WCCAction(a, @"按天气名称管理绑定", ^{ WCCAfterAlert(p, ^{
        NSError *error = nil;
        if (![NSFileManager.defaultManager createDirectoryAtPath:WCCRoot() withIntermediateDirectories:YES attributes:nil error:&error]) {
            [self pathFailure:WCCRoot() reason:error.localizedDescription from:p completion:completion]; return;
        }
        WCCWeatherMappings *gallery = [[WCCWeatherMappings alloc] initWithStyle:UITableViewStylePlain];
        gallery.onDone = ^{ [self iconsFrom:p completion:completion]; };
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gallery];
        nav.modalPresentationStyle = UIModalPresentationPopover;
        nav.preferredContentSize = CGSizeMake(320, 420);
        UIPopoverPresentationController *pop = nav.popoverPresentationController;
        pop.sourceView = p.view; pop.sourceRect = CGRectMake(CGRectGetMidX(p.view.bounds), CGRectGetMidY(p.view.bounds), 1, 1);
        pop.permittedArrowDirections = 0; pop.delegate = gallery;
        if (p.view.window && !p.presentedViewController) [p presentViewController:nav animated:YES completion:nil];
    }); });
    WCCAction(a, @"用 Filza 打开素材目录", ^{ WCCAfterAlert(p, ^{ [self openFilzaFrom:p completion:completion]; }); });
    [self back:a from:p completion:completion]; WCCShow(p, a);
}
+ (void)pathFailure:(NSString *)path reason:(NSString *)reason from:(UIViewController *)p completion:(void (^)(void))completion {
    UIAlertController *a = WCCAlert(@"无法打开素材目录", [NSString stringWithFormat:@"%@\n%@\n请检查 Filza 是否安装，或复制路径后手动前往。", reason ?: @"系统未能打开 Filza。", path]);
    WCCAction(a, @"复制路径", ^{ UIPasteboard.generalPasteboard.string = path; WCCAfterAlert(p, ^{ [self iconsFrom:p completion:completion]; }); });
    WCCAction(a, @"返回", ^{ WCCAfterAlert(p, ^{ [self iconsFrom:p completion:completion]; }); });
    WCCShow(p, a);
}
+ (void)openFilzaFrom:(UIViewController *)p completion:(void (^)(void))completion {
    NSString *path = WCCRoot(); NSError *error = nil;
    if (![NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
        [self pathFailure:path reason:error.localizedDescription from:p completion:completion]; return;
    }
    // Encode each path as UTF-8 URL data; never leave #, ?, %, or spaces literal.
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/"];
    NSString *encoded = [path stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    NSURL *url = encoded ? [NSURL URLWithString:[@"filza://view" stringByAppendingString:encoded]] : nil;
    if (!url) { [self pathFailure:path reason:@"目录 URL 编码失败。" from:p completion:completion]; return; }
    UIApplication *app = UIApplication.sharedApplication;
    // SpringBoard must launch as an external user request, not as its own app.
    // Runtime guard avoids binding the bundle to a private SDK declaration.
    SEL springOpen = NSSelectorFromString(@"openURL:withCompletionHandler:");
    __block BOOL finished = NO;
    void (^finish)(BOOL) = ^(BOOL ok) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finished) return; finished = YES;
            if (ok) { if (completion) completion(); }
            else [self pathFailure:path reason:@"系统未确认 Filza 已打开（可能未安装或 URL 路由不支持）。" from:p completion:completion];
        });
    };
    if ([app respondsToSelector:springOpen]) {
        ((void (*)(id, SEL, NSURL *, id))objc_msgSend)(app, springOpen, url, finish);
    } else {
        [app openURL:url options:@{} completionHandler:finish];
    }
    // Some SpringBoard versions never invoke the private completion callback.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ finish(NO); });
}
@end
