#include "../src/WCCRuntime.h"
#include "../src/WCCSession.h"
#include <assert.h>
static void consume(WCCModuleSession *m,WCCHostState h,WCCGreetingState *g,int *draws) {
 if(WCCConsumeModuleHost(m,h)) {int prev=g->index; WCCPresentGreeting(g,15,42);assert(prev!=g->index);++*draws;}
}
#include "../src/WCCABI.h"
int main(int argc,char **argv) {
 (void)argv;
 const char *a[]={"@",":","B","B"}, *wanted[]={"B","B"};
 assert(WCCABICompatible("@","@",4,a,2,wanted));
 assert(!WCCABICompatible("v","@",4,a,2,wanted));
 assert(!WCCABICompatible("@","@",3,a,2,wanted));
 a[2]="c";assert(!WCCABICompatible("@","@",4,a,2,wanted));
 a[2]="{CGRect=dddd}";assert(!WCCABICompatible("@","@",4,a,2,wanted));
 a[2]="B";a[0]="#";assert(!WCCABICompatible("@","@",4,a,2,wanted));
 a[0]="@";a[1]="@";assert(!WCCABICompatible("@","@",4,a,2,wanted));
 assert(!WCCABICompatible(NULL,"@",4,a,2,wanted));
 WCCHostState h={0}; WCCModuleSession m={0}; WCCGreetingState g={0,-1};int draws=0;
 for(int i=0;i<1000;i++) {
  assert(WCCConsumeHostEvent(&h,WCCHostBegin,1)); consume(&m,h,&g,&draws); int n=draws,index=g.index;
  assert(!WCCConsumeHostEvent(&h,WCCHostBegin,1));
  assert(!WCCConsumeHostEvent(&h,WCCHostPresented,1));
  for(int j=0;j<20;j++) consume(&m,h,&g,&draws); // Module present/window/appearance/settings return, same host generation.
  assert(draws==n&&g.index==index);
  assert(WCCConsumeExpansion(&m,1));WCCPresentGreeting(&g,15,42);assert(g.index!=index);index=g.index;
  assert(!WCCConsumeExpansion(&m,1));
  assert(WCCConsumeExpansion(&m,0));WCCPresentGreeting(&g,15,42);assert(g.index!=index);
  assert(!WCCConsumeExpansion(&m,0));
  // Cancelled dismissal is still visible; no new presentation generation.
  assert(!WCCConsumeHostEvent(&h,WCCHostDismissed,1));consume(&m,h,&g,&draws);assert(draws==n);
  assert(WCCConsumeHostEvent(&h,WCCHostDismissed,0));consume(&m,h,&g,&draws);assert(draws==n);
 }
 assert(draws==1000);
 // Cancelled interactive presentation resets visibility; retry advances once.
 WCCConsumeHostEvent(&h,WCCHostBegin,1);consume(&m,h,&g,&draws);
 assert(WCCConsumeHostEvent(&h,WCCHostPresented,0));
 WCCConsumeHostEvent(&h,WCCHostBegin,1);consume(&m,h,&g,&draws);assert(draws==1002);
 int sizes[][2]={{2,1},{3,1},{4,1},{2,2},{3,3}};
 for(int k=80;k<=140;k++) for(int i=0;i<5;i++) {
  double s=k/100.,w=(80*sizes[i][0]-4)*s,ht=(80*sizes[i][1]-4)*s;
  WCCGeometry a=WCCComputeModuleGeometry(w,ht,0,sizes[i][0],sizes[i][1]);
  if(i==1){assert(fabs(a.city.x-(a.icon.x+a.icon.w)-6*s)<.001);assert(a.tempFont>a.cityFont);assert(a.precipitation.x==a.city.x);}
  WCCRect r[]={a.icon,a.city,a.temperature,a.condition,a.highLow,a.precipitation,a.greeting};
  for(int j=0;j<7;j++){assert(r[j].x>=0&&r[j].y>=0&&r[j].x+r[j].w<=w+.001&&r[j].y+r[j].h<=ht+.001);}
  if(argc>1&&k==100){printf("%d %d %.2f %.2f %.2f %.2f %.2f %.2f",sizes[i][0],sizes[i][1],w,ht,a.cityFont,a.tempFont,a.detailFont,a.greetingFont);for(int j=0;j<7;j++)printf(" %.2f %.2f %.2f %.2f",r[j].x,r[j].y,r[j].w,r[j].h);puts("");}
 }
 if(argc==1) puts("PASS: production host begin/present/dismiss state adapter; 1000 close/reopen, 20000 duplicate module deliveries, 2000 expand/collapse changes, cancelled presentation/dismissal, 305 geometries. UIKit runtime NOT RUN.");
}
