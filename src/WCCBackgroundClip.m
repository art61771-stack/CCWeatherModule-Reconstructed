#import "WCCBackgroundClip.h"
#import <QuartzCore/QuartzCore.h>

static BOOL WCCFiniteRect(CGRect r) {
    return isfinite(r.origin.x)&&isfinite(r.origin.y)&&isfinite(r.size.width)&&isfinite(r.size.height)&&r.size.width>0&&r.size.height>0;
}
static BOOL WCCUsableAncestor(UIView *candidate, UIView *root) {
    if (!candidate || candidate==root || candidate.hidden || candidate.alpha<=0 || !candidate.window) return NO;
    CGRect converted=[candidate convertRect:candidate.bounds toView:root];
    if (!WCCFiniteRect(converted) || !CGRectIntersectsRect(root.bounds,converted)) return NO;
    CGFloat area=converted.size.width*converted.size.height, rootArea=root.bounds.size.width*root.bounds.size.height;
    return rootArea>0 && area>=rootArea*.70 && area<=rootArea*1.35;
}
static CAShapeLayer *WCCShapeMaskInRoot(UIView *host, UIView *root) {
    CAShapeLayer *source=[host.layer.mask isKindOfClass:CAShapeLayer.class]?(CAShapeLayer *)host.layer.mask:nil;
    CGPathRef path=source.path;
    if (!path) return nil;
    CGPoint o=[root.layer convertPoint:CGPointZero fromLayer:source];
    CGPoint x=[root.layer convertPoint:CGPointMake(1,0) fromLayer:source];
    CGPoint y=[root.layer convertPoint:CGPointMake(0,1) fromLayer:source];
    CGAffineTransform t=CGAffineTransformMake(x.x-o.x,x.y-o.y,y.x-o.x,y.y-o.y,o.x,o.y);
    CGPathRef converted=CGPathCreateCopyByTransformingPath(path,&t);
    if (!converted) return nil;
    CAShapeLayer *copy=[CAShapeLayer layer]; copy.frame=root.bounds; copy.path=converted; copy.fillRule=source.fillRule;
    CGPathRelease(converted); return copy;
}
CGFloat WCCBackgroundFallbackRadius(CGSize size) {
    CGFloat edge=MIN(size.width,size.height);
    // Conservative system-module fallback, bounded by current geometry rather than a fixed screenshot value.
    return MAX(0,MIN(edge*.18,edge*.5));
}
WCCBackgroundClipSource WCCUpdateBackgroundClipView(UIView *clipView, UIView *rootView) {
    if (!clipView || !rootView) return WCCBackgroundClipSourceFallback;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    clipView.frame=rootView.bounds; clipView.clipsToBounds=YES; clipView.userInteractionEnabled=NO;
    clipView.layer.mask=nil; clipView.layer.cornerCurve=kCACornerCurveContinuous;
    clipView.layer.cornerRadius=WCCBackgroundFallbackRadius(rootView.bounds.size);
    WCCBackgroundClipSource result=WCCBackgroundClipSourceFallback;
    for (UIView *host=rootView.superview; host && result==WCCBackgroundClipSourceFallback; host=host.superview) {
        if (!WCCUsableAncestor(host,rootView)) continue;
        CAShapeLayer *shape=WCCShapeMaskInRoot(host,rootView);
        if (shape) { clipView.layer.cornerRadius=0; clipView.layer.mask=shape; result=WCCBackgroundClipSourceHostShape; break; }
        CGFloat radius=host.layer.cornerRadius;
        if (isfinite(radius) && radius>0 && (host.clipsToBounds || host.layer.masksToBounds || host.layer.mask)) {
            CGRect hostRect=[host convertRect:host.bounds toView:rootView];
            CGFloat sx=fabs(hostRect.size.width/host.bounds.size.width), sy=fabs(hostRect.size.height/host.bounds.size.height);
            CGFloat scale=MIN(sx,sy); if (!isfinite(scale)||scale<=0) scale=1;
            CGFloat convertedRadius=MIN(radius*scale,MIN(hostRect.size.width,hostRect.size.height)*.5);
            CAShapeLayer *rounded=[CAShapeLayer layer]; rounded.frame=rootView.bounds;
            rounded.path=[UIBezierPath bezierPathWithRoundedRect:hostRect cornerRadius:convertedRadius].CGPath;
            clipView.layer.cornerRadius=0; clipView.layer.mask=rounded;
            result=WCCBackgroundClipSourceHostCorner;
        }
    }
    [clipView setNeedsLayout]; [clipView layoutIfNeeded];
    [CATransaction commit]; return result;
}
BOOL WCCBackgroundPointVisible(UIView *clipView, CGPoint point) {
    if (!CGRectContainsPoint(clipView.bounds,point)) return NO;
    CAShapeLayer *shape=[clipView.layer.mask isKindOfClass:CAShapeLayer.class]?(CAShapeLayer *)clipView.layer.mask:nil;
    if (shape.path) return CGPathContainsPoint(shape.path,NULL,point,shape.fillRule==kCAFillRuleEvenOdd);
    CGFloat r=clipView.layer.cornerRadius;
    return r<=0 || CGPathContainsPoint([UIBezierPath bezierPathWithRoundedRect:clipView.bounds cornerRadius:r].CGPath,NULL,point,false);
}
