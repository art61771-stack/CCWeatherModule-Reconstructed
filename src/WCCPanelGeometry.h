#ifndef WCC_PANEL_GEOMETRY_H
#define WCC_PANEL_GEOMETRY_H
#include <math.h>
static inline double WCCPanelUnit(double n) { return isfinite(n)?fmax(0,fmin(1,n)):0.5; }
static inline double WCCPanelOrigin(double start,double available,double size,double unit) {
    return start+fmax(0,available-size)*WCCPanelUnit(unit);
}
static inline double WCCPanelPosition(double origin,double start,double available,double size) {
    return available>size?WCCPanelUnit((origin-start)/(available-size)):0.5;
}
/* Only a title-bar touch which isn't a control may start a drag. */
static inline int WCCPanelCanDrag(int title,int control,int fingers) { return title && !control && fingers==1; }
#endif
