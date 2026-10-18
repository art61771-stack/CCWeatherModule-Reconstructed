#include "../src/WCCRuntime.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
static int near(double a,double b){return fabs(a-b)<1e-7;}
int main(void){
 const double moduleWidths[]={156,220,290,320,440};
 const double requests[]={-1366,-49,-1,-.49,0,.49,1,49,1366};
 const double measured[]={12,24,112,400};
 /* Reproduce 1.2.8: positive X selected a right-aligned visible edge, so the
    actual visible LEFT differed with sentence width. */
 WCCRect oldRail=WCCR(36,30,204,18);
 WCCRect oldDelta=WCCGreetingTranslation(oldRail,320,76,49,0);
 WCCRect oldShort=WCCGreetingVisibleBounds(WCCR(oldRail.x+oldDelta.x,30,204,18),24,12,2);
 WCCRect oldLong=WCCGreetingVisibleBounds(WCCR(oldRail.x+oldDelta.x,30,204,18),112,12,2);
 assert(!near(oldShort.x,oldLong.x));
 for(unsigned m=0;m<sizeof(moduleWidths)/sizeof(moduleWidths[0]);m++){
  double width=moduleWidths[m], base=fmin(36,width), height=m&1?152:76;
  for(unsigned r=0;r<sizeof(requests)/sizeof(requests[0]);r++){
   WCCRect rail=WCCGreetingRail(WCCR(base,30,fmax(0,width-base),18),width,height,requests[r],13);
   double expected=fmax(0,fmin(width-WCCGreetingMinimumVisibleWidth,base+WCCNormalizePositionOffset(6,requests[r])));
   assert(near(rail.x,expected)&&near(rail.w,width-expected));
   for(int pass=0;pass<100;pass++){
    double inkWidth=measured[pass%4];
    WCCRect visible=WCCGreetingVisibleBounds(rail,inkWidth,pass&1?18:12,0);
    assert(near(visible.x,expected));
    assert(near(visible.y,rail.y));
   }
  }
 }
 WCCRect left=WCCGreetingRail(WCCR(36,30,204,18),320,76,-1366,-40);
 WCCRect right=WCCGreetingRail(WCCR(36,30,204,18),320,76,1366,40);
 assert(near(left.x,0)&&near(left.w,320));
 assert(near(right.x,319)&&near(right.w,1));
 assert(near(left.y,0)&&near(right.y,58));
 WCCRect info=WCCAlignedTextBounds(WCCR(120,5,150,20),40,WCCInformationAlignment(1,0));
 assert(near(info.x,230));
 puts("PASS1214 greeting origin: 1.2.8 positive-X drift reproduced; five sizes, extrema, near-zero/signs, 100 swaps, 1/2-line, fit/truncation oracle and Y stable");
 return 0;
}
