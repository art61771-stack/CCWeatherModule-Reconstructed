#include "../src/WCCRuntime.h"
#include <assert.h>
int main(void){
 for(int w=156;w<=600;w+=6)for(int h=60;h<=140;h+=10){
 WCCGeometry g=WCCComputeModuleGeometry(w,h,0,3,1);
 g=WCCBalanceMeasuredStrip(g,w,h,39,44,47,25,77,148);
 assert(fabs(g.temperature.x-(w-g.city.x-g.city.w))<.001);
 assert(fabs(g.icon.y+g.icon.h/2-(g.city.y+g.precipitation.y+g.precipitation.h)/2)<.001 || !g.details);
 assert(g.temperature.x>=0 && g.city.x+g.city.w<=w);
 assert(fabs(g.greeting.x-(w-g.greeting.x-g.greeting.w))<.001);
 }
 WCCGeometry g=WCCComputeModuleGeometry(290,84,0,3,1);
 g=WCCBalanceMeasuredStrip(g,290,84,40,42,47,25,77,148);
 WCCRect r[]={g.temperature,g.highLow,g.icon,g.city,g.condition,g.precipitation,g.greeting};
 for(int i=0;i<7;i++)printf("%.3f %.3f %.3f %.3f\n",r[i].x,r[i].y,r[i].w,r[i].h);
 return 0;
}
