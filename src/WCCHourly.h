#ifndef WCC_HOURLY_H
#define WCC_HOURLY_H
#include "WCCAssetKeys.h"
/* daylight=-1 means the forecast supplies no ABI-checked daylight value.
 * Never substitute the CURRENT city's isDay or device wall clock for a future
 * forecast. Fixed day/night codes remain exact recovered resource basenames.
 * An ambiguous %@ template falls back to the original system condition glyph.
 */
static inline int WCCHourlyAsset(int code,int daylight,char *out,size_t size) {
    if (code<0 || code>=48) return 0;
    if (daylight<0 && strstr(WCCAssetTemplate(code),"%@")) return 0;
    WCCAssetBasename(code,daylight==0,out,size); return 1;
}
/* Layout/window admission gate shared by UIKit and lifecycle regression tests. */
static inline int WCCHourlyLayoutReady(int expanded,int mediaVisible,int suspended,
        int hostWindow,int scrollWindow,int presented,double width,double height) {
    return expanded && mediaVisible && !suspended && hostWindow && scrollWindow &&
        !presented && width>0 && height>0;
}
/* Half-open intersection avoids starting adjacent, fully clipped cells. */
static inline int WCCHourlyIntersects(double x,double width,double left,double visibleWidth) {
    return width>0 && visibleWidth>0 && x+width>left && x<left+visibleWidth;
}
/* Visibility is the only admission budget. Preparation is serialized by media;
 * no persistent playback quota may starve a later visible forecast. */
static inline int WCCHourlyAdmit(int visible,int hasPath) {
    return visible && hasPath;
}
#endif
