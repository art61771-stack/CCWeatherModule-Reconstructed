#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "../src/WCCRuntime.h"
@interface UILabel : NSObject
@property CGRect frame; @property NSInteger textAlignment; @property(copy) NSString *text;
@property NSInteger numberOfLines; @property BOOL adjustsFontSizeToFitWidth; @property NSInteger lineBreakMode;
@end
@implementation UILabel @end
static BOOL near(double a,double b){return fabs(a-b)<1e-7;}
static WCCRect ink(UILabel *l,double measured,double height,WCCRect d){int a=l.textAlignment==2?2:0;return WCCGreetingVisibleBounds(WCCR(l.frame.origin.x+d.x,l.frame.origin.y+d.y,l.frame.size.width,l.frame.size.height),measured,height,a);}
int main(void){@autoreleasepool{
 UILabel *label=[UILabel new]; label.frame=CGRectMake(36,30,204,18); label.numberOfLines=1; label.adjustsFontSizeToFitWidth=NO;
 NSArray *texts=@[@"早安",@"你好，愿你今天顺心",@"很长很长会截断但选定可见锚点不能移动的随机问候语"];
 NSArray *widths=@[@24,@112,@400];
 /* 1.2.7 stub asserted translation only at zero and never compared visible ink. */
 label.textAlignment=2; WCCRect oldA=ink(label,24,12,WCCR(0,0,0,0)),oldB=ink(label,112,12,WCCR(0,0,0,0)); NSCAssert(!near(oldA.x,oldB.x),@"must reproduce 127 screenshot failure");
 for(NSNumber *request in @[@0,@0.49,@(-0.49),@(-1),@1,@1366]){
  double x=request.doubleValue; int a=WCCGreetingVisibleAlignment(x); label.textAlignment=a; WCCRect d=WCCGreetingTranslation(WCCR(36,30,204,18),320,76,x,13);
  for(int pass=0;pass<100;pass++){NSUInteger i=pass%texts.count;label.text=texts[i];WCCRect v=ink(label,[widths[i] doubleValue],pass%2?18:12,d);
   NSCAssert(near(v.x,36+d.x),@"current left visible anchor");
   NSCAssert(near(v.y,30+d.y),@"Y must not follow one/two-line ink");
  }
 }
 NSCAssert(!label.adjustsFontSizeToFitWidth&&label.numberOfLines==1,@"production fitting contract");
 puts("PASS128 Apple UIKit stub: historical failure plus current visible-left anchors across zero, near-zero, signs, 100 text swaps, fit/truncation and 1-2-line fixtures");
}return 0;}
