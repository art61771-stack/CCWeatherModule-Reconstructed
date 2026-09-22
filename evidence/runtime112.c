#include "../src/WCCRuntime.h"
#include <assert.h>
#include <dirent.h>
static void rect(WCCRect r,double w,double h) {
    assert(isfinite(r.x+r.y+r.w+r.h));
    assert(r.x>=0 && r.y>=0 && r.w>=0 && r.h>=0);
    assert(r.x+r.w<=w+.00001 && r.y+r.h<=h+.00001);
}
static int overlap(WCCRect a,WCCRect b) {
    return a.w>0 && b.w>0 && a.h>0 && b.h>0 && a.x<b.x+b.w-.001 && b.x<a.x+a.w-.001 && a.y<b.y+b.h-.001 && b.y<a.y+a.h-.001;
}
int main(int argc,char **argv) {
    if(argc==3) { char out[PATH_MAX]; printf("%d\n", WCCValidateFile(argv[1],argv[2],out,sizeof(out))); return 0; }
    if(argc==2) {
        DIR *d=opendir(argv[1]); assert(d); struct dirent *e;
        while((e=readdir(d))) { if(!strcmp(e->d_name,".")||!strcmp(e->d_name,"..")) continue;
            char out[PATH_MAX]; printf("%s\t%d\n",e->d_name,WCCValidateFile(argv[1],e->d_name,out,sizeof(out)));
        } closedir(d); return 0;
    }
    double sizes[][2]={{156,70},{238,70},{320,70},{156,156},{238,238},{130,60},{360,180},{0,0}};
    for(unsigned i=0;i<sizeof(sizes)/sizeof(*sizes);i++) for(int expanded=0;expanded<2;expanded++) {
        double w=sizes[i][0], h=sizes[i][1];
        WCCGeometry g=WCCComputeGeometry(w,h,expanded);
        WCCRect rs[]={g.icon,g.city,g.temperature,g.condition,g.highLow,g.precipitation,g.greeting};
        for(int j=0;j<7;j++) { rect(rs[j],w,g.headerHeight); for(int k=j+1;k<7;k++) assert(!overlap(rs[j],rs[k])); }
        assert(g.icon.w==g.icon.h);
        if (w>0 && h>0 && (g.square || w>=220 || expanded)) {
            assert(g.details && g.highLow.w>0 && g.highLow.h>0);
            assert(g.precipitation.w>0 && g.precipitation.h>0);
            assert(g.greeting.y>=g.precipitation.y+g.precipitation.h);
            assert(g.greetingFont<g.detailFont);
        }
        for(int cycle=0;cycle<100;cycle++) {
            WCCComputeGeometry(w,h,!expanded);
            WCCGeometry again=WCCComputeGeometry(w,h,expanded);
            assert(again.icon.w==g.icon.w && again.icon.h==g.icon.h && again.greeting.y==g.greeting.y);
        }
    }
    int expected[]={0,0,0,0,0,1,1,1,1,2,2,2,3,3,4,4,4,4,5,5,5,5,0,0};
    int previous=-1;
    for(int hour=0;hour<24;hour++) {
        assert(WCCGreetingPeriod(hour)==expected[hour]);
        for(int i=0;i<1000;i++) {
            int index=WCCPickGreeting(hour,previous,(uint32_t)i);
            assert(index/3==expected[hour] && index!=previous);
            assert(strlen(WCCGreetingText(index))>0); previous=index;
        }
        for(int old=-1;old<18;old++) {
            int counts[18]={0}; for(int r=0;r<6;r++) counts[WCCPickGreeting(hour,old,r)]++;
            for(int n=expected[hour]*3;n<expected[hour]*3+3;n++)
                assert(counts[n]==(old==n?0:(old/3==expected[hour] && old>=0 ? 3:2)));
        }
    }
    puts("PASS: bounds/non-overlap, square media, 100 transition cycles, 24h greeting boundaries and no-repeat distribution");
    return 0;
}
