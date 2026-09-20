#import "WCCHostObserver.h"
#import "WCCABI.h"
#import "WCCPreferences.h"
static NSMutableDictionary *diagnosticCounts, *diagnosticABI;
static BOOL diagnosticsEnabled(void) { return [WCCPrefs() boolForKey:@"hostDiagnostics"]; }
void WCCDiagnosticCount(NSString *name) {
    if (!NSThread.isMainThread || !diagnosticsEnabled()) return;
    if (!diagnosticCounts) diagnosticCounts=[NSMutableDictionary dictionary];
    diagnosticCounts[name]=@([diagnosticCounts[name] unsignedLongLongValue]+1);
}
static void diagnosticValue(NSString *name,id value) {
    if (!NSThread.isMainThread || !diagnosticsEnabled()) return;
    if (!diagnosticABI) diagnosticABI=[NSMutableDictionary dictionary];
    diagnosticABI[name]=value ?: @"missing";
}
NSString *WCCDiagnosticExport(void) {
    if (!NSThread.isMainThread || !diagnosticsEnabled()) return @"诊断未开启；请开启后关闭/下拉控制中心3次再导出。";
    NSDictionary *report=@{@"version":@"1.1.7",@"scope":@"local aggregate only; iOS16.6 execution must be verified on target",@"counts":diagnosticCounts ?: @{},@"abi":diagnosticABI ?: @{}};
    NSData *data=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
    NSString *text=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *directory=@"/var/mobile/Documents/CCWeatherModule";
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    BOOL saved=[data writeToFile:[directory stringByAppendingPathComponent:@"host-diagnostics-117.json"] atomically:YES];
    return [NSString stringWithFormat:@"%@\n\n%@",saved?@"已写入 /var/mobile/Documents/CCWeatherModule/host-diagnostics-117.json":@"文件写入失败；以下聚合数据仍可复制",text ?: @"导出失败"];
}
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
    Method m=class_getInstanceMethod(cls,sel);
    diagnosticValue(NSStringFromSelector(sel),m ? [NSString stringWithUTF8String:method_getTypeEncoding(m)] : @"missing");
    if(!m) return NO;
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
    WCCDiagnosticCount(e==WCCHostBegin?@"host.begin":e==WCCHostPresented?@"host.endPresentation":@"host.endDismissal");
    diagnosticValue(@"lastActiveGate",@(visible));
    if(!WCCConsumeHostEvent(&state,e,visible)) { WCCDiagnosticCount(@"host.coalesced"); return; }
    WCCDiagnosticCount(@"host.edge");
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
    [modules addObject:module];
    Class cls=NSClassFromString(@"CCUIModularControlCenterOverlayViewController");
    WCCDiagnosticCount(@"module.observe");
    diagnosticValue(@"hostClassExists",@(cls!=Nil)); diagnosticValue(@"installed",@(installed));
    diagnosticValue(@"installCount",@(installed?1:0));
    // Enabling after installation still captures the concrete runtime encodings.
    if (diagnosticsEnabled()) {
        for (NSString *name in @[@"_beginPresentationAnimated:interactive:",@"_endPresentationWithUUID:",@"_endDismissalWithUUID:animated:",@"_endPresentationWithUUID:success:",@"_endDismissalWithUUID:animated:success:",@"isActive"]) {
            Method m=class_getInstanceMethod(cls,NSSelectorFromString(name));
            diagnosticValue(name,m?[NSString stringWithUTF8String:method_getTypeEncoding(m)]:@"missing");
        }
        NSMutableArray *ancestry=[NSMutableArray array];
        for (UIViewController *p=module.parentViewController;p && ancestry.count<12;p=p.parentViewController) [ancestry addObject:NSStringFromClass(p.class)];
        diagnosticValue(@"moduleParentClasses",ancestry);
    }
    if(installed) {
        // A module can register before UIKit attaches its parent. Retrying the
        // same ancestry-only bootstrap later fixes that proven registration race;
        // it does NOT assert that this is the user's missing downstream event.
        if(!notifying && !state.visible) for(UIViewController *p=module.parentViewController;p;p=p.parentViewController)
            if([p isKindOfClass:cls]) { if(active(p)) event(p,WCCHostPresented,YES); break; }
        return;
    }
    // All methods checked BEFORE modifying any IMP. Evidence: CCDynamic local source.
    const char *b=@encode(BOOL); NSString *bt=[NSString stringWithUTF8String:b];
    if(!signature(cls,NSSelectorFromString(@"_beginPresentationAnimated:interactive:"),"@",@[bt,bt])) { diagnosticValue(@"installReason",cls?@"begin ABI mismatch":@"host class missing"); WCCDiagnosticCount(@"install.rejected"); return; }
    BOOL getter=signature(cls,NSSelectorFromString(@"isActive"),"B",@[])||signature(cls,NSSelectorFromString(@"isActive"),"c",@[]);
    BOOL modern=getter && signature(cls,NSSelectorFromString(@"_endPresentationWithUUID:"),"v",@[@"@"]) && signature(cls,NSSelectorFromString(@"_endDismissalWithUUID:animated:"),"v",@[@"@",bt]);
    BOOL legacy=signature(cls,NSSelectorFromString(@"_endPresentationWithUUID:success:"),"v",@[@"@",bt]) && signature(cls,NSSelectorFromString(@"_endDismissalWithUUID:animated:success:"),"v",@[@"@",bt,bt]);
    if(!modern&&!legacy) { diagnosticValue(@"installReason",@"end/getter ABI unsupported"); WCCDiagnosticCount(@"install.rejected"); return; }
    replace(cls,@"_beginPresentationAnimated:interactive:",(IMP)begin,&beginOriginal);
    if(modern) {
        replace(cls,@"_endPresentationWithUUID:",(IMP)present,&presentOriginal);
        replace(cls,@"_endDismissalWithUUID:animated:",(IMP)dismiss,&dismissOriginal);
    } else {
        replace(cls,@"_endPresentationWithUUID:success:",(IMP)presentOld,&presentOldOriginal);
        replace(cls,@"_endDismissalWithUUID:animated:success:",(IMP)dismissOld,&dismissOldOriginal);
    }
    installed=YES; WCCDiagnosticCount(@"install.success");
    diagnosticValue(@"installed",@YES); diagnosticValue(@"installCount",@1);
    diagnosticValue(@"installReason",modern?@"modern installed":@"legacy installed");
    // Bootstrap only from this module's actual host ancestry, not window attachment.
    for(UIViewController *p=module.parentViewController;p;p=p.parentViewController)
        if([p isKindOfClass:cls] && getter) { event(p,WCCHostPresented,active(p)); break; }
}
