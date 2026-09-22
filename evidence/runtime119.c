#include "../src/WCCRuntime.h"
#include <assert.h>
static int eq(double a,double b){return fabs(a-b)<1e-8;}
static void same(WCCRect a,WCCRect b){assert(eq(a.x,b.x)&&eq(a.y,b.y)&&eq(a.w,b.w)&&eq(a.h,b.h));}
int main(void){
 int sizes[5][2]={{2,1},{3,1},{4,1},{2,2},{3,3}};
 for(int i=0;i<5;i++){
  double w=78*sizes[i][0],h=76*sizes[i][1];
  WCCGeometry g=WCCComputeModuleGeometry(w,h,0,sizes[i][0],sizes[i][1]);
  WCCRect groups[]={g.temperature,g.icon,g.city,g.greeting};
  for(int k=0;k<4;k++){
   same(WCCRegionTranslation(groups[k],w,h,0,0),WCCR(0,0,0,0));
   for(int x=-40;x<=40;x++)for(int y=-40;y<=40;y++){
    WCCRect d=WCCRegionTranslation(groups[k],w,h,x,y);
    assert(groups[k].x+d.x+groups[k].w>0 && groups[k].x+d.x<w);
    assert(groups[k].y+d.y+groups[k].h>0 && groups[k].y+d.y<h);
    same(d,WCCRegionTranslation(groups[k],w,h,x,y));
   }
  }
  same(g.icon,WCCMainIconTarget(g.icon,w,h,0,0,0,100));
  for(int percent=50;percent<=150;percent+=50){
   WCCRect target=WCCMainIconTarget(g.icon,w,h,0,17,-9,percent);
   for(int repeat=0;repeat<100;repeat++){
    // Every media type uses the exact same parent target; no media flag in API.
    for(int type=0;type<5;type++)same(target,WCCMainIconTarget(g.icon,w,h,0,17,-9,percent));
    WCCRect expanded=WCCR(16,15,55,55);
    same(WCCMainIconTarget(expanded,320,85,1,17,-9,percent),WCCMainIconTarget(expanded,320,85,1,-40,40,percent));
    same(target,WCCMainIconTarget(g.icon,w,h,0,17,-9,percent));
   }
   WCCRect moved=WCCMainIconTarget(g.icon,w,h,0,17,-9,100);
   assert(eq(target.x+target.w/2,moved.x+moved.w/2));
   assert(eq(target.y+target.h/2,moved.y+moved.h/2));
  }
 }
 WCCRect open=WCCR(100,100,40,40);
 assert(eq(WCCMainIconTarget(open,400,400,0,0,0,50).w,20));
 assert(eq(WCCMainIconTarget(open,400,400,0,0,0,100).w,40));
 assert(eq(WCCMainIconTarget(open,400,400,0,0,0,150).w,60));
 assert(WCCNormalizeRegionOffset(NAN)==0 && WCCNormalizeRegionOffset(41)==0);
 assert(WCCNormalizeIconPercent(NAN)==100 && WCCNormalizeIconPercent(103)==105);
 puts("PASS 119 production geometry: five sizes, zero defaults, limits, repeated layouts, collapsed/expanded restore, shared native/custom/fallback target");
 return 0;
}
