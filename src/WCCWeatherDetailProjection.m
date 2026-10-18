#import "WCCWeatherDetailProjection.h"
NSDictionary<NSString *,NSString *> *WCCProjectWeatherText(NSString *condition,NSString *precipitation,NSString *details,NSString *outlook,BOOL enabled) {
    condition=[condition isKindOfClass:NSString.class]?condition:@"";
    precipitation=[precipitation isKindOfClass:NSString.class]?precipitation:@"";
    details=[details isKindOfClass:NSString.class]?details:@"";
    outlook=[outlook isKindOfClass:NSString.class]?outlook:@"";
    return @{ @"condition":enabled && details.length?[NSString stringWithFormat:@"%@ · %@",condition,details]:condition,
              @"precipitation":enabled && outlook.length?[NSString stringWithFormat:@"%@ · %@",outlook,precipitation]:precipitation };
}
