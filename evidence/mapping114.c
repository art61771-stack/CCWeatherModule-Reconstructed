#include "../src/WCCAssetKeys.h"
#include <assert.h>
int main(void) {
 char a[128],b[128]; int n=0;
 for(int code=-2;code<50;code++) for(int night=0;night<2;night++) {
  WCCAssetBasename(code,night,a,sizeof a); assert(*a && !strstr(a,"%@")); n++;
 }
 WCCAssetBasename(9,0,a,sizeof a); WCCAssetBasename(9,1,b,sizeof b);
 assert(!strcmp(a,"小雨-白天") && !strcmp(b,"小雨-夜间"));
 WCCAssetBasename(32,1,a,sizeof a); assert(!strcmp(a,"晴天-白天"));
 WCCAssetBasename(31,0,a,sizeof a); assert(!strcmp(a,"晴天-夜间"));
 WCCAssetBasename(44,0,a,sizeof a); WCCAssetBasename(44,1,b,sizeof b); assert(strcmp(a,b));
 for(unsigned long generation=0;generation<100;generation++) for(unsigned long captured=0;captured<100;captured++) for(int match=0;match<2;match++) assert(WCCMediaCallbackCurrent(captured,generation,match)==(captured==generation && match));
 printf("PASS %d production basename cases; 20000 generation/object callback guards. AVFoundation device runtime NOT RUN.\n",n);
}
