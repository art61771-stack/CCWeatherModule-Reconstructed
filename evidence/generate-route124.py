from pathlib import Path
p=Path(__file__).resolve().parents[1]
s=(p/'src/WCCSettings.m').read_text()
helper=s[s.index('// One owner-local'):s.index('static void WCCSave')]
helper+=s[s.index('static void (^WCCOnce'):s.index('@interface WCCSettingsGallery')]
cancel=s[s.index('+ (void)cancelFrom:'):s.index('+ (void)presentFrom:')]
base=r'''#import <Foundation/Foundation.h>
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
// HELPERS
@interface WCCSettings : NSObject
+ (void)cancelFrom:(UIViewController *)p;
@end
@implementation WCCSettings
// CANCEL
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
'''
(p/'evidence/route124-generated.m').write_text(base.replace('// HELPERS',helper).replace('// CANCEL',cancel))
print('Generated extracted production route124 Foundation test')
