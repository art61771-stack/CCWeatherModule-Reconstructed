#include "../src/WCCRuntime.h"
#include "../src/WCCSession.h"
#include <assert.h>
static void near(double a,double b){assert(fabs(a-b)<1e-8);}
int main(void){
 for(int w=250;w<=600;w+=50){
  WCCGeometry g=WCCComputeModuleGeometry(w,76,0,4,1);
  WCCRect rails[]={g.greeting,g.city,g.condition,g.precipitation};
  for(int j=0;j<4;j++)for(int text=8;text<=300;text+=13){
   WCCRect r=WCCAlignedTextBounds(rails[j],text,2);
   WCCRect left=WCCRegionTranslation(r,w,76,-1366,0),right=WCCRegionTranslation(r,w,76,1366,0);
   near(r.x+left.x,0);near(r.x+r.w+right.x,w);
   near(WCCRegionTranslation(r,w,76,0,0).x,0);
  }
  for(int scale=50;scale<=250;scale+=5){
   WCCRect zero=WCCMainIconTarget(g.icon,w,76,0,0,0,scale);
   WCCRect up=WCCMainIconTarget(g.icon,w,76,0,0,-40,scale);
   WCCRect down=WCCMainIconTarget(g.icon,w,76,0,0,40,scale);
   assert(up.y<=zero.y && down.y>=zero.y);
   assert(up.y>=0 && down.y+down.h<=76+1e-8);
   if(zero.h<76){assert(up.y<down.y);}
   WCCRect left=WCCMainIconTarget(g.icon,w,76,0,-1366,0,scale);
   WCCRect right=WCCMainIconTarget(g.icon,w,76,0,1366,0,scale);
   near(left.x,0);near(right.x+right.w,w);
   near(WCCMainIconTarget(g.icon,w,76,1,0,-40,100).y,WCCMainIconTarget(g.icon,w,76,1,0,40,100).y);
  }
 }
 // Actual production 4x1 path is WCCComputeModuleGeometry (not 3x1 balance).
 WCCGeometry actual=WCCComputeModuleGeometry(350,76,0,4,1);
 near(actual.icon.y,8);near(actual.icon.h,32);
 for(int p=50;p<=250;p+=50){
  WCCRect z=WCCMainIconTarget(actual.icon,350,76,0,0,0,p);
  WCCRect u=WCCMainIconTarget(actual.icon,350,76,0,0,-40,p);
  WCCRect d=WCCMainIconTarget(actual.icon,350,76,0,0,40,p);
  assert(d.y-u.y>=16-1e-8);
  printf("4x1 350x76 scale=%d iconHeight=%.1f baselineY=%.1f upY=%.1f downY=%.1f availableY=%.1f\n",p,z.h,z.y,u.y,d.y,76-z.h);
 }
 assert(WCCPickCustomGreeting(0,SIZE_MAX,0)==SIZE_MAX);
 for(unsigned r=0;r<10000;r++){
  assert(WCCPickCustomGreeting(1,0,r)==0);
  for(size_t count=2;count<20;count++)for(size_t prev=0;prev<count;prev++){
   size_t n=WCCPickCustomGreeting(count,prev,r);assert(n<count && n!=prev);
  }
 }
 WCCHostState h={0};WCCModuleSession m={0};int changes=0;
 assert(WCCConsumeHostEvent(&h,WCCHostBegin,1));changes+=WCCConsumeModuleHost(&m,h);
 for(int i=0;i<100;i++){changes+=WCCConsumeModuleHost(&m,h);}assert(changes==1);
 changes+=WCCConsumeExpansion(&m,1);changes+=WCCConsumeExpansion(&m,1);assert(changes==2);
 changes+=WCCConsumeExpansion(&m,0);assert(changes==3);
 WCCConsumeHostEvent(&h,WCCHostDismissed,0);assert(!WCCConsumeModuleHost(&m,h));
 WCCConsumeHostEvent(&h,WCCHostBegin,1);changes+=WCCConsumeModuleHost(&m,h);assert(changes==4);
 puts("PASS redo122 production C: aligned 4x1 text extremes, icon X/Y/scale, selection empty/single/nonrepeat, host and expansion edge dedup");
}
