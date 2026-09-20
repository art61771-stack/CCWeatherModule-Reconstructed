// Generated from arm64 dictionary construction, jump table and pointer table.
#import "WCCContentViewController.h"
@implementation WCCContentViewController (RecoveredConditionTables)
- (NSString *)localizedConditionForCode:(NSInteger)code {
    NSArray *table = @[
        @"龙卷风", // 0
        @"热带风暴", // 1
        @"飓风", // 2
        @"强雷暴", // 3
        @"雷暴", // 4
        @"雨夹雪", // 5
        @"雨夹冰", // 6
        @"雪夹冰", // 7
        @"冻毛毛雨", // 8
        @"毛毛雨", // 9
        @"冻雨", // 10
        @"阵雨", // 11
        @"阵雨", // 12
        @"阵雪", // 13
        @"小阵雪", // 14
        @"风吹雪", // 15
        @"雪", // 16
        @"冰雹", // 17
        @"冰雨", // 18
        @"浮尘", // 19
        @"雾", // 20
        @"霾", // 21
        @"烟", // 22
        @"大风", // 23
        @"有风", // 24
        @"寒冷", // 25
        @"多云", // 26
        @"多云", // 27
        @"多云", // 28
        @"晴间多云", // 29
        @"晴间多云", // 30
        @"晴朗", // 31
        @"晴朗", // 32
        @"晴朗", // 33
        @"晴朗", // 34
        @"雨夹冰雹", // 35
        @"炎热", // 36
        @"雷阵雨", // 37
        @"雷阵雨", // 38
        @"雷阵雨", // 39
        @"阵雨", // 40
        @"大雪", // 41
        @"阵雪", // 42
        @"大雪", // 43
        @"多云", // 44
        @"雷阵雨", // 45
        @"阵雪", // 46
        @"雷阵雨", // 47
    ];
    return code >= 0 && code < 48 ? table[code] : @"--";
}
- (NSString *)sfSymbolForConditionCode:(NSInteger)code {
    NSArray *table = @[
        @"tornado", // 0
        @"hurricane", // 1
        @"hurricane", // 2
        @"cloud.bolt.rain.fill", // 3
        @"cloud.bolt.rain.fill", // 4
        @"cloud.sleet.fill", // 5
        @"cloud.sleet.fill", // 6
        @"cloud.sleet.fill", // 7
        @"cloud.rain.fill", // 8
        @"cloud.rain.fill", // 9
        @"cloud.rain.fill", // 10
        @"cloud.rain.fill", // 11
        @"cloud.rain.fill", // 12
        @"cloud.snow.fill", // 13
        @"cloud.snow.fill", // 14
        @"cloud.snow.fill", // 15
        @"cloud.snow.fill", // 16
        @"cloud.sleet.fill", // 17
        @"cloud.sleet.fill", // 18
        @"wind", // 19
        @"cloud.fog.fill", // 20
        @"cloud.fog.fill", // 21
        @"cloud.fog.fill", // 22
        @"wind", // 23
        @"wind", // 24
        @"wind", // 25
        @"cloud.fill", // 26
        @"cloud.moon.fill", // 27
        @"cloud.sun.fill", // 28
        @"cloud.moon.fill", // 29
        @"cloud.sun.fill", // 30
        @"moon.stars.fill", // 31
        @"sun.max.fill", // 32
        @"moon.stars.fill", // 33
        @"sun.max.fill", // 34
        @"cloud.sleet.fill", // 35
        @"sun.max.fill", // 36
        @"cloud.bolt.rain.fill", // 37
        @"cloud.bolt.rain.fill", // 38
        @"cloud.bolt.rain.fill", // 39
        @"cloud.rain.fill", // 40
        @"cloud.snow.fill", // 41
        @"cloud.snow.fill", // 42
        @"cloud.snow.fill", // 43
        @"cloud.sun.fill", // 44
        @"cloud.bolt.rain.fill", // 45
        @"cloud.snow.fill", // 46
        @"cloud.bolt.rain.fill", // 47
    ];
    return code >= 0 && code < 48 ? table[code] : @"cloud.fill";
}
- (NSString *)imageNameForConditionCode:(NSInteger)code {
    BOOL night = _currentCity && [_currentCity respondsToSelector:@selector(isDay)] && ![_currentCity isDay];
    NSArray *table = @[
        @"龙卷风", // 0
        @"龙卷风", // 1
        @"龙卷风", // 2
        @"雷阵雨", // 3
        @"雷阵雨", // 4
        @"雨夹雪", // 5
        @"雨夹雪", // 6
        @"雨夹雪", // 7
        @"中雨", // 8
        @"小雨-%@", // 9
        @"中雨", // 10
        @"中雨", // 11
        @"中雨", // 12
        @"小雪-%@", // 13
        @"小雪-%@", // 14
        @"中雪", // 15
        @"中雪", // 16
        @"冰雹", // 17
        @"雨夹雪", // 18
        @"浮尘", // 19
        @"雾", // 20
        @"轻度雾霾", // 21
        @"中度雾霾", // 22
        @"大风", // 23
        @"大风", // 24
        @"寒冷", // 25
        @"阴天", // 26
        @"多云-夜间", // 27
        @"多云-%@", // 28
        @"多云-夜间", // 29
        @"多云-%@", // 30
        @"晴天-夜间", // 31
        @"晴天-白天", // 32
        @"晴天-夜间", // 33
        @"晴天-白天", // 34
        @"雨夹雪", // 35
        @"炎热", // 36
        @"雷阵雨", // 37
        @"雷阵雨", // 38
        @"雷阵雨", // 39
        @"中雨", // 40
        @"大雪", // 41
        @"小雪-%@", // 42
        @"大雪", // 43
        @"多云-%@", // 44
        @"雷阵雨", // 45
        @"小雪-%@", // 46
        @"雷阵雨", // 47
    ];
    NSString *name = code >= 0 && code < 48 ? table[code] : @"多云-%@";
    return [NSString stringWithFormat:name, night ? @"夜间" : @"白天"];
}
@end
