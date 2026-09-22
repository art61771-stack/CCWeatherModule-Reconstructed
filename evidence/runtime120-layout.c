#include "../src/WCCRuntime.h"
#include <assert.h>
static int eq(double a,double b){return fabs(a-b)<1e-7;}
static void inside(WCCRect r,double w,double h){assert(r.x>=-1e-7&&r.y>=-1e-7&&r.x+r.w<=w+1e-7&&r.y+r.h<=h+1e-7);}
static int intersects(WCCRect a,WCCRect b){return a.x<b.x+b.w&&b.x<a.x+a.w&&a.y<b.y+b.h&&b.y<a.y+a.h;}
static WCCRect unite(WCCRect a,WCCRect b){return WCCR(fmin(a.x,b.x),fmin(a.y,b.y),fmax(a.x+a.w,b.x+b.w)-fmin(a.x,b.x),fmax(a.y+a.h,b.y+b.h)-fmin(a.y,b.y));}
static void endpoints(WCCRect r,double w,double h){
 WCCRect lo=WCCRegionTranslation(r,w,h,-1366,0),hi=WCCRegionTranslation(r,w,h,1366,0);
 assert(eq(r.x+lo.x,0)); assert(eq(r.x+r.w+hi.x,w));
 assert(eq(WCCRegionTranslation(r,w,h,0,0).x,0));
}
int main(void){
 double widths[]={140,156,170,180,200,240,320,430,768,1024,1366};
 double heights[]={65,76,84,96};
 for(unsigned i=0;i<sizeof(widths)/sizeof(*widths);i++)for(unsigned j=0;j<sizeof(heights)/sizeof(*heights);j++){
  double w=widths[i],h=heights[j]; WCCGeometry g=WCCComputeModuleGeometry(w,h,0,2,1);
  assert(g.details&&g.detailFont>0);
  WCCRect all[]={g.temperature,g.highLow,g.icon,g.city,g.condition,g.precipitation,g.greeting};
  for(int a=0;a<7;a++){inside(all[a],w,h);assert(all[a].w>0&&all[a].h>0);for(int b=a+1;b<7;b++)assert(!intersects(all[a],all[b]));}
  WCCRect groups[]={unite(g.temperature,g.highLow),g.icon,unite(unite(g.city,g.condition),g.precipitation),g.greeting};
  for(int k=0;k<4;k++)endpoints(groups[k],w,h);
  for(int p=50;p<=150;p+=5){
   WCCRect base=WCCMainIconTarget(g.icon,w,h,0,0,0,p);
   WCCRect lo=WCCMainIconTarget(g.icon,w,h,0,-1366,0,p),hi=WCCMainIconTarget(g.icon,w,h,0,1366,0,p);
   inside(lo,w,h);inside(hi,w,h);assert(eq(lo.x,0)&&eq(hi.x+hi.w,w));assert(eq(lo.w,base.w)&&eq(hi.w,base.w));
   for(int repeat=0;repeat<10;repeat++){WCCRect again=WCCMainIconTarget(g.icon,w,h,0,1366,0,p);assert(eq(again.x,hi.x)&&eq(again.w,hi.w));}
  }
 }
 WCCRect slot=WCCR(16,15,55,55);
 for(int p=50;p<=150;p+=5){WCCRect a=WCCMainIconTarget(slot,320,85,1,-1366,-40,p),b=WCCMainIconTarget(slot,320,85,1,1366,40,p);assert(eq(a.x,b.x)&&eq(a.y,b.y)&&eq(a.w,b.w));inside(a,320,85);}
 assert(WCCNormalizePositionOffset(0,1366)==1366&&WCCNormalizePositionOffset(0,1367)==0);
 assert(WCCNormalizePositionOffset(1,41)==0&&WCCNormalizePositionOffset(1,40)==40);
 assert(WCCNormalizePositionOffset(2,NAN)==0&&WCCNormalizePositionOffset(4,INFINITY)==0);
 puts("PASS production120 geometry: 44 real bounds, seven visible nonoverlapping 2x1 frames, complete four-group horizontal endpoints, every 50..150 scale endpoint, repeated layouts, expanded offset removal, nonfinite input");
 return 0;
}
