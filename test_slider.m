#import <Foundation/Foundation.h>
#import "WCCRuntime.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        // Test WCCNormalizeRegionOffset
        NSLog(@"WCCNormalizeRegionOffset(-50) = %f", WCCNormalizeRegionOffset(-50));
        NSLog(@"WCCNormalizeRegionOffset(-40) = %f", WCCNormalizeRegionOffset(-40));
        NSLog(@"WCCNormalizeRegionOffset(-10) = %f", WCCNormalizeRegionOffset(-10));
        NSLog(@"WCCNormalizeRegionOffset(0) = %f", WCCNormalizeRegionOffset(0));
        NSLog(@"WCCNormalizeRegionOffset(10) = %f", WCCNormalizeRegionOffset(10));
        NSLog(@"WCCNormalizeRegionOffset(40) = %f", WCCNormalizeRegionOffset(40));
        NSLog(@"WCCNormalizeRegionOffset(50) = %f", WCCNormalizeRegionOffset(50));
        
        // Test WCCNormalizePositionOffset for horizontal (index 0, limit 1366)
        NSLog(@"WCCNormalizePositionOffset(0, -1500) = %f", WCCNormalizePositionOffset(0, -1500));
        NSLog(@"WCCNormalizePositionOffset(0, -1366) = %f", WCCNormalizePositionOffset(0, -1366));
        NSLog(@"WCCNormalizePositionOffset(0, -100) = %f", WCCNormalizePositionOffset(0, -100));
        NSLog(@"WCCNormalizePositionOffset(0, 0) = %f", WCCNormalizePositionOffset(0, 0));
        NSLog(@"WCCNormalizePositionOffset(0, 100) = %f", WCCNormalizePositionOffset(0, 100));
        NSLog(@"WCCNormalizePositionOffset(0, 1366) = %f", WCCNormalizePositionOffset(0, 1366));
        NSLog(@"WCCNormalizePositionOffset(0, 1500) = %f", WCCNormalizePositionOffset(0, 1500));
        
        // Test WCCNormalizePositionOffset for vertical (index 1, limit 40)
        NSLog(@"WCCNormalizePositionOffset(1, -50) = %f", WCCNormalizePositionOffset(1, -50));
        NSLog(@"WCCNormalizePositionOffset(1, -40) = %f", WCCNormalizePositionOffset(1, -40));
        NSLog(@"WCCNormalizePositionOffset(1, -10) = %f", WCCNormalizePositionOffset(1, -10));
        NSLog(@"WCCNormalizePositionOffset(1, 0) = %f", WCCNormalizePositionOffset(1, 0));
        NSLog(@"WCCNormalizePositionOffset(1, 10) = %f", WCCNormalizePositionOffset(1, 10));
        NSLog(@"WCCNormalizePositionOffset(1, 40) = %f", WCCNormalizePositionOffset(1, 40));
        NSLog(@"WCCNormalizePositionOffset(1, 50) = %f", WCCNormalizePositionOffset(1, 50));
        
        // Test invalid index
        NSLog(@"WCCNormalizePositionOffset(-1, 10) = %f", WCCNormalizePositionOffset(-1, 10));
        NSLog(@"WCCNormalizePositionOffset(8, 10) = %f", WCCNormalizePositionOffset(8, 10));
        
        // Test slider percent functions
        NSLog(@"WCCCollapsedSliderPercent(-1.0) = %f", WCCCollapsedSliderPercent(-1.0));
        NSLog(@"WCCCollapsedSliderPercent(-0.5) = %f", WCCCollapsedSliderPercent(-0.5));
        NSLog(@"WCCCollapsedSliderPercent(0.0) = %f", WCCCollapsedSliderPercent(0.0));
        NSLog(@"WCCCollapsedSliderPercent(0.5) = %f", WCCCollapsedSliderPercent(0.5));
        NSLog(@"WCCCollapsedSliderPercent(1.0) = %f", WCCCollapsedSliderPercent(1.0));
    }
    return 0;
}
