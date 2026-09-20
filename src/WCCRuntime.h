#ifndef WCC_RUNTIME_H
#define WCC_RUNTIME_H
#include <math.h>
#include <stdint.h>
#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

/* Portable production logic: UIKit only converts these rectangles to CGRect. */
typedef struct { double x,y,w,h; } WCCRect;
typedef struct {
    WCCRect icon, city, temperature, condition, highLow, precipitation, greeting;
    double headerHeight, cityFont, tempFont, detailFont, greetingFont;
    int square, details;
} WCCGeometry;
static inline WCCRect WCCR(double x,double y,double w,double h) {
    return (WCCRect){x,y,fmax(0,w),fmax(0,h)};
}
static inline WCCGeometry WCCComputeGeometry(double width,double height,int expanded) {
    double w=fmax(0,width), h=fmax(0,height); WCCGeometry g={0};
    g.headerHeight=expanded?fmin(h,112):h;
    double hh=g.headerHeight; g.square=!expanded && hh>=w*.72;
    if (g.square) {
        double s=fmin(w/156.,hh/156.), p=12*s;
        g.city=WCCR(p,10*s,w-2*p,18*s);
        g.temperature=WCCR(p,34*s,w-2*p-58*s,44*s);
        g.icon=WCCR(w-p-52*s,32*s,52*s,52*s);
        g.condition=WCCR(p,86*s,w-2*p,15*s);
        g.highLow=WCCR(p,103*s,w-2*p,14*s);
        g.precipitation=WCCR(p,120*s,w-2*p,13*s);
        g.greeting=WCCR(p,hh-18*s,w-2*p,13*s);
        g.cityFont=14*s;g.tempFont=39*s;g.detailFont=11*s;g.greetingFont=10*s;g.details=1;
    } else {
        double s=fmin(hh/76.,w/156.), p=10*s;
        g.details=w>=220 || expanded;
        g.cityFont=13*s; g.tempFont=31*s; g.detailFont=10*s; g.greetingFont=10*s;
        if (!g.details) {
            // Compact: two weather columns plus a dedicated full-width greeting rail.
            g.city=WCCR(p,6*s,w-2*p,16*s);
            g.temperature=WCCR(p,23*s,57*s,30*s);
            g.icon=WCCR(w-p-28*s,23*s,28*s,28*s);
            g.condition=WCCR(p+60*s,29*s,w-2*p-91*s,17*s);
            g.greeting=WCCR(p,hh-18*s,w-2*p,13*s);
        } else {
            // Temperature owns the left; metadata forms a separate right-hand grid.
            double left=p+65*s, icon=36*s, x=left+icon+10*s, avail=w-p-x;
            g.temperature=WCCR(p,10*s,62*s,34*s);
            g.icon=WCCR(left,7*s,icon,icon);
            g.city=WCCR(x,6*s,avail,17*s);
            g.condition=WCCR(x,25*s,avail,14*s);
            g.highLow=WCCR(p,45*s,(w-2*p)*.58,12*s);
            g.precipitation=WCCR(p+(w-2*p)*.62,45*s,(w-2*p)*.38,12*s);
            g.greeting=WCCR(p,hh-17*s,w-2*p,12*s);
        }
    }
    return g;
}
/* Explicit cached module size: all single-row modules share adaptive rails. */
static inline WCCGeometry WCCComputeModuleGeometry(double width,double height,int expanded,int columns,int rows) {
    WCCGeometry g=WCCComputeGeometry(width,height,expanded);
    if (expanded) { g.headerHeight=85; g.greeting=WCCR(0,0,0,0); return g; }
    if (rows!=1 || columns<2 || columns>4) return g;
    double w=fmax(0,width), h=fmax(0,height), s=fmin(h/76.,w/156.);
    double p=12*s, right=w-p, usable=w-2*p;
    int compact=w<210*s;
    double leftWidth=(compact?51:65)*s, gap=(compact?4:8)*s, icon=(compact?24:32)*s;
    // Flexible metadata rail grows with the actual bounds, not nominal column count.
    double iconX=p+leftWidth+gap, textX=iconX+icon+gap, textWidth=right-textX;
    g.temperature=WCCR(p,9*s,leftWidth,32*s);
    g.highLow=compact?WCCR(0,0,0,0):WCCR(p,44*s,fmin(76*s,usable*.40),12*s);
    g.icon=WCCR(iconX,8*s,icon,icon);
    g.city=WCCR(textX,7*s,textWidth,16*s);
    g.condition=WCCR(textX,26*s,textWidth,13*s);
    g.precipitation=compact?WCCR(0,0,0,0):WCCR(right-fmin(112*s,usable*.52),44*s,fmin(112*s,usable*.52),12*s);
    g.greeting=WCCR(p,h-17*s,w-2*p,12*s);
    g.tempFont=(compact?27:29)*s; g.cityFont=(compact?11:13)*s; g.detailFont=(compact?9:10)*s; g.greetingFont=10*s;
    if (columns==3) {
        // Only 3x1: compact icon+left-aligned city/weather, no far-right text rail.
        double x=p+leftWidth+6*s, tx=x+30*s+6*s;
        g.icon=WCCR(x,9*s,30*s,30*s);
        g.city=WCCR(tx,7*s,fmin(94*s,w-p-tx),16*s);
        g.condition=WCCR(tx,26*s,fmin(94*s,w-p-tx),13*s);
        g.precipitation=WCCR(tx,44*s,w-p-tx,12*s);
        g.tempFont=31*s;
    }
    g.details=!compact; g.square=0;
    return g;
}
/* Hours are supplied by NSCalendar using the device's current time zone. */
static inline int WCCGreetingPeriod(int hour) {
    if (hour<5) return 0;
    if (hour<9) return 1;
    if (hour<12) return 2;
    if (hour<14) return 3;
    if (hour<18) return 4;
    if (hour<22) return 5;
    return 0;
}
enum { WCCGreetingVariants=8, WCCGreetingCount=48 };
static const char * const WCCGreetingPrefixes[6]={"夜深了","早安","上午好","中午好","下午好","晚上好"};
static const char * const WCCGreetingSuffixes[6][8]={
    {"记得早点休息","愿你今夜好眠","让思绪慢慢安静","给疲惫按下暂停","愿美梦如约而至","把烦恼留给昨天","为明天蓄满元气","享受这一刻宁静"},
    {"开启元气一天","愿你心情晴朗","慢慢出发也很好","吃份早餐再忙吧","让晨光带来好运","今天也值得期待","把微笑带在身边","愿一路都有好事"},
    {"愿今天顺心","忙碌之余喝点水","好心情与你相伴","一步一步慢慢来","给努力一点鼓励","记得舒展肩颈","愿灵感悄悄到来","让今天多点从容"},
    {"记得好好吃饭","歇一歇补充能量","愿午后轻松自在","给自己片刻悠闲","让美食治愈忙碌","吃饱再向前出发","愿小憩带走疲惫","留一点时间放松"},
    {"给自己一点放松","愿晴朗陪到傍晚","忙里偷闲喝杯水","让步调稍稍放缓","愿努力都有回响","看看窗外的风景","再忙也照顾自己","期待日落的小美好"},
    {"辛苦一天了","愿今晚心情温柔","卸下疲惫放松吧","享受属于你的时光","和喜欢的人聊聊","给今天一个微笑","让晚风捎走烦恼","愿灯火带来安心"}
};
static inline int WCCPickGreeting(int hour,int previous,uint32_t randomValue) {
    int base=WCCGreetingPeriod(hour)*WCCGreetingVariants;
    if (previous>=base && previous<base+WCCGreetingVariants) {
        int offset=(int)(randomValue%(WCCGreetingVariants-1));
        if (offset>=previous-base) offset++;
        return base+offset;
    }
    return base+(int)(randomValue%WCCGreetingVariants);
}
typedef struct { int active, index; } WCCGreetingState;
static inline int WCCBeginGreeting(WCCGreetingState *state,int hour,uint32_t randomValue) {
    if (!state->active || state->index<0 || state->index>=WCCGreetingCount) {
        state->index=WCCPickGreeting(hour,state->index,randomValue); state->active=1;
    }
    return state->index;
}
/* Caller must first consume a new host generation or explicit expansion edge. */
static inline int WCCPresentGreeting(WCCGreetingState *state,int hour,uint32_t randomValue) {
    state->active=0;
    return WCCBeginGreeting(state,hour,randomValue);
}
static inline void WCCEndGreeting(WCCGreetingState *state) { state->active=0; }
static inline const char *WCCGreetingPrefix(int index) {
    return index>=0 && index<WCCGreetingCount ? WCCGreetingPrefixes[index/WCCGreetingVariants] : "你好";
}
static inline const char *WCCGreetingSuffix(int index) {
    return index>=0 && index<WCCGreetingCount ? WCCGreetingSuffixes[index/WCCGreetingVariants][index%WCCGreetingVariants] : "愿你今天心情晴朗";
}
/* No writes, chmod or deletion. Reject links escaping the actual canonical root. */
typedef enum { WCCFileOK, WCCFileName, WCCFileRoot, WCCFileEscape,
    WCCFileExtension, WCCFileStat, WCCFileRegular, WCCFileEmpty,
    WCCFileLarge, WCCFileRead } WCCFileResult;
static inline WCCFileResult WCCValidateFile(const char *root,const char *name,char *out,size_t cap) {
    char base[PATH_MAX],joined[PATH_MAX],resolved[PATH_MAX];
    if (!name || !*name || strchr(name,'/') || !strcmp(name,".") || !strcmp(name,"..")) return WCCFileName;
    if (!root || !realpath(root,base)) return WCCFileRoot;
    if (snprintf(joined,sizeof(joined),"%s/%s",base,name)>=(int)sizeof(joined)) return WCCFileName;
    if (!realpath(joined,resolved)) return WCCFileStat;
    size_t n=strlen(base);
    if (strncmp(resolved,base,n) || resolved[n]!='/' || strchr(resolved+n+1,'/')) return WCCFileEscape;
    const char *ext=strrchr(resolved,'.');
    if (!ext || (strcasecmp(ext,".png") && strcasecmp(ext,".jpg") && strcasecmp(ext,".jpeg") && strcasecmp(ext,".gif") && strcasecmp(ext,".mp4"))) return WCCFileExtension;
    struct stat a;
    if (stat(resolved,&a)) return WCCFileStat;
    if (!S_ISREG(a.st_mode)) return WCCFileRegular;
    if (!a.st_size) return WCCFileEmpty;
    if (a.st_size>8*1024*1024) return WCCFileLarge;
    int fd=open(resolved,O_RDONLY); if(fd<0) return WCCFileRead;
    unsigned char byte; ssize_t count=read(fd,&byte,1); close(fd);
    if(count!=1) return WCCFileRead;
    if(strlen(resolved)+1>cap) return WCCFileName;
    memcpy(out,resolved,strlen(resolved)+1); return WCCFileOK;
}
#endif
