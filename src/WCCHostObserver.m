#import "WCCHostObserver.h"
#import "WCCABI.h"
#import <objc/runtime.h>
#import <objc/message.h>
#include <string.h>
#include <stdbool.h>
NSString *const WCCHostVisibilityChanged=@"WCCWeatherHostVisibilityChanged115";
static WCCHostState state;
static NSHashTable *modules;
static BOOL installed;
static BOOL notifying;
WCCHostState WCCCurrentHostState(void) { return state; }
static BOOL signature(Class cls,SEL sel,const char *result,NSArray *args) {
    Method m=class_getInstanceMethod(cls,sel); if(!m) return NO;
    NSMethodSignature *s=[NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(m)];
    if(s.numberOfArguments>5 || args.count>3) return NO;
    const char *actual[5]={0}, *expected[3]={0};
    for(NSUInteger i=0;i<s.numberOfArguments;i++) actual[i]=[s getArgumentTypeAtIndex:i];
    for(NSUInteger i=0;i<args.count;i++) expected[i]=[args[i] UTF8String];
    return WCCABICompatible(s.methodReturnType,result,s.numberOfArguments,actual,args.count,expected);
}
static BOOL active(id host) {
    SEL sel=NSSelectorFromString(@"isActive");
    if(signature(object_getClass(host),sel,"B",@[])) return ((bool(*)(id,SEL))objc_msgSend)(host,sel);
    if(signature(object_getClass(host),sel,"c",@[])) return ((signed char(*)(id,SEL))objc_msgSend)(host,sel)!=0;
    return NO;
}
static void event(id host,WCCHostEvent e,BOOL visible) {
    if(!NSThread.isMainThread) return; // UIKit lifecycle must be main-thread.
    if(!WCCConsumeHostEvent(&state,e,visible)) return;
    // A synchronous module callback must not bootstrap a dismissed host while
    // its original implementation is still unwinding. Snapshot weak modules.
    BOOL previous=notifying; notifying=YES;
    @try {
        for(UIViewController *module in modules.allObjects)
            [NSNotificationCenter.defaultCenter postNotificationName:WCCHostVisibilityChanged object:module];
    } @finally { notifying=previous; }
}
static IMP beginOriginal, presentOriginal, dismissOriginal, presentOldOriginal, dismissOldOriginal;
static id begin(id o,SEL s,BOOL a,BOOL i) { event(o,WCCHostBegin,YES); return ((id(*)(id,SEL,BOOL,BOOL))beginOriginal)(o,s,a,i); }
static void present(id o,SEL s,id u) { ((void(*)(id,SEL,id))presentOriginal)(o,s,u); if(NSThread.isMainThread) event(o,WCCHostPresented,active(o)); }
static void dismiss(id o,SEL s,id u,BOOL a) { ((void(*)(id,SEL,id,BOOL))dismissOriginal)(o,s,u,a); if(NSThread.isMainThread) event(o,WCCHostDismissed,active(o)); }
static void presentOld(id o,SEL s,id u,BOOL ok) { ((void(*)(id,SEL,id,BOOL))presentOldOriginal)(o,s,u,ok); event(o,WCCHostPresented,ok); }
static void dismissOld(id o,SEL s,id u,BOOL a,BOOL ok) { ((void(*)(id,SEL,id,BOOL,BOOL))dismissOldOriginal)(o,s,u,a,ok); event(o,WCCHostDismissed,!ok); }
static void replace(Class cls,NSString *name,IMP imp,IMP *original) {
    SEL sel=NSSelectorFromString(name); Method m=class_getInstanceMethod(cls,sel);
    // Publish the per-selector original before making the wrapper reachable.
    // Installation is serialized on the UIKit main thread and performed once.
    *original=method_getImplementation(m);
    if(!class_addMethod(cls,sel,imp,method_getTypeEncoding(m)))
        method_setImplementation(class_getInstanceMethod(cls,sel),imp);
}
void WCCObserveHostForModule(UIViewController *module) {
    if(!NSThread.isMainThread) return;
    if(!module) return;
    if(!modules) modules=[NSHashTable weakObjectsHashTable];
    BOOL newlyRegistered=![modules containsObject:module];
    [modules addObject:module];
    Class cls=NSClassFromString(@"CCUIModularControlCenterOverlayViewController");
    if(installed) {
        if(newlyRegistered && !notifying && !state.visible) for(UIViewController *p=module.parentViewController;p;p=p.parentViewController)
            if([p isKindOfClass:cls]) { if(active(p)) event(p,WCCHostPresented,YES); break; }
        return;
    }
    // All methods checked BEFORE modifying any IMP. Evidence: CCDynamic local source.
    const char *b=@encode(BOOL); NSString *bt=[NSString stringWithUTF8String:b];
    if(!signature(cls,NSSelectorFromString(@"_beginPresentationAnimated:interactive:"),"@",@[bt,bt])) return;
    BOOL getter=signature(cls,NSSelectorFromString(@"isActive"),"B",@[])||signature(cls,NSSelectorFromString(@"isActive"),"c",@[]);
    BOOL modern=getter && signature(cls,NSSelectorFromString(@"_endPresentationWithUUID:"),"v",@[@"@"]) && signature(cls,NSSelectorFromString(@"_endDismissalWithUUID:animated:"),"v",@[@"@",bt]);
    BOOL legacy=signature(cls,NSSelectorFromString(@"_endPresentationWithUUID:success:"),"v",@[@"@",bt]) && signature(cls,NSSelectorFromString(@"_endDismissalWithUUID:animated:success:"),"v",@[@"@",bt,bt]);
    if(!modern&&!legacy) { NSLog(@"[WCC115] host ABI unsupported; no hooks installed"); return; }
    replace(cls,@"_beginPresentationAnimated:interactive:",(IMP)begin,&beginOriginal);
    if(modern) {
        replace(cls,@"_endPresentationWithUUID:",(IMP)present,&presentOriginal);
        replace(cls,@"_endDismissalWithUUID:animated:",(IMP)dismiss,&dismissOriginal);
    } else {
        replace(cls,@"_endPresentationWithUUID:success:",(IMP)presentOld,&presentOldOriginal);
        replace(cls,@"_endDismissalWithUUID:animated:success:",(IMP)dismissOld,&dismissOldOriginal);
    }
    installed=YES;
    // Bootstrap only from this module's actual host ancestry, not window attachment.
    for(UIViewController *p=module.parentViewController;p;p=p.parentViewController)
        if([p isKindOfClass:cls] && getter) { event(p,WCCHostPresented,active(p)); break; }
}
