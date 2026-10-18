#include <assert.h>
#include <math.h>
#include <stdio.h>

typedef struct { double a,b,c,d,tx,ty; } M;
typedef struct { double x,y; } P;
static P apply(M m,P p){return (P){m.a*p.x+m.c*p.y+m.tx,m.b*p.x+m.d*p.y+m.ty};}
static M mul(M x,M y){return (M){x.a*y.a+x.c*y.b,x.b*y.a+x.d*y.b,x.a*y.c+x.c*y.d,x.b*y.c+x.d*y.d,x.a*y.tx+x.c*y.ty+x.tx,x.b*y.tx+x.d*y.ty+x.ty};}
static M st(double sx,double sy,double tx,double ty){return (M){sx,0,0,sy,tx,ty};}
static M centered(double s,double cx,double cy){return mul(st(1,1,cx,cy),mul(st(s,s,0,0),st(1,1,-cx,-cy)));}
static void near(P a,P b){assert(fabs(a.x-b.x)<1e-9);assert(fabs(a.y-b.y)<1e-9);}
int main(void){
 const double pct[]={.5,1,2,2.5}, xy[]={-260,-80,0,75,260}, breath[]={.9,1.1};
 P local={27.5,27.5};
 for(unsigned p=0;p<4;p++)for(unsigned ix=0;ix<5;ix++)for(unsigned iy=0;iy<5;iy++){
  M parent=st(pct[p],pct[p],xy[ix],xy[iy]); P expected=apply(parent,local);
  for(unsigned e=0;e<2;e++){
   /* 1.2.9: child bounds-center scaling, then parent placement. */
   near(apply(mul(parent,centered(breath[e],local.x,local.y)),local),expected);
   /* 1.2.8 reproduction: additive scale composed on translated parent drifts. */
   P old=apply(mul(st(breath[e],breath[e],0,0),parent),local);
   if((xy[ix]||xy[iy]) && breath[e]!=1)assert(fabs(old.x-expected.x)>1e-6||fabs(old.y-expected.y)>1e-6);
  }
  for(int cycle=0;cycle<100;cycle++){near(apply(mul(parent,centered(.9,local.x,local.y)),local),expected);near(apply(mul(parent,centered(1.1,local.x,local.y)),local),expected);near(apply(parent,local),expected);}
 }
 puts("PASS129 matrix presentation center: old translated-parent additive scale reproduces drift; child non-additive center scale stays fixed for 50-250%, 4x1 +/-XY, .9/1.1 endpoints and 100 stop cycles.");
 return 0;
}
