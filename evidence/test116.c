#include "../src/WCCRuntime.h"
#include "../src/WCCHourly.h"
#include <assert.h>
static int overlap(WCCRect a,WCCRect b) { return a.x<b.x+b.w && a.x+a.w>b.x && a.y<b.y+b.h && a.y+a.h>b.y; }
int main(void) {
    for(int w=240;w<=420;w+=20) {
        WCCGeometry g=WCCComputeModuleGeometry(w,76,0,3,1);
        double old=12+65+6;
        assert(g.icon.x>=old && g.icon.x<=old+(w-12-old-130)*.55);
        assert(w-(g.city.x+g.city.w)>12);
        assert(g.temperature.x==12 && g.tempFont==31);
        assert(g.city.x==g.icon.x+36 && g.city.x+g.city.w<=w-12);
        assert(!overlap(g.temperature,g.icon));
        // Expanded fixtures approximate UIKit intrinsic font metrics. Production
        // uses ACTUAL resolved frames instead; fixture values are not UI proof.
        WCCRect occupied[]={WCCR(16,15,55,55),WCCR(89,12,w-170,22),WCCR(89,36,100,16),WCCR(89,54,110,15),WCCR(w-100,10,84,46),WCCR(w-110,56,94,16)};
        WCCRect r=WCCExpandedGreeting(w,occupied,6);
        assert(r.w>0 && r.h==10 && r.y+r.h<=85 && r.x>=16 && r.x+r.w<=w-16);
        for(int i=0;i<6;i++) assert(!overlap(r,occupied[i]));
        if(w==320) {
            printf("<svg xmlns='http://www.w3.org/2000/svg' width='640' height='360' viewBox='0 0 320 180'><rect width='320' height='180' fill='#203044'/><path d='M16 85H304' stroke='white'/>");
            for(int i=0;i<6;i++) printf("<rect x='%g' y='%g' width='%g' height='%g' fill='none' stroke='#88bbee'/>",occupied[i].x,occupied[i].y,occupied[i].w,occupied[i].h);
            printf("<rect x='%g' y='%g' width='%g' height='%g' fill='#408850'/><text x='%g' y='%g' fill='white' font-size='8'>Greeting (tail truncated)</text><text x='16' y='110' fill='white' font-size='10'>Hourly: unchanged y=85; header=85 total=180</text></svg>\n",r.x,r.y,r.w,r.h,r.x,r.y+8);
        }
    }
    for(int round=0;round<1000;round++) {
        int accepted=0;
        for(int i=0;i<12;i++) accepted+=WCCHourlyAdmit(1,1);
        assert(accepted==12);
        assert(WCCHourlyAdmit(1,1));
        assert(!WCCHourlyAdmit(0,1));
        assert(!WCCHourlyAdmit(1,0));
    }
    assert(!WCCHourlyIntersects(55,55,0,55));
    assert(WCCHourlyIntersects(54,55,0,55));
    char name[128],expected[128];
    for(int code=0;code<48;code++) for(int day=-1;day<=1;day++) {
        int ok=WCCHourlyAsset(code,day,name,sizeof(name));
        if(day<0 && strstr(WCCAssetTemplate(code),"%@")) assert(!ok);
        else { WCCAssetBasename(code,day==0,expected,sizeof(expected)); assert(ok && !strcmp(name,expected)); }
    }
    return 0;
}
