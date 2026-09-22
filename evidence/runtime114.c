#include "../src/WCCRuntime.h"
#include <assert.h>
static void rect(WCCRect r,double w,double h){assert(isfinite(r.x)&&isfinite(r.y)&&r.w>=0&&r.h>=0);assert(r.x>=-.001&&r.y>=-.001&&r.x+r.w<=w+.001&&r.y+r.h<=h+.001);}
static int overlap(WCCRect a,WCCRect b){return a.w>0&&a.h>0&&b.w>0&&b.h>0&&fmin(a.x+a.w,b.x+b.w)-fmax(a.x,b.x)>.1&&fmin(a.y+a.h,b.y+b.h)-fmax(a.y,b.y)>.1;}
int main(int argc,char **argv){
 int sizes[][2]={{2,1},{3,1},{4,1},{2,2},{3,3}}; int count=0;
 for(int scale=80;scale<=140;scale++)for(int i=0;i<5;i++)for(int ex=0;ex<2;ex++){
 double factor=scale/100.,w=(80*sizes[i][0]-4)*factor,h=ex?200*factor:(80*sizes[i][1]-4)*factor;
 WCCGeometry g=WCCComputeModuleGeometry(w,h,ex,sizes[i][0],sizes[i][1]);
 WCCRect a[]={g.icon,g.city,g.temperature,g.condition,g.highLow,g.precipitation,g.greeting};
 for(int j=0;j<7;j++){rect(a[j],w,g.headerHeight);for(int k=j+1;k<7;k++)assert(!overlap(a[j],a[k]));}
 if(i>=3||ex){WCCGeometry old=WCCComputeGeometry(w,h,ex);assert(!memcmp(&g,&old,sizeof(g)));}
 else {double edge=g.city.x+g.city.w;if(g.details)assert(fabs(g.precipitation.x+g.precipitation.w-edge)<.001);assert(fabs(g.city.x+g.city.w-edge)<.001);assert(fabs(g.condition.x+g.condition.w-edge)<.001);assert(fabs(g.greeting.x+g.greeting.w-edge)<.001);assert(fabs(g.temperature.x-(w-edge))<.001);assert(g.icon.x>=g.temperature.x+g.temperature.w);assert(g.icon.x+g.icon.w<g.city.x);assert(g.tempFont>g.cityFont);}
 count++;
 if(argc>1&&scale==100){printf("%dx%d%s %.2f %.2f %.2f %.2f %.2f %.2f",sizes[i][0],sizes[i][1],ex?"-expanded":"",w,h,g.cityFont,g.tempFont,g.detailFont,g.greetingFont);for(int j=0;j<7;j++)printf(" %.2f %.2f %.2f %.2f",a[j].x,a[j].y,a[j].w,a[j].h);puts("");}
 }
 WCCGreetingState state={0,-1};
 for(int hour=0;hour<24;hour++)for(int r=0;r<840;r++){
 int last=state.index;int next=WCCPresentGreeting(&state,hour,r); // Deliberately NO end/dismiss/window detach.
 assert(next!=last&&next/8==WCCGreetingPeriod(hour));assert(strlen(WCCGreetingPrefix(next))&&strlen(WCCGreetingSuffix(next)));
 if(last>=0&&last/8==next/8){assert(!strcmp(WCCGreetingPrefix(last),WCCGreetingPrefix(next)));assert(strcmp(WCCGreetingSuffix(last),WCCGreetingSuffix(next)));}
 for(int e=0;e<5;e++)assert(WCCBeginGreeting(&state,(hour+e)%24,r+e)==next);
 }
 for(int period=0;period<6;period++)for(int a=0;a<8;a++)for(int b=a+1;b<8;b++)assert(strcmp(WCCGreetingSuffixes[period][a],WCCGreetingSuffixes[period][b]));
 if(argc==1)printf("PASS: %d production geometries, all three single-row sizes aligned; square/expanded byte-identical; 20160 presentation edges without dismissal; 100800 stable events; 6 fixed prefixes / 48 distinct within-period suffixes. iOS16.6 UIKit host delivery NOT RUN.\n",count);
}
