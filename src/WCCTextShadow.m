#import "WCCTextShadow.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "WCCRefreshPolicy.h"
@interface WCCTextShadowState : NSObject
@property(nonatomic,strong) UIColor *labelColor;
@property(nonatomic) CGSize labelOffset;
@property(nonatomic,strong) UIColor *layerColor;
@property(nonatomic) CGSize layerOffset;
@property(nonatomic) float opacity;
@property(nonatomic) CGFloat radius;
@property(nonatomic) BOOL masks;
@property(nonatomic,strong) id path;
@end
@implementation WCCTextShadowState @end
static char WCCTextShadowKey;
void WCCApplyTextShadow(UILabel *label, BOOL enabled) { WCCApplyTextEffects(label,enabled,NO); }
void WCCApplyTextEffects(UILabel *label, BOOL shadow, BOOL glow) {
    BOOL enabled=shadow || glow;
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
            state.masks=layer.masksToBounds;state.path=(__bridge id)layer.shadowPath;
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
        if(glow) {
            // A real glyph-alpha halo, not a title-only option. Glow takes
            // precedence when both are on; shadow returns when glow is off.
            layer.shadowColor=text.CGColor;layer.shadowOffset=CGSizeZero;
            layer.shadowRadius=6;layer.shadowOpacity=1;
        }
    } else {
        label.shadowColor=state.labelColor;label.shadowOffset=state.labelOffset;
        layer.shadowColor=state.layerColor.CGColor;layer.shadowOffset=state.layerOffset;
        layer.shadowOpacity=state.opacity;layer.shadowRadius=state.radius;
        layer.shadowPath=(__bridge CGPathRef)state.path;layer.masksToBounds=state.masks;
        objc_setAssociatedObject(label,&WCCTextShadowKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [CATransaction commit];
}

void WCCApplyConfiguredTextEffects(UILabel *label,BOOL shadow,BOOL glow,NSArray *settings,BOOL active) {
    NSCAssert(NSThread.isMainThread,@"UIKit main thread");
    if(!label)return;
    NSString *key=@"wcc.text.shadowOpacity.breathe124";
    WCCApplyTextEffects(label,shadow,glow);
    NSArray *rgba=settings[0];
    if((shadow || glow) && rgba.count==4) {
        [CATransaction begin];[CATransaction setDisableActions:YES];
        label.layer.shadowColor=[UIColor colorWithRed:[rgba[0] doubleValue] green:[rgba[1] doubleValue] blue:[rgba[2] doubleValue] alpha:[rgba[3] doubleValue]].CGColor;
        [CATransaction commit];
    }
    double standard=WCCEffectStandardOpacity124;
    double high=WCCEffectOpacity(standard,settings.count>3?[settings[3] doubleValue]:0);
    double low=WCCEffectLow(high,standard);
    if(shadow || glow){[CATransaction begin];[CATransaction setDisableActions:YES];label.layer.shadowOpacity=high;[CATransaction commit];}
    BOOL running=active && (shadow || glow) && [settings[1] boolValue];
    CABasicAnimation *old=(CABasicAnimation *)[label.layer animationForKey:key];
    double duration=WCCBreathDuration([settings[2] doubleValue])/2;
    if(!running) { [label.layer removeAnimationForKey:key];return; }
    if(old && fabs(old.duration-duration)<.001 && [old.toValue floatValue]==label.layer.shadowOpacity && fabs([old.fromValue doubleValue]-low)<.001)return;
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    animation.fromValue=@(low);animation.toValue=@(label.layer.shadowOpacity);
    animation.duration=duration;animation.autoreverses=YES;animation.repeatCount=HUGE_VALF;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [label.layer addAnimation:animation forKey:key];
}

// Main image view ONLY. Its native contents and custom media subtree share one
// transform; no shadow on header or hourly media. Video is explicitly a box.
static char WCCIconEffectKey;
void WCCApplyMainIconEffects(UIView *icon,BOOL shadow,BOOL glow,NSArray *settings,BOOL active,BOOL video) {
    NSCAssert(NSThread.isMainThread,@"UIKit main thread");if(!icon)return;
    CALayer *layer=icon.layer;NSString *key=@"wcc.icon.shadowOpacity.breathe124";
    WCCTextShadowState *state=objc_getAssociatedObject(icon,&WCCIconEffectKey);
    BOOL enabled=shadow||glow;
    if(!enabled && !state)return;
    [CATransaction begin];[CATransaction setDisableActions:YES];
    if(enabled) {
        if(!state){state=[WCCTextShadowState new];state.layerColor=layer.shadowColor?[UIColor colorWithCGColor:layer.shadowColor]:nil;state.layerOffset=layer.shadowOffset;state.opacity=layer.shadowOpacity;state.radius=layer.shadowRadius;state.masks=layer.masksToBounds;state.path=(__bridge id)layer.shadowPath;objc_setAssociatedObject(icon,&WCCIconEffectKey,state,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
        NSArray *c=settings[0];UIColor *color=c.count==4?[UIColor colorWithRed:[c[0] doubleValue] green:[c[1] doubleValue] blue:[c[2] doubleValue] alpha:[c[3] doubleValue]]:glow?UIColor.whiteColor:UIColor.blackColor;
        layer.masksToBounds=NO;layer.shadowColor=color.CGColor;layer.shadowOffset=glow?CGSizeZero:CGSizeMake(0,1);
        layer.shadowRadius=glow?6:1.25;layer.shadowOpacity=WCCEffectOpacity(WCCEffectStandardOpacity124,settings.count>3?[settings[3] doubleValue]:0);
        // AVPlayerLayer cannot promise alpha-based subject segmentation.
        layer.shadowPath=video?[UIBezierPath bezierPathWithRect:icon.bounds].CGPath:NULL;
    } else {
        layer.shadowColor=state.layerColor.CGColor;layer.shadowOffset=state.layerOffset;layer.shadowOpacity=state.opacity;layer.shadowRadius=state.radius;layer.masksToBounds=state.masks;layer.shadowPath=(__bridge CGPathRef)state.path;
        objc_setAssociatedObject(icon,&WCCIconEffectKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [CATransaction commit];
    if(!enabled || !active || ![settings[1] boolValue]){[layer removeAnimationForKey:key];return;}
    double duration=WCCBreathDuration([settings[2] doubleValue])/2;
    double low=WCCEffectLow(layer.shadowOpacity,WCCEffectStandardOpacity124);
    CABasicAnimation *old=(CABasicAnimation *)[layer animationForKey:key];
    if(old && fabs(old.duration-duration)<.001 && [old.toValue floatValue]==layer.shadowOpacity && fabs([old.fromValue doubleValue]-low)<.001)return;
    CABasicAnimation *a=[CABasicAnimation animationWithKeyPath:@"shadowOpacity"];a.fromValue=@(low);a.toValue=@(layer.shadowOpacity);a.duration=duration;a.autoreverses=YES;a.repeatCount=HUGE_VALF;a.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];[layer addAnimation:a forKey:key];
}
