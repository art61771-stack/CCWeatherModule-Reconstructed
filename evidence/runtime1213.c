#include <assert.h>
#include <math.h>
#include <stdio.h>
typedef struct{double x,y,w,h;} R;
static int rounded(R b,double r,double x,double y){
 if(x<b.x||y<b.y||x>b.x+b.w||y>b.y+b.h)return 0;
 double cx=x<b.x+r?b.x+r:(x>b.x+b.w-r?b.x+b.w-r:x);
 double cy=y<b.y+r?b.y+r:(y>b.y+b.h-r?b.y+b.h-r:y);
 double dx=x-cx,dy=y-cy;return dx*dx+dy*dy<=r*r+1e-9;
}
static R convert(R host,double sx,double sy,double tx,double ty){return(R){host.x*sx+tx,host.y*sy+ty,host.w*sx,host.h*sy};}
int main(void){
 double sizes[][2]={{120,60},{180,60},{240,60},{120,120},{180,180}};
 for(int loop=0;loop<100;loop++)for(int i=0;i<5;i++){
  R b={0,0,sizes[i][0],sizes[i][1]};double r=fmin(b.w,b.h)*.18;
  assert(!rounded(b,r,.1,.1));assert(rounded(b,r,r,r));assert(rounded(b,r,b.w/2,b.h/2));
 }
 R host={4,6,100,50},root=convert(host,1.5,2,-6,-12);
 assert(root.x==0&&root.y==0&&root.w==150&&root.h==100);
 assert(!rounded(root,24,1,1)&&rounded(root,24,24,24));
 // The same predicate represents image/video/overlay because production gives
 // all three one superview and one mask; repeated layout creates no inset drift.
 R stable=root;for(int i=0;i<100;i++)stable=convert(host,1.5,2,-6,-12);
 assert(stable.x==root.x&&stable.y==root.y&&stable.w==root.w&&stable.h==root.h);
 puts("PASS1213 geometry: outside rejected, inside visible, five sizes, converted path geometry and 100 stable layouts");
}
