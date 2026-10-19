#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "../src/WCCRuntime.h"
@interface UIView1215 : NSObject
@property CGRect bounds; @property CGPoint center; @property CGAffineTransform transform; @property(strong) CALayer *layer;
@end
@implementation UIView1215
- (instancetype)init{if((self=[super init]))_layer=[CALayer layer];return self;}
- (void)install:(WCCMainIconLayout)layout {
 self.transform=CGAffineTransformIdentity;self.bounds=CGRectMake(0,0,layout.baseline.w,layout.baseline.h);
 self.center=CGPointMake(layout.centerX,layout.centerY);self.transform=CGAffineTransformMakeScale(layout.scaleX,layout.scaleY);
 self.layer.bounds=self.bounds;self.layer.position=self.center;self.layer.affineTransform=self.transform;
}
- (CGRect)actualVisibleRect {
 CGRect b=self.layer.bounds;CGPoint p=self.layer.position;CGAffineTransform t=self.layer.affineTransform;
 CGPoint q[4]={{0,0},{b.size.width,0},{0,b.size.height},{b.size.width,b.size.height}};
 CGFloat minx=INFINITY,miny=INFINITY,maxx=-INFINITY,maxy=-INFINITY;
 for(int i=0;i<4;i++){CGPoint v=CGPointApplyAffineTransform(q[i],t);v.x+=p.x-b.size.width*t.a/2;v.y+=p.y-b.size.height*t.d/2;minx=MIN(minx,v.x);miny=MIN(miny,v.y);maxx=MAX(maxx,v.x);maxy=MAX(maxy,v.y);}
 return CGRectMake(minx,miny,maxx-minx,maxy-miny);
}
@end
static BOOL near(CGFloat a,CGFloat b){return fabs(a-b)<1e-7;}
int main(void){@autoreleasepool{
 UIView1215 *parent=[UIView1215 new];CALayer *content=[CALayer layer];[parent.layer addSublayer:content];
 NSArray *collapsed=@[@50,@100,@150,@200,@250],*expanded=@[@50,@100,@150];
 CGRect first=CGRectNull;
 for(int media=0;media<5;media++)for(int animation=0;animation<2;animation++)for(int order=0;order<6;order++)for(int pass=0;pass<100;pass++){
  WCCMainIconLayout c=WCCMainIconLayoutForBaseline(WCCR(14,8,60,60),320,76,0,3,1,31,-22,[collapsed[(pass+media)%5] doubleValue]);
  [parent install:c];content.bounds=parent.bounds;content.position=CGPointMake(30,30);
  if(animation)[content addAnimation:[CABasicAnimation animationWithKeyPath:@"transform.scale"] forKey:@"wcc.icon.transform.scale125"];
  CGRect actual=parent.actualVisibleRect;WCCRect expected=WCCMainIconVisibleRect(c);
  NSCAssert(near(actual.origin.x,expected.x)&&near(actual.origin.y,expected.y)&&near(actual.size.width,expected.w)&&near(actual.size.height,expected.h),@"actual QuartzCore matrix must match target");
  WCCMainIconLayout e=WCCMainIconLayoutForBaseline(WCCR(16,15,55,55),320,85,1,3,2,31,-22,[expanded[pass%3] doubleValue]);
  NSCAssert(near(e.centerX,WCCMainIconLayoutForBaseline(WCCR(16,15,55,55),320,85,1,3,2,0,0,[expanded[pass%3] doubleValue]).centerX),@"expanded excludes collapsed offset");
  WCCMainIconLayout back=WCCMainIconLayoutForBaseline(WCCR(14,8,60,60),320,76,0,3,1,31,-22,[collapsed[(pass+media)%5] doubleValue]);[parent install:back];
  if(pass==0)first=parent.actualVisibleRect;
  if(pass%100==0)NSCAssert(CGRectEqualToRect(first,parent.actualVisibleRect),@"same settings return exactly");
  (void)order;
 }
 puts("PASS1215 Apple QuartzCore stub: actual affine corners, content scale animation isolation, five media classes, callback orders and 100 presentations");
}return 0;}
