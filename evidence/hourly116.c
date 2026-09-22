#include "../src/WCCHourly.h"
#include "../src/WCCABI.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
 char out[128], expected[128];
 for(int code=0;code<48;code++) for(int daylight=0;daylight<=1;daylight++) {
  assert(WCCHourlyAsset(code,daylight,out,sizeof(out)));
  WCCAssetBasename(code,!daylight,expected,sizeof(expected));assert(!strcmp(out,expected));
 }
 for(int code=0;code<48;code++) {
  int ambiguous=strstr(WCCAssetTemplate(code),"%@")!=NULL;
  assert(WCCHourlyAsset(code,-1,out,sizeof(out))==!ambiguous);
 }
 assert(!WCCHourlyAsset(-1,0,out,sizeof(out)));
 assert(!WCCHourlyAsset(48,1,out,sizeof(out)));
 WCCHourlyAsset(31,1,out,sizeof(out));assert(!strcmp(out,"晴天-夜间"));
 WCCHourlyAsset(32,0,out,sizeof(out));assert(!strcmp(out,"晴天-白天"));
 const char *args[]={"@",":"};
 assert(WCCABICompatible("B","B",2,args,0,NULL));
 assert(WCCABICompatible("c","c",2,args,0,NULL));
 assert(!WCCABICompatible("@","B",2,args,0,NULL));
 assert(!WCCABICompatible("q","B",2,args,0,NULL));
 assert(!WCCABICompatible("B","B",3,args,0,NULL));
 for(int left=0;left<700;left+=5) {
  int visible=0,playing=0;
  for(int i=0;i<12;i++) if(WCCHourlyIntersects(12+i*55,55,left,360)) {
   visible++;playing+=WCCHourlyAdmit(1,1);
  }
  assert(playing==visible);
  if(left==0) assert(playing>=6);
 }
 // Exercise all twelve, partial intersections, offscreen unload, return and collapse.
 for(int cycle=0;cycle<1000;cycle++) {
  int bound[12]={0},generation[12]={0};
  const int widths[]={660,360,360,660,0,660};
  const int lefts[]={12,40,700,12,12,12};
  for(int step=0;step<6;step++) {
   int count=0;
   for(int i=0;i<12;i++) {
    int wanted=WCCHourlyAdmit(WCCHourlyIntersects(12+i*55,55,lefts[step],widths[step]),1);
    if(bound[i]!=wanted) { bound[i]=wanted; generation[i]++; }
    int stable=generation[i];
    assert(bound[i]==WCCHourlyAdmit(WCCHourlyIntersects(12+i*55,55,lefts[step],widths[step]),1));
    assert(generation[i]==stable); count+=bound[i];
   }
   if(step==0 || step==3 || step==5) assert(count==12);
   if(step==1) assert(count>=6);
   if(step==2 || step==4) assert(count==0);
  }
 }
 assert(!WCCMediaCallbackCurrent(9,9,0)); // same generation, obsolete KVO object
 assert(!WCCHourlyIntersects(12,55,67,360));
 assert(!WCCHourlyIntersects(372,55,12,360));
 assert(WCCMediaCallbackCurrent(9,9,1));assert(!WCCMediaCallbackCurrent(8,9,1));
 puts("PASS production hourly: 96 explicit daylight mappings, 48 unknown-daylight fallbacks, strict getter ABI, all visible items admitted including 6+ animations; no fixed playback quota, stale-generation rejection. UIKit / iOS16.6 NOT RUN.");
 return 0;
}
