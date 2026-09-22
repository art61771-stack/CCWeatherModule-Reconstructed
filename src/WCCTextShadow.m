#import "WCCTextShadow.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
@interface WCCTextShadowState : NSObject
@property(nonatomic,strong) UIColor *labelColor;
@property(nonatomic) CGSize labelOffset;
@property(nonatomic,strong) UIColor *layerColor;
@property(nonatomic) CGSize layerOffset;
@property(nonatomic) float opacity;
@property(nonatomic) CGFloat radius;
@property(nonatomic) BOOL masks;
@property(nonatomic,strong) id path;
@property(nonatomic) BOOL glowEnabled;
@property(nonatomic) CGFloat glowRadius;
@end
@implementation WCCTextShadowState @end
static char WCCTextShadowKey;
void WCCApplyTextShadow(UILabel *label, BOOL enabled, int group, CGFloat glowRadius) {
    if(!label)return;
    CALayer *layer=label.layer;
    WCCTextShadowState *state=objc_getAssociatedObject(label,&WCCTextShadowKey);
    if(!enabled && !state)return; // Default-off is a true no-op.
    [CATransaction begin];[CATransaction setDisableActions:YES];
    if(enabled) {
        if(!state) {
            state=[WCCTextShadowState new];state.labelColor=label.shadowColor;state.labelOffset=label.shadowOffset;
            state.layerColor=layer.shadowColor?[UIColor colorWithCGColor:layer.shadowColor]:nil;
            state.layerOffset=layer.shadowOffset;state.opacity=layer.shadowOpacity;state.radius=layer.shadowRadius;
            state.masks=layer.masksToBounds;state.path=(__bridge id)layer.shadowPath;state.glowRadius=glowRadius;state.glowEnabled=glowRadius>0;
            objc_setAssociatedObject(label,&WCCTextShadowKey,state,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        // Resolve the current trait collection now: a CGColor cannot be dynamic.
        UIColor *text=[(label.textColor?:UIColor.whiteColor) resolvedColorWithTraitCollection:label.traitCollection];
        CGFloat r=1,g=1,b=1,a=1,w=1;
        if(![text getRed:&r green:&g blue:&b alpha:&a] && [text getWhite:&w alpha:&a])r=g=b=w;
        UIColor *contrast=(r*.2126+g*.7152+b*.0722)>.5?UIColor.blackColor:UIColor.whiteColor;
        // Clear UILabel's legacy shadow so glyphs are not shadowed twice.
        label.shadowColor=nil;label.shadowOffset=CGSizeZero;
        layer.masksToBounds=NO;layer.shadowPath=NULL;
        layer.shadowColor=contrast.CGColor;layer.shadowOffset=CGSizeMake(0,1);
        layer.shadowRadius=1.25;layer.shadowOpacity=.9;
    } else {
        label.shadowColor=state.labelColor;label.shadowOffset=state.labelOffset;
        layer.shadowColor=state.layerColor.CGColor;layer.shadowOffset=state.layerOffset;
        layer.shadowOpacity=state.opacity;layer.shadowRadius=state.radius;
        layer.shadowPath=(__bridge CGPathRef)state.path;layer.masksToBounds=state.masks;
        objc_setAssociatedObject(label,&WCCTextShadowKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [CATransaction commit];
}
