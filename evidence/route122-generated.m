#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#include <assert.h>
#define UIGestureRecognizerStateRecognized 3
@interface UIView : NSObject
@property(nonatomic,strong) id window;
@end
@implementation UIView
@end
@interface UIViewController : NSObject
@property BOOL isViewLoaded, isBeingPresented, isBeingDismissed, reject;
@property(nonatomic,strong) UIView *view;
@property(nonatomic,strong) UIViewController *presentedViewController;
@property(nonatomic,strong) id transitionCoordinator;
- (void)presentViewController:(UIViewController *)c animated:(BOOL)a completion:(void (^)(void))done;
- (void)dismissViewControllerAnimated:(BOOL)a completion:(void (^)(void))done;
@end
@implementation UIViewController
- (void)presentViewController:(UIViewController *)c animated:(BOOL)a completion:(void (^)(void))done { if(!self.reject) self.presentedViewController=c; if(done)done(); }
- (void)dismissViewControllerAnimated:(BOOL)a completion:(void (^)(void))done { self.presentedViewController=nil; if(done)done(); }
@end
@interface UITapGestureRecognizer : NSObject
@property NSInteger state;
@end
@implementation UITapGestureRecognizer
@end
@interface Media : NSObject
@property BOOL active;
@end
@implementation Media
@end
static void (^WCCOnce(void (^completion)(void)))(void) {
    __block BOOL finished=NO;
    return [^{ if (finished) return; finished=YES; if(completion) completion(); } copy];
}
static void WCCShow(UIViewController *p, UIViewController *a, void (^rejected)(void)) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ WCCShow(p, a, rejected); });
        return;
    }
    if (!p || !p.isViewLoaded || !p.view.window || p.presentedViewController || p.isBeingPresented || p.isBeingDismissed || p.transitionCoordinator) {
        if(rejected) rejected(); return;
    }
    [p presentViewController:a animated:YES completion:nil];
    if (p.presentedViewController != a && rejected) rejected();
}


static void (^sessionDone)(void);
@interface WCCSettings : NSObject
+ (void)presentFrom:(UIViewController *)p completion:(void (^)(void))done;
@end
@implementation WCCSettings
+ (void)presentFrom:(UIViewController *)p completion:(void (^)(void))done { sessionDone=WCCOnce(done); WCCShow(p,[UIViewController new],sessionDone); }
@end
@interface Controller : UIViewController
@property BOOL mediaSuspended;
@property(nonatomic,strong) Media *customMedia;
@property NSInteger refreshes, resumes;
- (void)refreshHourlyMedia;
- (void)preferencesChanged;
- (void)handleTwoFingerDoubleTap:(UITapGestureRecognizer *)gesture;
@end
@implementation Controller
- (void)refreshHourlyMedia { self.refreshes++; }
- (void)preferencesChanged { self.resumes++; }
- (void)handleTwoFingerDoubleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized || self.presentedViewController || self.mediaSuspended) return;
    if (![NSThread isMainThread] || !self.isViewLoaded || !self.view.window || self.isBeingDismissed || self.isBeingPresented || self.transitionCoordinator) return;
    // 122 restores the 120 native settings presentation and media suspension.
    self.mediaSuspended=YES; self.customMedia.active=NO; [self refreshHourlyMedia];
    __weak typeof(self) weak = self;
    [WCCSettings presentFrom:self completion:^{ weak.mediaSuspended=NO; [weak preferencesChanged]; }];
}

@end
@interface Page : UIViewController
@property(nonatomic,copy) void (^onDone)(void);
- (void)done;
@end
@implementation Page
- (void)done { void (^done)(void)=self.onDone; self.onDone=nil; if(done) [self dismissViewControllerAnimated:YES completion:done]; }

@end
int main(void) { @autoreleasepool {
 Controller *p=[Controller new]; p.isViewLoaded=YES; p.view=[UIView new]; p.view.window=[NSObject new]; p.customMedia=[Media new];
 UITapGestureRecognizer *g=[UITapGestureRecognizer new];
 assert([p respondsToSelector:@selector(handleTwoFingerDoubleTap:)]);
 [p handleTwoFingerDoubleTap:g]; assert(p.refreshes==0);
 g.state=3; p.view.window=nil; [p handleTwoFingerDoubleTap:g]; assert(p.refreshes==0);
 p.view.window=[NSObject new]; p.transitionCoordinator=[NSObject new]; [p handleTwoFingerDoubleTap:g]; assert(p.refreshes==0); p.transitionCoordinator=nil;
 p.reject=YES; [p handleTwoFingerDoubleTap:g]; assert(!p.mediaSuspended && p.resumes==1);
 p.reject=NO; [p handleTwoFingerDoubleTap:g]; assert(p.mediaSuspended && p.presentedViewController);
 NSInteger count=p.refreshes; [p handleTwoFingerDoubleTap:g]; assert(p.refreshes==count);
 p.presentedViewController=nil; sessionDone(); sessionDone(); assert(!p.mediaSuspended && p.resumes==2);
 __block int ends=0; for(int i=0;i<6;i++) { p.isViewLoaded=YES;p.isBeingPresented=NO;p.isBeingDismissed=NO;p.transitionCoordinator=nil;p.presentedViewController=nil;p.view.window=[NSObject new];
 if(i==0)p.isViewLoaded=NO; if(i==1)p.view.window=nil; if(i==2)p.isBeingPresented=YES; if(i==3)p.isBeingDismissed=YES; if(i==4)p.transitionCoordinator=[NSObject new]; if(i==5)p.presentedViewController=[UIViewController new];
 WCCShow(p,[UIViewController new],WCCOnce(^{ends++;})); } assert(ends==6);
 WCCShow(nil,[UIViewController new],^{ends++;}); assert(ends==7);
 Page *page=[Page new]; assert([page respondsToSelector:@selector(done)]); page.onDone=^{ends++;}; [page done];[page done]; assert(ends==8);
 puts("PASS122: extracted Objective-C WCCShow/WCCOnce/two-finger/done on Foundation route stubs. NOT UIKit or iOS16 runtime.");
 } return 0; }
