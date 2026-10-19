#include "../src/WCCRuntime.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
static int near(double a,double b){return fabs(a-b)<1e-7;}
static WCCRect visible(WCCRect rail,double measured,double height,int align,WCCRect d){return WCCGreetingVisibleBounds(WCCR(rail.x+d.x,rail.y+d.y,rail.w,rail.h),measured,height,align);}
int main(void){
 const double requests[]={0,0.49,-0.49,-1,1,1366};
 const double widths[]={24,112,204,400};
 WCCRect rail=WCCR(36,30,204,18);
 /* Reproduce 1.2.7's real 4x1 failure: zero inherited right alignment, so
    short/long visible left edges differ although the UILabel translation is 0. */
 WCCRect legacyShort=visible(rail,24,12,2,WCCR(0,0,0,0));
 WCCRect legacyLong=visible(rail,112,12,2,WCCR(0,0,0,0));
 assert(!near(legacyShort.x,legacyLong.x));
 for(unsigned r=0;r<sizeof(requests)/sizeof(requests[0]);r++){
  double x=requests[r]; int align=WCCGreetingVisibleAlignment(x);
  WCCRect d=WCCGreetingTranslation(rail,320,76,x,13), first=d;
  for(unsigned i=0;i<sizeof(widths)/sizeof(widths[0]);i++){
   WCCRect ink=visible(rail,widths[i],i&1?18:12,align,d);
   assert(near(d.x,first.x)&&near(d.y,first.y));
   /* 1.2.14 supersedes the historical positive-X right anchor: every
      persisted request now controls a text-independent visible left edge. */
   assert(near(ink.x,rail.x+d.x));
   assert(near(ink.y,rail.y+d.y));
  }
 }
 /* Saturated endpoints, stable Y, and unrelated information contract. */
 WCCRect dl=WCCGreetingTranslation(rail,320,76,-1366,-40),dr=WCCGreetingTranslation(rail,320,76,1366,40);
 assert(near(visible(rail,24,12,0,dl).x,0));
 WCCRect rr=visible(rail,24,12,0,dr);assert(near(rr.x,319));
 assert(near(dl.y,-30)&&near(dr.y,28));
 WCCRect info=WCCAlignedTextBounds(WCCR(120,5,150,20),40,WCCInformationAlignment(0,2));assert(near(info.x,230));
 puts("PASS128 historical failure plus current left-origin greeting anchor: zero/near-zero/negative/positive, short/long/fit/truncation/1-2-line and Y stable");
 return 0;
}
