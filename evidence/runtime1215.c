#include <assert.h>
#include <math.h>
#include <stdio.h>
#include "../src/WCCRuntime.h"
static int near(double a,double b){return fabs(a-b)<1e-8;}
static void verify(WCCRect baseline,double w,double h,int expanded,int columns,int rows,double x,double y,double pct){
 WCCMainIconLayout l=WCCMainIconLayoutForBaseline(baseline,w,h,expanded,columns,rows,x,y,pct);
 WCCRect actual=WCCMainIconVisibleRect(l);
 assert(near(actual.x,l.target.x)&&near(actual.y,l.target.y)&&near(actual.w,l.target.w)&&near(actual.h,l.target.h));
 double matrixCenterX=baseline.w*.5*l.scaleX+(l.centerX-baseline.w*.5*l.scaleX);
 double matrixCenterY=baseline.h*.5*l.scaleY+(l.centerY-baseline.h*.5*l.scaleY);
 assert(near(matrixCenterX,l.centerX)&&near(matrixCenterY,l.centerY));
 if(expanded){WCCMainIconLayout neutral=WCCMainIconLayoutForBaseline(baseline,w,h,1,columns,rows,0,0,pct);assert(near(l.centerX,neutral.centerX)&&near(l.centerY,neutral.centerY));}
}
int main(void){
 const double offsets[][2]={{-49,-37},{0,0},{49,37}};
 const int collapsed[]={50,100,150,200,250},expanded[]={50,100,150};
 for(int media=0;media<5;media++)for(int animation=0;animation<2;animation++)for(int order=0;order<6;order++)
 for(unsigned o=0;o<3;o++)for(unsigned c=0;c<5;c++)for(unsigned e=0;e<3;e++){
  WCCRect cb=WCCR(14,8,60,60),eb=WCCR(16,15,55,55); WCCMainIconLayout first={0};
  for(int pass=0;pass<100;pass++){
   WCCMainIconLayout col=WCCMainIconLayoutForBaseline(cb,320,76,0,3,1,offsets[o][0],offsets[o][1],collapsed[c]);
   verify(cb,320,76,0,3,1,offsets[o][0],offsets[o][1],collapsed[c]);
   verify(eb,320,85,1,3,2,offsets[o][0],offsets[o][1],expanded[e]);
   WCCMainIconLayout back=WCCMainIconLayoutForBaseline(cb,320,76,0,3,1,offsets[o][0],offsets[o][1],collapsed[c]);
   if(!pass)first=col;
   assert(near(back.centerX,first.centerX)&&near(back.centerY,first.centerY));
   assert(near(back.target.w,first.target.w)&&near(back.target.h,first.target.h));
  }
  (void)media;(void)animation;(void)order;
 }
 /* Reproduce 1.2.14: a transformed visible frame recached as the next slot
    applies the persisted offset/scale a second time and moves every pull-down. */
 WCCRect base=WCCR(14,8,60,60);WCCMainIconLayout stable=WCCMainIconLayoutForBaseline(base,320,76,0,3,1,31,-22,150);
 WCCRect contaminated=WCCMainIconVisibleRect(stable);
 WCCMainIconLayout legacyNext=WCCMainIconLayoutForBaseline(contaminated,320,76,0,3,1,31,-22,150);
 assert(!near(legacyNext.centerX,stable.centerX)||!near(legacyNext.centerY,stable.centerY));
 WCCMainIconLayout old=WCCMainIconLayoutForBaseline(base,320,76,0,3,1,31,-22,150);
 WCCMainIconLayout changed=WCCMainIconLayoutForBaseline(WCCR(22,12,72,72),390,92,0,4,1,31,-22,150);
 assert(!near(old.centerX,changed.centerX)||!near(old.centerY,changed.centerY));
 WCCMainIconLayout preference=WCCMainIconLayoutForBaseline(WCCR(14,8,60,60),320,76,0,3,1,-31,22,150);
 assert(!near(old.centerX,preference.centerX)||!near(old.centerY,preference.centerY));
 puts("PASS1215 immutable geometry: 5 media paths, animation on/off, 6 callback orders, 100 host presentations, independent sizes/offsets, matrix-visible centers, bounds and preference regeneration");
 return 0;
}
