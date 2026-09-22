#include "../src/WCCRuntime.h"
#include <assert.h>
static int eq(double a,double b){return fabs(a-b)<1e-8;}
int main(void){
 int sizes[5][2]={{2,1},{3,1},{4,1},{2,2},{3,3}}; int changes=0;
 for(int i=0;i<5;i++){
  double w=78*sizes[i][0],h=76*sizes[i][1];
  WCCRect b=WCCComputeModuleGeometry(w,h,0,sizes[i][0],sizes[i][1]).icon;
  WCCRect moved=WCCMainIconTarget(b,w,h,0,17,-9,100);
  for(int p=50;p<=150;p+=50){
   WCCRect t=WCCMainIconTarget(b,w,h,0,17,-9,p);
   assert(t.y>=-1e-8 && t.y+t.h<=h+1e-8);
   if(!eq(t.y+t.h/2,moved.y+moved.h/2)){
    changes++; printf("119 center exception size=%dx%d scale=%d baseline=(%.3f,%.3f,%.3f,%.3f) targetY=%.3f height=%.3f center=%.3f vs100=%.3f\n",sizes[i][0],sizes[i][1],p,b.x,b.y,b.w,b.h,t.y,t.h,t.y+t.h/2,moved.y+moved.h/2);
    // Center change is allowed only when the scaled box hits a vertical boundary.
    assert(eq(t.y,0)||eq(t.y+t.h,h)||eq(moved.y,0)||eq(moved.y+moved.h,h));
   }
  }
 }
 assert(changes>0);
 // Away from boundaries, all scales preserve the requested center exactly.
 WCCRect b=WCCR(100,100,40,40);
 for(int p=50;p<=150;p+=5){WCCRect t=WCCMainIconTarget(b,400,400,0,17,-9,p);assert(eq(t.x+t.w/2,137)&&eq(t.y+t.h/2,111));}
 puts("PASS 120 boundary explanation: clipped scaled boxes clamp; interior center invariant retained");
}
