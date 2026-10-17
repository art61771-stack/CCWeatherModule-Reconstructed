#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "../src/WCCSystemWeatherDetails.h"
#include <assert.h>
#include <math.h>

@interface MockHour:NSObject @property NSDate *date; @property NSInteger conditionCode; @end
@implementation MockHour @end
@interface MockCity:NSObject @property float windDirection,windSpeed,humidity; @property NSArray *hourlyForecasts; @property NSTimeZone *timeZone; @end
@implementation MockCity @end
@interface Missing:NSObject @end @implementation Missing @end
@interface NumberCity:NSObject @property NSNumber *windDirection,*humidity; @property NSArray *hourlyForecasts; @end
@implementation NumberCity @end
@interface BadCity:NSObject @end
@implementation BadCity
- (NSRange)windDirection{return NSMakeRange(0,0);}
- (NSString *)humidity{return @"50";}
- (NSString *)hourlyForecasts{return @"bad";}
@end
static MockHour *H(NSDate *d,NSInteger code){MockHour*h=[MockHour new];h.date=d;h.conditionCode=code;return h;}
static NSString *NameFunction(NSInteger code){return code==1?@"晴":code==2?@"多云":@"";}
int main(void){@autoreleasepool{
 WCCSystemConditionName Name=^NSString *(NSInteger code){return NameFunction(code);};
 NSDate *now=[NSDate dateWithTimeIntervalSince1970:1767225600];
 NSDictionary*r=WCCRenderSystemWeatherDetails([Missing new],now,Name);assert([r[@"details"] isEqual:@""]&&[r[@"outlook"] isEqual:@""]);
 MockCity*c=[MockCity new];c.timeZone=[NSTimeZone timeZoneWithName:@"Asia/Shanghai"];c.windDirection=0;c.windSpeed=12;c.humidity=.45;
 c.hourlyForecasts=@[H(now,1),H([now dateByAddingTimeInterval:3600],1),H([now dateByAddingTimeInterval:7200],2)];
 r=WCCRenderSystemWeatherDetails(c,now,Name);assert([r[@"details"] isEqual:@"北风 · 湿度45%"]);assert([r[@"outlook"] hasPrefix:@"未来3小时 "]);assert([r[@"outlook"] containsString:@"晴 / 多云"]);assert(![r[@"details"] containsString:@"12"]); // unit intentionally unproven
 c.windDirection=360;c.humidity=50;r=WCCRenderSystemWeatherDetails(c,now,Name);assert([r[@"details"] isEqual:@"北风 · 湿度50%"]);
 NumberCity*n=[NumberCity new];n.windDirection=@135;n.humidity=@.98;n.hourlyForecasts=@[];r=WCCRenderSystemWeatherDetails(n,now,Name);assert([r[@"details"] isEqual:@"东南风 · 湿度98%"]);
 c.windDirection=-1;c.humidity=101;r=WCCRenderSystemWeatherDetails(c,now,Name);assert([r[@"details"] isEqual:@""]);
 r=WCCRenderSystemWeatherDetails([BadCity new],now,Name);assert([r[@"details"] isEqual:@""]&&[r[@"outlook"] isEqual:@""]);
 c.windDirection=90;c.humidity=.5;c.hourlyForecasts=@[H([now dateByAddingTimeInterval:7200],1)];r=WCCRenderSystemWeatherDetails(c,now,Name);assert([r[@"outlook"] isEqual:@""]);
 c.hourlyForecasts=@[H(now,1),H([now dateByAddingTimeInterval:7200],2)];r=WCCRenderSystemWeatherDetails(c,now,Name);assert([r[@"outlook"] hasPrefix:@"未来1小时 "]);
 NSMutableArray*a=[NSMutableArray array];for(int i=0;i<30;i++)[a addObject:H([now dateByAddingTimeInterval:i*3600],1)];c.hourlyForecasts=a;r=WCCRenderSystemWeatherDetails(c,now,Name);assert([r[@"outlook"] hasPrefix:@"未来24小时 "]);
 NSDictionary*cleared=WCCRenderSystemWeatherDetails(nil,now,Name);assert([cleared[@"details"] isEqual:@""]&&[cleared[@"outlook"] isEqual:@""]);
 puts("PASS126 production runtime helper: selector present/missing, NSNumber/raw float/invalid signatures, humidity fractions/percent, 0/360 direction, unproven speed omitted, contiguous future hours/gaps/short forecasts/timezone, source-clear projection.");
}return 0;}
