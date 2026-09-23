#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import "../src/WCCRoutePolicy.h"
#include <assert.h>
@protocol UIViewControllerTransitionCoordinatorContext @end
@interface Coordinator : NSObject
@property(nonatomic,copy) void (^pending)(id<UIViewControllerTransitionCoordinatorContext>);
- (BOOL)animateAlongsideTransition:(id)a completion:(void (^)(id<UIViewControllerTransitionCoordinatorContext>))c;
@end
@implementation Coordinator
- (BOOL)animateAlongsideTransition:(id)a completion:(void (^)(id<UIViewControllerTransitionCoordinatorContext>))c { self.pending=c;return YES; }
@end
@interface UIView : NSObject
@property(nonatomic,strong) id window;
@end
@implementation UIView @end
@interface UIViewController : NSObject
@property BOOL isViewLoaded,isBeingPresented,isBeingDismissed,reject;
@property(nonatomic,strong) UIView *view;
@property(nonatomic,strong) UIViewController *presentedViewController;
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) Coordinator *transitionCoordinator;
- (void)presentViewController:(UIViewController *)c animated:(BOOL)a completion:(void (^)(void))done;
- (void)dismissViewControllerAnimated:(BOOL)a completion:(void (^)(void))done;
@end
@implementation UIViewController
- (void)presentViewController:(UIViewController *)c animated:(BOOL)a completion:(void (^)(void))done { if(!self.reject){self.presentedViewController=c;c.owner=self;}if(done)done(); }
- (void)dismissViewControllerAnimated:(BOOL)a completion:(void (^)(void))done { if(self.owner.presentedViewController==self)self.owner.presentedViewController=nil;else self.presentedViewController=nil;if(done)done(); }
@end
// One owner-local session. Late UIKit completions cannot resurrect a closed CC.
@interface WCCSettingsSession : NSObject
@property(nonatomic) BOOL ended;
@property(nonatomic,weak) UIViewController *root;
@property(nonatomic,copy) void (^finish)(void);
@end
@implementation WCCSettingsSession @end
static char WCCSettingsSessionKey;
static WCCSettingsSession *WCCSession(UIViewController *p) { return objc_getAssociatedObject(p,&WCCSettingsSessionKey); }
static void (^WCCReturn(UIViewController *p,void (^work)(void)))(void) {
    WCCSettingsSession *session=WCCSession(p);
    return [^{ if(WCCRouteCanReturn(session!=nil,session.ended,WCCSession(p)==session,p.view.window!=nil)) work(); } copy];
}
static void (^WCCOnce(void (^completion)(void)))(void) {
    __block BOOL finished=NO;
    return [^{ if (finished) return; finished=YES; if(completion) completion(); } copy];
}
static void WCCShow(UIViewController *p, UIViewController *a, void (^rejected)(void)) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ WCCShow(p, a, rejected); });
        return;
    }
    if (!p || !WCCRouteCanEnter(p.isViewLoaded,p.view.window!=nil,p.presentedViewController!=nil,p.isBeingPresented,p.isBeingDismissed,p.transitionCoordinator!=nil)) {
        if(rejected) rejected(); return;
    }
    WCCSettingsSession *session=WCCSession(p);
    if(session.ended) { if(rejected)rejected();return; }
    if(!session) {
        session=[WCCSettingsSession new];session.finish=WCCOnce(rejected);
        objc_setAssociatedObject(p,&WCCSettingsSessionKey,session,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    session.root=a;
    [p presentViewController:a animated:YES completion:nil];
    if (p.presentedViewController != a && rejected) rejected();
}


@interface WCCSettings : NSObject
+ (void)cancelFrom:(UIViewController *)p;
@end
@implementation WCCSettings
+ (void)cancelFrom:(UIViewController *)p {
    NSAssert(NSThread.isMainThread,@"UIKit main thread");
    WCCSettingsSession *session=WCCSession(p); if(!session || session.ended)return;
    session.ended=YES;
    UIViewController *root=session.root;
    void (^finish)(void)=session.finish; session.finish=nil;
    // Never dismiss another owner's controller. Keep stale transition ownership
    // until UIKit completes; a new tap naturally retries after the transition.
    if(root && p.presentedViewController==root) {
        void (^dismiss)(void)=^{ if(WCCRouteOwnsDismiss(root!=nil,p.presentedViewController==root,root.isBeingDismissed))[root dismissViewControllerAnimated:NO completion:nil]; };
        if(root.isBeingPresented && root.transitionCoordinator) {
            if(![root.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> c){dismiss();}])dismiss();
        } else if(!root.isBeingDismissed) dismiss();
    }
    if(finish)finish();
}

@end
static WCCSettingsSession *begin(UIViewController *p,void (^done)(void)) {
 WCCSettingsSession *s=[WCCSettingsSession new];s.finish=WCCOnce(done);objc_setAssociatedObject(p,&WCCSettingsSessionKey,s,OBJC_ASSOCIATION_RETAIN_NONATOMIC);return s;
}
int main(void){@autoreleasepool{
 UIViewController *p=[UIViewController new];p.isViewLoaded=YES;p.view=[UIView new];p.view.window=[NSObject new];
 __block int finished=0,returns=0;
 for(int n=0;n<1000;n++){
  WCCSettingsSession *s=begin(p,^{finished++;});WCCShow(p,[UIViewController new],^{assert(0);});
  assert(p.presentedViewController==s.root);void (^late)(void)=WCCReturn(p,^{returns++;});
  [WCCSettings cancelFrom:p];[WCCSettings cancelFrom:p];late();assert(s.ended&&!p.presentedViewController);
 }
 assert(finished==1000&&returns==0);
 WCCSettingsSession *s=begin(p,^{finished++;});UIViewController *root=[UIViewController new];WCCShow(p,root,nil);
 root.isBeingPresented=YES;root.transitionCoordinator=[Coordinator new];[WCCSettings cancelFrom:p];assert(p.presentedViewController==root&&s.ended);
 root.isBeingPresented=NO;root.transitionCoordinator.pending(nil);assert(!p.presentedViewController);
 s=begin(p,^{finished++;});root=[UIViewController new];WCCShow(p,root,nil);UIViewController *other=[UIViewController new];p.presentedViewController=other;[WCCSettings cancelFrom:p];assert(p.presentedViewController==other);p.presentedViewController=nil;
 s=begin(p,^{finished++;});void (^late)(void)=WCCReturn(p,^{returns++;});begin(p,nil);late();assert(returns==0);
 __block int rejected=0;for(int n=0;n<6;n++){
  p.isViewLoaded=YES;p.view.window=[NSObject new];p.isBeingPresented=NO;p.isBeingDismissed=NO;p.transitionCoordinator=nil;p.presentedViewController=nil;begin(p,nil);
  if(n==0)p.isViewLoaded=NO;if(n==1)p.view.window=nil;if(n==2)p.isBeingPresented=YES;if(n==3)p.isBeingDismissed=YES;if(n==4)p.transitionCoordinator=[Coordinator new];if(n==5)p.presentedViewController=[UIViewController new];
  WCCShow(p,[UIViewController new],^{rejected++;});
 }assert(rejected==6);
 puts("PASS124 extracted production WCCShow/Once/Return/cancel: 1000 reopen, late callback, transition deferral, unrelated VC, six entry guards. Foundation stubs NOT UIKit runtime.");
}return 0;}
