#include "../src/WCCRuntime.h"
#include <assert.h>
static void rect(WCCRect r,double w,double h) {assert(isfinite(r.x)&&isfinite(r.y)&&r.w>=0&&r.h>=0);assert(r.x>=-.001&&r.y>=-.001&&r.x+r.w<=w+.001&&r.y+r.h<=h+.001);}
static int overlap(WCCRect a,WCCRect b){return a.w>0&&a.h>0&&b.w>0&&b.h>0&&fmin(a.x+a.w,b.x+b.w)-fmax(a.x,b.x)>.1&&fmin(a.y+a.h,b.y+b.h)-fmax(a.y,b.y)>.1;}
int main(int argc,char **argv){
 WCCGreetingState state={0,-1};
 for(int hour=0;hour<24;hour++)for(int r=0;r<100;r++){
  int previous=state.index; WCCEndGreeting(&state); int a=WCCBeginGreeting(&state,hour,r);
  assert(a>=0&&a<18&&a/3==WCCGreetingPeriod(hour)&&a!=previous&&strlen(WCCGreetingText(a)));
  for(int event=0;event<10;event++) assert(WCCBeginGreeting(&state,(hour+1)%24,r+event)==a);
 }
 // Event ordering: present before label, appearance/layout/preferences are stable,
 // settings return stays stable; public disappearance ends session even without private callback.
 WCCEndGreeting(&state); int before=WCCBeginGreeting(&state,13,0);
 assert(WCCBeginGreeting(&state,13,1)==before);assert(WCCBeginGreeting(&state,13,2)==before);
 WCCEndGreeting(&state);assert(WCCBeginGreeting(&state,13,0)!=before);
 double dims[][3]={{156,76,0},{236,76,0},{316,76,0},{156,156,0},{236,236,0},{350,200,1},{171,83,0},{259,83,0},{347,83,0},{171,171,0},{259,259,0}};
 const char *names[]={"2x1","3x1","4x1","2x2","3x3","expanded","2x1-alt","3x1-alt","4x1-alt","2x2-alt","3x3-alt"};
 for(unsigned i=0;i<sizeof(dims)/sizeof(*dims);i++){
  double w=dims[i][0],h=dims[i][1];WCCGeometry g=WCCComputeGeometry(w,h,dims[i][2]);
  WCCRect all[]={g.icon,g.city,g.temperature,g.condition,g.highLow,g.precipitation,g.greeting};
  for(int j=0;j<7;j++){rect(all[j],w,g.headerHeight);for(int k=j+1;k<7;k++)if(overlap(all[j],all[k])){fprintf(stderr,"overlap %s %d %d\n",names[i],j,k);assert(0);}}
  assert(g.greeting.h>=12&&g.greeting.w>=130&&g.tempFont>g.cityFont&&g.cityFont>g.greetingFont);
  if(i==0)assert(!g.details);if(i>0&&i<6)assert(g.details);
  if(argc>1){printf("%s %.2f %.2f %.2f %.2f %.2f %.2f",names[i],w,h,g.cityFont,g.tempFont,g.detailFont,g.greetingFont);for(int j=0;j<7;j++)printf(" %.2f %.2f %.2f %.2f",all[j].x,all[j].y,all[j].w,all[j].h);puts("");}
 }
 if(argc==1)puts("PASS production geometry: 11 dimensions, bounds/nonoverlap/hierarchy; greeting: 2400 sessions, 24000 stable events. UIKit event delivery NOT RUN.");
}
