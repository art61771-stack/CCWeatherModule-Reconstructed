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
// INSERT_HELPERS
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
// INSERT_ENTRY
@end
@interface Page : UIViewController
@property(nonatomic,copy) void (^onDone)(void);
- (void)done;
@end
@implementation Page
// INSERT_DONE
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
