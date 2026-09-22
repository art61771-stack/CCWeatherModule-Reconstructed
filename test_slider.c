#include <math.h>
#include <stdio.h>
#define isfinite(x) ((x)==(x) && (x)!=HUGE_VAL && (x)!=-HUGE_VAL)

static inline double WCCNormalizeRegionOffset(double value) {
    return isfinite(value) ? round(fmax(-40, fmin(40, value))) : 0;
}
enum { WCCMaximumHorizontalOffset = 1366 };
static inline double WCCNormalizePositionOffset(int index,double value) {
    double limit=(index%2)==0 ? WCCMaximumHorizontalOffset : 40;
    return index>=0 && index<8 && isfinite(value) ? round(fmax(-limit, fmin(limit, value))) : 0;
}
static inline double WCCNormalizeIconPercentForMode(int expanded,double value) {
    if (!isfinite(value) || value<50 || value>(expanded?150:250)) return 100;
    return round(value/5)*5;
}
static inline double WCCCollapsedSliderPercent(double position) {
    position=fmax(-1,fmin(1,position));
    return WCCNormalizeIconPercentForMode(0,100+position*(position<0?50:150));
}

int main() {
    // Test WCCNormalizeRegionOffset
    printf("WCCNormalizeRegionOffset(-50) = %f\n", WCCNormalizeRegionOffset(-50));
    printf("WCCNormalizeRegionOffset(-40) = %f\n", WCCNormalizeRegionOffset(-40));
    printf("WCCNormalizeRegionOffset(-10) = %f\n", WCCNormalizeRegionOffset(-10));
    printf("WCCNormalizeRegionOffset(0) = %f\n", WCCNormalizeRegionOffset(0));
    printf("WCCNormalizeRegionOffset(10) = %f\n", WCCNormalizeRegionOffset(10));
    printf("WCCNormalizeRegionOffset(40) = %f\n", WCCNormalizeRegionOffset(40));
    printf("WCCNormalizeRegionOffset(50) = %f\n", WCCNormalizeRegionOffset(50));
    
    // Test WCCNormalizePositionOffset for horizontal (index 0, limit 1366)
    printf("WCCNormalizePositionOffset(0, -1500) = %f\n", WCCNormalizePositionOffset(0, -1500));
    printf("WCCNormalizePositionOffset(0, -1366) = %f\n", WCCNormalizePositionOffset(0, -1366));
    printf("WCCNormalizePositionOffset(0, -100) = %f\n", WCCNormalizePositionOffset(0, -100));
    printf("WCCNormalizePositionOffset(0, 0) = %f\n", WCCNormalizePositionOffset(0, 0));
    printf("WCCNormalizePositionOffset(0, 100) = %f\n", WCCNormalizePositionOffset(0, 100));
    printf("WCCNormalizePositionOffset(0, 1366) = %f\n", WCCNormalizePositionOffset(0, 1366));
    printf("WCCNormalizePositionOffset(0, 1500) = %f\n", WCCNormalizePositionOffset(0, 1500));
    
    // Test WCCNormalizePositionOffset for vertical (index 1, limit 40)
    printf("WCCNormalizePositionOffset(1, -50) = %f\n", WCCNormalizePositionOffset(1, -50));
    printf("WCCNormalizePositionOffset(1, -40) = %f\n", WCCNormalizePositionOffset(1, -40));
    printf("WCCNormalizePositionOffset(1, -10) = %f\n", WCCNormalizePositionOffset(1, -10));
    printf("WCCNormalizePositionOffset(1, 0) = %f\n", WCCNormalizePositionOffset(1, 0));
    printf("WCCNormalizePositionOffset(1, 10) = %f\n", WCCNormalizePositionOffset(1, 10));
    printf("WCCNormalizePositionOffset(1, 40) = %f\n", WCCNormalizePositionOffset(1, 40));
    printf("WCCNormalizePositionOffset(1, 50) = %f\n", WCCNormalizePositionOffset(1, 50));
    
    // Test invalid index
    printf("WCCNormalizePositionOffset(-1, 10) = %f\n", WCCNormalizePositionOffset(-1, 10));
    printf("WCCNormalizePositionOffset(8, 10) = %f\n", WCCNormalizePositionOffset(8, 10));
    
    // Test slider percent functions
    printf("WCCCollapsedSliderPercent(-1.0) = %f\n", WCCCollapsedSliderPercent(-1.0));
    printf("WCCCollapsedSliderPercent(-0.5) = %f\n", WCCCollapsedSliderPercent(-0.5));
    printf("WCCCollapsedSliderPercent(0.0) = %f\n", WCCCollapsedSliderPercent(0.0));
    printf("WCCCollapsedSliderPercent(0.5) = %f\n", WCCCollapsedSliderPercent(0.5));
    printf("WCCCollapsedSliderPercent(1.0) = %f\n", WCCCollapsedSliderPercent(1.0));
    
    return 0;
}
