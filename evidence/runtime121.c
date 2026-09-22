#include "../src/WCCRuntime.h"
#include "../src/WCCPanelGeometry.h"
#include <assert.h>
int main(void) {
 assert(WCCCollapsedSliderPercent(-1)==50 && WCCCollapsedSliderPercent(0)==100 && WCCCollapsedSliderPercent(1)==250);
 for(int p=50;p<=250;p+=5)assert(WCCCollapsedSliderPercent(WCCCollapsedSliderPosition(p))==p);
 assert(WCCNormalizeIconPercentForMode(1,250)==100);
 assert(WCCNormalizeIconPercentForMode(0,250)==250);
 int sizes[][2]={{2,1},{3,1},{4,1},{2,2},{3,3}};
 for(int i=0;i<5;i++)for(int p=50;p<=250;p+=5)for(int x=-1366;x<=1366;x+=1366)for(int y=-40;y<=40;y+=40){
 double w=78*sizes[i][0],h=76*sizes[i][1];WCCRect b=WCCComputeModuleGeometry(w,h,0,sizes[i][0],sizes[i][1]).icon;
 WCCRect t=WCCMainIconTarget(b,w,h,0,x,y,p);
 assert(t.x>=-1e-8 && t.y>=-1e-8 && t.x+t.w<=w+1e-8 && t.y+t.h<=h+1e-8);
 }
 for(int a=100;a<=1000;a+=100)for(int size=44;size<=540;size+=31)for(int u=-10;u<=20;u++){
 double origin=WCCPanelOrigin(6,a,size,u/10.);assert(origin>=6 && origin<=6+fmax(0,a-size));
 double pos=WCCPanelPosition(origin,6,a,size);assert(pos>=0 && pos<=1);
 assert(fabs(WCCPanelOrigin(6,a,size,pos)-origin)<1e-8);
 }
 assert(WCCPanelUnit(NAN)==.5);assert(WCCPanelCanDrag(1,0,1));
 assert(!WCCPanelCanDrag(0,0,1)&&!WCCPanelCanDrag(1,1,1)&&!WCCPanelCanDrag(1,0,2));
 puts("PASS 121 production portable C: split slider, all five sizes through250, panel rotation/keyboard geometry and drag eligibility");
}
