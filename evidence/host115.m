#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>
#import "../src/WCCHostObserver.m"
#include <assert.h>
#include <stdio.h>
// Test-only preferences: production diagnostics remain opt-in.
NSUserDefaults *WCCPrefs(void) { return NSUserDefaults.standardUserDefaults; }
@implementation UIViewController
@end
static int begins, presents, dismisses, notices, beforeCalls, afterCalls;
static BOOL live, lastA, lastI;
static id marker;
static IMP beforeOriginal, afterOriginal;
static id hostBegin(id o,SEL s,BOOL a,BOOL i) { begins++;lastA=a;lastI=i;live=YES;return marker; }
static void hostPresent(id o,SEL s,id uuid) { assert(uuid==marker); presents++; }
static void hostDismiss(id o,SEL s,id uuid,BOOL a) { assert(uuid==marker);dismisses++;lastA=a;live=NO; }
static void hostPresentOld(id o,SEL s,id uuid,BOOL ok) { hostPresent(o,s,uuid);live=ok; }
static void hostDismissOld(id o,SEL s,id uuid,BOOL a,BOOL ok) { assert(uuid==marker);dismisses++;lastA=a;live=!ok; }
static bool getterB(id o,SEL s) { return live; }
static signed char getterC(id o,SEL s) { return live?1:0; }
static id before(id o,SEL s,BOOL a,BOOL i) { beforeCalls++;return ((id(*)(id,SEL,BOOL,BOOL))beforeOriginal)(o,s,a,i); }
static id after(id o,SEL s,BOOL a,BOOL i) { afterCalls++;return ((id(*)(id,SEL,BOOL,BOOL))afterOriginal)(o,s,a,i); }
static SEL bs,ps,ds;
static BOOL oldMode;
static void endPresent(id h,BOOL ok) {
 if(oldMode) ((void(*)(id,SEL,id,BOOL))objc_msgSend)(h,ps,marker,ok);
 else {live=ok;((void(*)(id,SEL,id))objc_msgSend)(h,ps,marker);}
}
static void endDismiss(id h,BOOL ok) {
 if(oldMode) ((void(*)(id,SEL,id,BOOL,BOOL))objc_msgSend)(h,ds,marker,YES,ok);
 else if(ok) ((void(*)(id,SEL,id,BOOL))objc_msgSend)(h,ds,marker,YES);
 else {live=YES;event(h,WCCHostDismissed,YES);}
}
static id start(id h) { return ((id(*)(id,SEL,BOOL,BOOL))objc_msgSend)(h,bs,YES,NO); }
int main(int argc,char **argv) { @autoreleasepool {
 assert(NSThread.isMainThread);assert(argc==2);
 NSString *mode=@(argv[1]);oldMode=[mode isEqual:@"legacy"];
 BOOL inherited=[mode isEqual:@"inherited"], reject=[mode hasPrefix:@"reject"], missing=[mode isEqual:@"reject-missing"];
 bs=NSSelectorFromString(@"_beginPresentationAnimated:interactive:");
 ps=NSSelectorFromString(oldMode?@"_endPresentationWithUUID:success:":@"_endPresentationWithUUID:");
 ds=NSSelectorFromString(oldMode?@"_endDismissalWithUUID:animated:success:":@"_endDismissalWithUUID:animated:");
 Class parent=objc_allocateClassPair(UIViewController.class,"WCCMockParent115",0);objc_registerClassPair(parent);
 Class cls=objc_allocateClassPair(parent,"CCUIModularControlCenterOverlayViewController",0);
 Class target=inherited?parent:cls;
 NSString *b=@(@encode(BOOL));
 NSString *beginType=[NSString stringWithFormat:@"@@:%@%@",b,b];
 if([mode isEqual:@"reject-bool"]) beginType=[NSString stringWithFormat:@"@@:%s%@",strcmp(@encode(BOOL),"B")?"B":"c",b];
 if([mode isEqual:@"reject-return"]) beginType=[NSString stringWithFormat:@"v@:%@%@",b,b];
 if([mode isEqual:@"reject-argc"]) beginType=[NSString stringWithFormat:@"@@:%@",b];
 class_addMethod(target,bs,(IMP)hostBegin,beginType.UTF8String);
 class_addMethod(target,ps,oldMode?(IMP)hostPresentOld:(IMP)hostPresent,oldMode?[[@"v@:@" stringByAppendingString:b] UTF8String]:"v@:@");
 NSString *dt=[NSString stringWithFormat:oldMode?@"v@:@%@%@":@"v@:@%@",b,b];
 if(!missing) class_addMethod(target,ds,oldMode?(IMP)hostDismissOld:(IMP)hostDismiss,dt.UTF8String);
 BOOL charGetter=[mode isEqual:@"getter-char"];
 class_addMethod(target,@selector(isActive),charGetter?(IMP)getterC:(IMP)getterB,charGetter?"c@:":"B@:");
 objc_registerClassPair(cls);
 IMP parentBegin=class_getMethodImplementation(parent,bs);
 Method bm=class_getInstanceMethod(cls,bs);
 if(!reject&&!inherited) { beforeOriginal=method_setImplementation(bm,(IMP)before); }
 IMP initial=class_getMethodImplementation(cls,bs);
 UIViewController *host=[cls new], *module=[UIViewController new];module.parentViewController=host;marker=[NSObject new];
 __weak UIViewController *weakModule=module;
 __block int observed=0;
 int notifications=0;
 uint64_t gen=0;
 @autoreleasepool {
 id token=[NSNotificationCenter.defaultCenter addObserverForName:WCCHostVisibilityChanged object:module queue:nil usingBlock:^(NSNotification *n){ assert(NSThread.isMainThread); observed++;notices++;WCCObserveHostForModule(weakModule); }];
 WCCObserveHostForModule(module);
 if(reject) { assert(!installed);assert(class_getMethodImplementation(cls,bs)==initial);assert(!state.generation);puts("PASS production runtime ABI rejection before any replacement");return 0; }
 assert(installed);
 if(inherited) assert(class_getMethodImplementation(parent,bs)==parentBegin);
 IMP hook=class_getMethodImplementation(cls,bs);
 for(int i=0;i<100;i++) WCCObserveHostForModule(module);
 assert(class_getMethodImplementation(cls,bs)==hook);
 afterOriginal=method_setImplementation(class_getInstanceMethod(cls,bs),(IMP)after);
 for(int i=0;i<1000;i++) {
  int n=begins;assert(start(host)==marker);assert(begins==n+1);assert(lastA&&!lastI);
  uint64_t gen=state.generation;assert(gen==(uint64_t)i+1);assert(state.visible);
  endPresent(host,YES);endPresent(host,YES);
  for(int j=0;j<20;j++) WCCObserveHostForModule(module);
  assert(state.generation==gen);endDismiss(host,YES);assert(!state.visible);assert(state.generation==gen);
 }
 assert(begins==1000&&presents==2000&&dismisses==1000);assert(afterCalls==1000);
 if(!inherited) assert(beforeCalls==1000);
 assert(observed==2000);
 assert(start(host)==marker);endPresent(host,NO);assert(!state.visible);
 uint64_t gen=state.generation;assert(start(host)==marker);assert(state.generation==gen+1);
 if(oldMode) {endDismiss(host,NO);assert(state.visible);}
 endDismiss(host,YES);assert(!state.visible);
 // Off-main calls still invoke original once; no notification/state mutation.
 gen=state.generation;notifications=notices;int n=begins;
 dispatch_semaphore_t done=dispatch_semaphore_create(0);
 dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), ^{assert(!NSThread.isMainThread);assert(start(host)==marker);dispatch_semaphore_signal(done);});
 dispatch_semaphore_wait(done,DISPATCH_TIME_FOREVER);
 assert(begins==n+1&&state.generation==gen&&notices==notifications);live=NO;
 [NSNotificationCenter.defaultCenter removeObserver:token];token=nil;
 }
 module=nil;assert(!weakModule);assert(modules.allObjects.count==0);
 // Regression: registration precedes parent attachment while begin already ran.
 // Installing a module bundle late is unlike a process-load substrate tweak.
 UIViewController *late=[UIViewController new];
 WCCObserveHostForModule(late); assert(!state.visible);
 late.parentViewController=host;live=YES;gen=state.generation;
 WCCObserveHostForModule(late);assert(state.visible&&state.generation==gen+1);
 WCCObserveHostForModule(late);assert(state.generation==gen+1);
 endDismiss(host,YES);late=nil;assert(modules.allObjects.count==0);
 start(host);endDismiss(host,YES);assert(notices==notifications);
 if(inherited) { assert(class_getMethodImplementation(parent,bs)==parentBegin);uint64_t g=state.generation;start([parent new]);assert(state.generation==g); }
 printf("PASS production WCCHostObserver.m runtime %s: exact original calls, IMP chain, registration dedup, cancel/retry, weak lifetime, main-thread events\n",argv[1]);
 }return 0;}
