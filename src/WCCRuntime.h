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
    double w=fmax(0,width), h=fmax(0,height);
    WCCGeometry g={0};
    g.headerHeight=expanded ? fmin(h,94) : h;
    double hh=g.headerHeight;
    g.square=!expanded && hh>=w*.72;
    if (g.square) {
        double s=fmin(w/156.,hh/156.), pad=12*s, icon=54*s;
        g.icon=WCCR(pad,12*s,icon,icon);
        g.temperature=WCCR(pad+icon+6*s,18*s,w-2*pad-icon-6*s,40*s);
        g.city=WCCR(pad,70*s,w-2*pad,18*s);
        g.condition=WCCR(pad,90*s,w-2*pad,14*s);
        g.highLow=WCCR(pad,106*s,w-2*pad,14*s);
        g.precipitation=WCCR(pad,122*s,w-2*pad,13*s);
        g.greeting=WCCR(pad,hh-18*s,w-2*pad,12*s);
        g.cityFont=16*s; g.tempFont=32*s; g.detailFont=12*s; g.greetingFont=11*s;
        g.details=1;
    } else {
        double s=fmin(hh/76.,w/156.), pad=10*s, gap=7*s;
        double icon=fmin(48*s,w*.22), x=pad+icon+gap;
        double temp=fmin(78*s,w*.27), right=w-pad-temp;
        g.icon=WCCR(pad,(hh-icon)/2,icon,icon);
        g.city=WCCR(x,hh*.12,right-gap-x,19*s);
        g.temperature=WCCR(right,hh*.10,temp,34*s);
        g.condition=WCCR(x,hh*.40,right-gap-x,15*s);
        g.greeting=WCCR(x,hh*.70,w-pad-x,15*s);
        g.highLow=WCCR(0,0,0,0); g.precipitation=WCCR(0,0,0,0);
        g.cityFont=14*s; g.tempFont=28*s; g.detailFont=11*s; g.greetingFont=10*s;
        g.details=0;
        if (w>=220 || expanded) {
            // Weather owns the first three rows; greeting remains secondary.
            g.city=WCCR(x,hh*.06,w-pad-x,16*s);
            g.condition=WCCR(x,hh*.31,right-gap-x,14*s);
            g.temperature=WCCR(right,hh*.28,temp,20*s);
            g.highLow=WCCR(x,hh*.55,(w-pad-x)*.46,12*s);
            g.precipitation=WCCR(x+(w-pad-x)*.48,hh*.55,(w-pad-x)*.52,12*s);
            g.greeting=WCCR(x,hh*.79,w-pad-x,11*s);
            g.tempFont=23*s; g.greetingFont=9*s;
            g.details=1;
        }
    }
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
static const char * const WCCGreetings[6][3]={
    {"夜深了，记得早点休息","愿你今夜好眠","放慢脚步，好好休息"},
    {"早安，开启元气一天","清晨好，愿你心情晴朗","新的一天，慢慢出发"},
    {"上午好，愿今天顺心","忙碌之余，记得喝水","愿好心情与你相伴"},
    {"中午好，记得好好吃饭","午间歇一歇，补充能量","愿午后的你轻松自在"},
    {"下午好，给自己一点放松","愿这份晴朗陪你到傍晚","忙里偷闲，喝杯水吧"},
    {"晚上好，辛苦一天了","愿今晚有温柔的好心情","卸下一天疲惫，放松一下"}
};
static inline int WCCPickGreeting(int hour,int previous,uint32_t randomValue) {
    int base=WCCGreetingPeriod(hour)*3;
    if (previous>=base && previous<base+3) {
        int offset=(int)(randomValue%2);
        if (offset>=previous-base) offset++;
        return base+offset;
    }
    return base+(int)(randomValue%3);
}
static inline const char *WCCGreetingText(int index) {
    return WCCGreetings[index/3][index%3];
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
