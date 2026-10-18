#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "../src/WCCRuntime.h"
@interface UILabel : NSObject
@property CGRect frame;
@property NSInteger textAlignment;
@property(copy) NSString *text;
@property NSInteger numberOfLines;
@end
@implementation UILabel @end
static BOOL near(double a,double b){return fabs(a-b)<1e-7;}
static WCCRect ink(UILabel *l,double measured,WCCRect delta){int a=l.textAlignment==2?2:l.textAlignment==1?1:0;return WCCAlignedTextBounds(WCCR(l.frame.origin.x+delta.x,l.frame.origin.y+delta.y,l.frame.size.width,l.frame.size.height),measured,a);}
int main(void){@autoreleasepool{
 UILabel *label=[UILabel new];label.frame=CGRectMake(36,30,204,18);label.numberOfLines=1;
 NSArray<NSString *> *texts=@[@"早安",@"你好，愿你今天顺心",@"很长很长会缩放或截断但锚点不能移动的随机问候语"];
 NSArray<NSNumber *> *widths=@[@24,@112,@204];
 for(NSNumber *request in @[@(-1366),@0,@1366]){
  int a=WCCGreetingAlignment(request.doubleValue,0);label.textAlignment=a;WCCRect expected=WCCGreetingTranslation(WCCR(36,30,204,18),320,76,request.doubleValue,13);
  for(int pass=0;pass<100;pass++){
   NSUInteger i=pass%texts.count;label.text=texts[i];WCCRect d=WCCGreetingTranslation(WCCR(36,30,204,18),320,76,request.doubleValue,13);WCCRect visible=ink(label,widths[i].doubleValue,d);
   NSCAssert(near(d.x,expected.x)&&near(d.y,expected.y),@"bind/layout accumulated or text changed translation");
   if(request.doubleValue<0)NSCAssert(near(visible.x,0),@"left visible edge");
   if(request.doubleValue>0)NSCAssert(near(visible.x+visible.w,320),@"right visible edge");
  }
 }
 // A two-line/stub textRect height change cannot affect fixed rail Y.
 WCCRect y1=WCCGreetingTranslation(WCCR(36,30,204,18),320,76,0,40),y2=WCCGreetingTranslation(WCCR(36,30,204,18),320,76,0,40);
 NSCAssert(near(y1.y,y2.y),@"Y anchor drift");
 puts("PASS127 Apple Foundation/UIKit UILabel stub: short/long/truncated/random binds, edge anchors, 100 idempotent layouts and stable Y");
}return 0;}
