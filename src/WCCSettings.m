#import "WCCSettings.h"
#import "WCCPreferences.h"
#import "WCCGallery.h"
#import <objc/message.h>

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
- (void)done { [self dismissViewControllerAnimated:YES completion:self.onDone]; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller { return UIModalPresentationNone; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traits { return UIModalPresentationNone; }
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popover { return NO; }
@end

@implementation WCCSettings
+ (void)presentFrom:(UIViewController *)p completion:(void (^)(void))completion {
    UIAlertController *a = WCCAlert(@"天气 · 设置", @"单指双击切换附近/城市；双指同时双击打开设置。");
    WCCAction(a, @"自定义图标", ^{ WCCAfterAlert(p, ^{ [self iconsFrom:p completion:completion]; }); });
    WCCAction(a, @"模块尺寸（列 × 行）", ^{ WCCAfterAlert(p, ^{ [self sizesFrom:p completion:completion]; }); });
    WCCAction(a, @"地标显示", ^{ WCCAfterAlert(p, ^{ [self modesFrom:p completion:completion]; }); });
    [a addAction:[UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { WCCAfterAlert(p, completion); }]];
    WCCShow(p, a);
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
    UIAlertController *a = WCCAlert(@"自定义图标", @"关闭立即恢复天气原图。PNG/JPG/GIF/MP4 素材通过 Filza 导入；原有安全大小限制保持不变。");
    WCCAction(a, enabled ? @"关闭自定义图标" : @"开启自定义图标", ^{
        [WCCPrefs() setBool:!enabled forKey:@"customIcon"]; WCCSave(); WCCAfterAlert(p, ^{ [self iconsFrom:p completion:completion]; });
    });
    WCCAction(a, @"浏览 HTML 动态图库", ^{ WCCAfterAlert(p, ^{
        NSError *error = nil;
        if (![NSFileManager.defaultManager createDirectoryAtPath:WCCRoot() withIntermediateDirectories:YES attributes:nil error:&error]) {
            [self pathFailure:WCCRoot() reason:error.localizedDescription from:p completion:completion]; return;
        }
        WCCSettingsGallery *gallery = [WCCSettingsGallery new];
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
