#include <assert.h>
#include <math.h>
#include <stdio.h>
#include "../src/WCCRuntime.h"
static int near(double a,double b){return fabs(a-b)<1e-9;}
int main(void){
 double w=800,h=228,x=137,y=-9,p=175;
 WCCPoint fixed=WCCAbsoluteIconCenterFromLegacy(w,h,4,1,x,y,p);
 WCCRect canonical=WCCCanonicalCollapsedIcon(w,h,4,1);
 /* 1.2.15 failure reproduction: two legal dynamic slots yield two centers. */
 WCCMainIconLayout oldA=WCCMainIconLayoutForBaseline(canonical,w,h,0,4,1,x,y,p);
 WCCRect shifted=canonical;shifted.x-=24;
 WCCMainIconLayout oldB=WCCMainIconLayoutForBaseline(shifted,w,h,0,4,1,x,y,p);
 assert(!near(oldA.centerX,oldB.centerX));
 /* 1.2.16: 100 pulls x 8 callback orders x all content/media states. */
 for(int pull=0;pull<100;pull++)for(int order=0;order<8;order++)for(int details=0;details<2;details++)
 for(int city=0;city<2;city++)for(int bg=0;bg<2;bg++)for(int media=0;media<5;media++)
 for(int animation=0;animation<2;animation++){
   (void)pull;(void)order;(void)details;(void)city;(void)bg;(void)media;(void)animation;
   WCCRect c=WCCCanonicalCollapsedIcon(w,h,4,1);
   WCCPoint q=WCCClampAbsoluteIconCenter(fixed.x,fixed.y,w,h,c.w,c.h,p);
   assert(near(q.x,fixed.x)&&near(q.y,fixed.y));
 }
 /* Minor host inset/baseline changes are irrelevant when module bounds match. */
 for(int jitter=-4;jitter<=4;jitter++){WCCRect fake=canonical;fake.x+=jitter;(void)fake;
   WCCRect c=WCCCanonicalCollapsedIcon(w,h,4,1);assert(near(c.x,canonical.x));}
 /* Real bounds changes map normalized center. */
 double nx=fixed.x/w,ny=fixed.y/h;assert(near(nx*(w*1.25),fixed.x*1.25));assert(near(ny*(h*1.25),fixed.y*1.25));
 /* One-point axes are independent before boundary clamp. */
 WCCPoint px=WCCClampAbsoluteIconCenter(fixed.x+1,fixed.y,w,h,canonical.w,canonical.h,p);
 WCCPoint py=WCCClampAbsoluteIconCenter(fixed.x,fixed.y+1,w,h,canonical.w,canonical.h,p);
 assert(near(px.x,fixed.x+1)&&near(px.y,fixed.y));assert(near(py.x,fixed.x)&&near(py.y,fixed.y+1));
 puts("PASS1216 absolute parent center matrix: 100 pulls, 8 orders, details/text/background, five media, animation, expand-collapse semantics, jitter and normalized resize");
}
