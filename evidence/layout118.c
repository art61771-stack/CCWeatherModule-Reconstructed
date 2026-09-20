#include "../src/WCCRuntime.h"
#include "../src/WCCHourly.h"
#include <assert.h>
int main(void) {
 for(int i=0;i<3;i++) {
  double w=260+i*30,h=84;
  WCCGeometry g=WCCComputeModuleGeometry(w,h,0,3,1);
  g=WCCBalanceMeasuredStrip(g,w,h,39,44,47,25,77,148);
  assert(fabs(g.temperature.x-g.highLow.x)<.001);
  assert(fabs(g.temperature.x-g.greeting.x)<.001);
  assert(fabs(g.temperature.x-(w-g.city.x-g.city.w))<.001);
  assert(g.icon.x>=g.temperature.x+g.temperature.w+20);
  assert(g.city.x>g.icon.x+g.icon.w);
  assert(fabs(g.icon.y+g.icon.h/2-(g.city.y+g.precipitation.y+g.precipitation.h)/2)<.001);
  g=WCCBalanceMeasuredStrip(g,w,h,500,500,500,500,500,500);
  assert(g.greeting.x+g.greeting.w<=w-g.temperature.x+.001);
 }
 assert(WCCNormalizeIconPercent(NAN)==100);
 assert(WCCNormalizeIconPercent(0)==100 && WCCNormalizeIconPercent(151)==100);
 assert(WCCNormalizeIconPercent(103)==105);
 assert((50+150)/2==100);
 WCCRect original=WCCR(0,0,30,30);
 WCCRect a=WCCScaledMainIcon(original,100,8); assert(a.x==0 && a.w==30);
 a=WCCScaledMainIcon(original,50,8); assert(a.x==7.5 && a.w==15);
 a=WCCScaledMainIcon(original,150,8); assert(a.x==-7.5 && a.w==45);
 a=WCCScaledMainIcon(original,150,2); assert(fabs(a.w-34)<.001);
 assert(original.w==30); // hourly rectangle never mutated by value-based helper
 // Production gate lifecycle: created at zero bounds, layout while detached,
 // host window before child window, child layout completion, then visible.
 assert(!WCCHourlyLayoutReady(1,1,0,0,0,0,0,0));
 assert(!WCCHourlyLayoutReady(1,1,0,0,0,0,350,80));
 assert(!WCCHourlyLayoutReady(1,1,0,1,0,0,350,80));
 assert(WCCHourlyLayoutReady(1,1,0,1,1,0,350,80));
 assert(!WCCHourlyLayoutReady(1,0,0,1,1,0,350,80));
 assert(!WCCHourlyLayoutReady(1,1,1,1,1,0,350,80));
 int count=0;
 for(int i=0;i<12;i++) count+=WCCHourlyAdmit(WCCHourlyIntersects(12+i*55,55,0,350),1);
 assert(count==7); // all seven, no three-player starvation
 assert(!WCCHourlyIntersects(12,55,350,350));
 assert(WCCHourlyIntersects(12,55,0,350)); // rolling back re-admits
 puts("118 production geometry/scale/layout gate: PASS (portable C; UIKit/device NOT RUN)");
 return 0;
}
