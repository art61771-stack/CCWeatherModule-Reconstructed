#ifndef WCC_REFRESH_POLICY_H
#define WCC_REFRESH_POLICY_H
#include <math.h>
static inline double WCCRefreshTTL(int hours) { return hours==1 || hours==12 || hours==24 ? hours*3600. : 900.; }
static inline double WCCRefreshDelay(double age,double ttl,double retry) {
    double remaining=isfinite(age) && age>=0 ? ttl-age : 0;
    return fmax(1,fmax(remaining,retry));
}
/* Full breathe cycle: center=3s; left=6s, right=1.5s. */
static inline double WCCBreathDuration(double speed) { return 3*pow(2,-fmax(-1,fmin(1,speed))); }
/* Independent 124 standard for both shadow/glow, with right-side headroom.
 * Legacy 123 used .9 / 1: the new midpoint is deliberately lighter.
 * Picker alpha multiplies this opacity in compositing, never changes hue. */
static const double WCCEffectStandardOpacity124 = .6;
static inline double WCCEffectOpacity(double standard,double density) {
    density=isfinite(density)?fmax(-1,fmin(1,density)):0;
    return density<=0 ? standard*(1+density) : standard+(1-standard)*density;
}
static inline double WCCEffectLow(double high,double standard) {
    return fmax(0,fmin(high,standard>0?high*.2/standard:0));
}
#endif
