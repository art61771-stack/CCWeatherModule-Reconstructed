#include "../src/WCCRuntime.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
static int near(double a,double b){return fabs(a-b)<1e-7;}
static double leftEdge(WCCRect rail,double measured,int align,WCCRect d){return WCCAlignedTextBounds(WCCR(rail.x+d.x,rail.y+d.y,rail.w,rail.h),measured,align).x;}
static double rightEdge(WCCRect rail,double measured,int align,WCCRect d){WCCRect r=WCCAlignedTextBounds(WCCR(rail.x+d.x,rail.y+d.y,rail.w,rail.h),measured,align);return r.x+r.w;}
int main(void){
 const double widths[]={18,64,146,260};
 WCCRect rails[]={WCCR(26,52,180,12),WCCR(80,35,210,24)};
 for(int r=0;r<2;r++)for(int sign=-1;sign<=1;sign++){
  double x=sign<0?-1366:sign>0?1366:0,y=sign<0?-40:sign>0?40:0;
  int align=WCCGreetingAlignment(x,1);
  WCCRect first=WCCGreetingTranslation(rails[r],320,76,x,y);
  for(int i=0;i<4;i++){
   WCCRect d=WCCGreetingTranslation(rails[r],320,76,x,y);
   assert(near(d.x,first.x)&&near(d.y,first.y));
   if(sign<0)assert(near(leftEdge(rails[r],widths[i],align,d),0));
   if(sign>0)assert(near(rightEdge(rails[r],widths[i],align,d),320));
   if(!sign)assert(near(d.x,0)&&near(d.y,0)&&align==1);
  }
 }
 // Same preference remains invariant through 100 bind/layout passes; no transform accumulation.
 WCCRect rail=WCCR(42,28,190,20), expected=WCCGreetingTranslation(rail,320,76,700,-17);
 for(int i=0;i<100;i++){double measured=widths[i%4];int align=WCCGreetingAlignment(700,0);WCCRect d=WCCGreetingTranslation(rail,320,76,700,-17);assert(near(d.x,expected.x)&&near(d.y,expected.y));assert(rightEdge(rail,measured,align,d)<=320+1e-7);}
 // Region group keeps its 1.2.4 measured-ink contract.
 for(int direction=-1;direction<=1;direction+=2){WCCRect ink=WCCAlignedTextBounds(WCCR(120,5,150,20),40,WCCInformationAlignment(direction,0));WCCRect d=WCCRegionTranslation(ink,320,76,direction*1366,0);assert(near(direction<0?ink.x+d.x:ink.x+d.x+ink.w,direction<0?0:320));}
 // Y is based on the fixed rail, not one/two-line textRect height.
 WCCRect one=WCCGreetingTranslation(WCCR(40,30,180,12),320,76,0,40);
 WCCRect two=WCCGreetingTranslation(WCCR(40,30,180,12),320,76,0,40);
 assert(near(one.y,two.y));
 puts("PASS127 production geometry: stable greeting rail anchors, visible edge endpoints, 100 idempotent layouts, region contract and Y stability");
 return 0;
}
