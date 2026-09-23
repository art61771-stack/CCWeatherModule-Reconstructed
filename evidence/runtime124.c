#include "../src/WCCRuntime.h"
#include "../src/WCCRefreshPolicy.h"
#include "../src/WCCRoutePolicy.h"
#include <assert.h>
#include <stdio.h>
static int near(double a,double b){return fabs(a-b)<1e-7;}
int main(void) {
 int cases=0;
 for(int i=0;i<64;i++){int a=i&1,b=i&2,c=i&4,d=i&8,e=i&16,f=i&32;assert(WCCRouteCanEnter(a,b,c,d,e,f)==!!(a&&b&&!c&&!d&&!e&&!f));}
 assert(WCCRouteCanReturn(1,0,1,1));assert(!WCCRouteCanReturn(1,1,1,1));assert(!WCCRouteCanReturn(1,0,0,1));assert(!WCCRouteOwnsDismiss(1,0,0));assert(!WCCRouteOwnsDismiss(1,1,1));
 const double standard=WCCEffectStandardOpacity124;
 const double densities[]={-1,-.5,0,.5,1}, highs[]={0,.3,.6,.8,1}, lows[]={0,.1,.2,4./15,1./3};
 assert(near(standard,.6));
 for(int i=0;i<5;i++) {
  double high=WCCEffectOpacity(standard,densities[i]),low=WCCEffectLow(high,standard);
  assert(near(high,highs[i])&&near(low,lows[i]));
  if(i){assert(high>WCCEffectOpacity(standard,densities[i-1]));assert(low>WCCEffectLow(WCCEffectOpacity(standard,densities[i-1]),standard));}
  printf("density=%g static/high=%.6f low=%.6f\n",densities[i],high,low);
 }
 // Both static and breathing endpoints strictly increase, including right half.
 for(int alphaStep=0;alphaStep<=10;alphaStep++) {
  double alpha=alphaStep/10.,previous=-1,previousLow=-1;
  for(int step=-100;step<=100;step++) {
   double high=WCCEffectOpacity(standard,step/100.0),low=WCCEffectLow(high,standard);
   assert(high>=0&&high<=1&&low>=0&&low<=high);
   if(alpha>0){assert(high*alpha>previous&&low*alpha>previousLow);}
   else {assert(high*alpha==0&&low*alpha==0);} // Fully transparent picker exception.
   previous=high*alpha;previousLow=low*alpha;
  }
 }
 assert(WCCEffectOpacity(standard,-2)==0&&WCCEffectOpacity(standard,2)==1);
 assert(WCCEffectOpacity(standard,NAN)==standard);
 assert(WCCEffectOpacity(standard,INFINITY)==standard);
 puts("PASS124 density: five production mapping points; 201 strict high/low samples x 11 picker alphas (zero exception)");
 for(int h=60;h<=110;h+=10)for(int w=240;w<=440;w+=40)for(int percent=50;percent<=250;percent+=5){
  WCCGeometry g=WCCComputeModuleGeometry(w,h,0,4,1);
  WCCRect n=WCCMainIconTargetForLayout(g.icon,w,g.headerHeight,0,4,1,0,0,percent);
  WCCRect up=WCCMainIconTargetForLayout(g.icon,w,g.headerHeight,0,4,1,0,-40,percent);
  WCCRect down=WCCMainIconTargetForLayout(g.icon,w,g.headerHeight,0,4,1,0,40,percent);
  assert(n.y>0 && n.y<g.headerHeight-n.h);assert(up.y<n.y && down.y>n.y);
  assert(up.y>=0 && down.y+down.h<=g.headerHeight+1e-7);
  assert(near(n.y,(g.headerHeight-n.h)/2));cases++;
 }
 for(int c=2;c<=4;c++)for(int r=1;r<=3;r++)for(int e=0;e<2;e++)for(int pct=50;pct<=150;pct+=5){
  if(!e && c==4 && r==1)continue;
  WCCGeometry g=WCCComputeModuleGeometry(320,100,e,c,r);
  WCCRect a=WCCMainIconTarget(g.icon,320,g.headerHeight,e,-22,-20,pct);
  WCCRect b=WCCMainIconTargetForLayout(g.icon,320,g.headerHeight,e,c,r,-22,-20,pct);
  assert(near(a.x,b.x)&&near(a.y,b.y)&&near(a.w,b.w)&&near(a.h,b.h));
 }
 for(int def=0;def<=2;def+=2){
  assert(WCCInformationAlignment(0,def)==def);
  assert(WCCInformationAlignment(-1,def)==0&&WCCInformationAlignment(-100,def)==0);
  assert(WCCInformationAlignment(1,def)==2&&WCCInformationAlignment(100,def)==2);
  for(int direction=-1;direction<=1;direction+=2){
   WCCRect ink=WCCAlignedTextBounds(WCCR(120,5,150,20),40,WCCInformationAlignment(direction,def));
   WCCRect delta=WCCRegionTranslation(ink,320,76,direction*1366,0);
   assert(near(direction<0?ink.x+delta.x:ink.x+delta.x+ink.w,direction<0?0:320));
  }
 }
 assert(WCCRefreshTTL(0)==900&&WCCRefreshTTL(1)==3600&&WCCRefreshTTL(12)==43200&&WCCRefreshTTL(24)==86400&&WCCRefreshTTL(2)==900);
 assert(WCCRefreshDelay(100,900,60)==800&&WCCRefreshDelay(900,900,60)==60&&WCCRefreshDelay(901,900,0)==1);
 assert(WCCBreathDuration(-1)==6&&WCCBreathDuration(0)==3&&WCCBreathDuration(1)==1.5);
 printf("PASS124 production C: %d 4x1 geometry/scale cases; other layout identity, sign alignment+edges, TTL/deadline, speed\n",cases);
 WCCGeometry g=WCCComputeModuleGeometry(320,76,0,4,1);
 for(int p=50;p<=250;p+=50){WCCRect old=WCCMainIconTarget(g.icon,320,g.headerHeight,0,0,0,p);WCCRect n=WCCMainIconTargetForLayout(g.icon,320,g.headerHeight,0,4,1,0,0,p);printf("320x76 %d%% slot.y=%.1f old.y=%.1f new.y=%.1f size=%.1f\n",p,g.icon.y,old.y,n.y,n.h);}
 return 0;
}
