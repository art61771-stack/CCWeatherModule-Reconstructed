// Exact recovered resource templates; shared by runtime and production tests.
#ifndef WCC_ASSET_KEYS_H
#define WCC_ASSET_KEYS_H
#include <stdio.h>
#include <string.h>
static const char * const WCCAssetTemplates[48] = {
    "龙卷风",
    "龙卷风",
    "龙卷风",
    "雷阵雨",
    "雷阵雨",
    "雨夹雪",
    "雨夹雪",
    "雨夹雪",
    "中雨",
    "小雨-%@",
    "中雨",
    "中雨",
    "中雨",
    "小雪-%@",
    "小雪-%@",
    "中雪",
    "中雪",
    "冰雹",
    "雨夹雪",
    "浮尘",
    "雾",
    "轻度雾霾",
    "中度雾霾",
    "大风",
    "大风",
    "寒冷",
    "阴天",
    "多云-夜间",
    "多云-%@",
    "多云-夜间",
    "多云-%@",
    "晴天-夜间",
    "晴天-白天",
    "晴天-夜间",
    "晴天-白天",
    "雨夹雪",
    "炎热",
    "雷阵雨",
    "雷阵雨",
    "雷阵雨",
    "中雨",
    "大雪",
    "小雪-%@",
    "大雪",
    "多云-%@",
    "雷阵雨",
    "小雪-%@",
    "雷阵雨",
};
static inline const char *WCCAssetTemplate(int code) { return code>=0 && code<48 ? WCCAssetTemplates[code] : "多云-%@"; }
static inline void WCCAssetBasename(int code, int night, char *out, size_t count) {
    const char *t=WCCAssetTemplate(code), *slot=strstr(t,"%@");
    if (slot) snprintf(out,count,"%.*s%s",(int)(slot-t),t,night?"夜间":"白天");
    else snprintf(out,count,"%s",t);
}
static inline int WCCMediaCallbackCurrent(unsigned long captured, unsigned long current, int objectMatches) {
    return captured==current && objectMatches;
}
#endif
