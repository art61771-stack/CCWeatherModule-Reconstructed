#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "../src/WCCRuntime.h"
@interface UILabel : NSObject
@property CGRect frame; @property NSInteger textAlignment; @property(copy) NSString *text;
@property NSInteger numberOfLines; @property BOOL adjustsFontSizeToFitWidth; @property double minimumScaleFactor; @property NSInteger lineBreakMode;
@end
@implementation UILabel @end
static BOOL near(double a,double b){return fabs(a-b)<1e-7;}
static WCCRect actualVisible(UILabel *label,double measured,double measuredHeight){
 int alignment=label.textAlignment==2?2:label.textAlignment==1?1:0;
 return WCCGreetingVisibleBounds(WCCR(label.frame.origin.x,label.frame.origin.y,label.frame.size.width,label.frame.size.height),measured,measuredHeight,alignment);
}
int main(void){@autoreleasepool{
 UILabel *label=[UILabel new]; label.textAlignment=0; label.lineBreakMode=4;
 NSArray *texts=@[@"早安",@"你好，愿你今天顺心",@"很长很长会在右侧截断或缩放但实际可见文字左缘不能移动的随机问候语"];
 NSArray *widths=@[@24,@112,@400];
 WCCRect legacy=WCCR(36,30,204,18),d=WCCGreetingTranslation(legacy,320,76,49,13);
 label.frame=CGRectMake(legacy.x+d.x,legacy.y+d.y,legacy.w,legacy.h);label.textAlignment=2;
 WCCRect oldA=actualVisible(label,24,12),oldB=actualVisible(label,112,12);
 NSCAssert(!near(oldA.x,oldB.x),@"must reproduce 1.2.8 positive-X right-anchor drift");
 for(NSNumber *moduleWidth in @[@156,@220,@290,@320,@440]) for(NSNumber *request in @[@(-1366),@(-49),@(-1),@(-.49),@0,@.49,@1,@49,@1366]){
  double width=moduleWidth.doubleValue;
  WCCRect rail=WCCGreetingRail(WCCR(MIN(36,width),30,MAX(0,width-MIN(36,width)),18),width,76,request.doubleValue,13);
  label.frame=CGRectMake(rail.x,rail.y,rail.w,rail.h); label.textAlignment=0;
  for(int fit=0;fit<2;fit++) for(int lines=1;lines<=2;lines++){
   label.adjustsFontSizeToFitWidth=fit;label.minimumScaleFactor=fit?.5:1;label.numberOfLines=lines;
   for(int pass=0;pass<100;pass++){NSUInteger i=pass%texts.count;label.text=texts[i];
    WCCRect visible=actualVisible(label,[widths[i] doubleValue],lines==2?18:12);
    NSCAssert(near(visible.x,rail.x),@"actual visible left must equal configured rail origin");
    NSCAssert(near(visible.y,rail.y),@"visible top must not move with line count");
   }
  }
 }
 NSCAssert(label.textAlignment==0,@"production label must remain left aligned");
 puts("PASS1214 Apple UILabel stub: actual visible left fixed for positive/zero/negative/extreme X, five sizes, 100 random swaps, 1/2 lines, fitting and truncation");
}return 0;}
