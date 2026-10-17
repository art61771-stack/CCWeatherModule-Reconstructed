#import <Foundation/Foundation.h>
#import "../src/CYCaiyunProvider.h"
#import "../src/WCCWeatherSource.h"
#include <assert.h>
static NSDictionary *fixture(id speed,id direction,id humidity,NSArray *hours){
 NSMutableDictionary *wind=[NSMutableDictionary new],*real=[@{@"status":@"ok",@"temperature":@20,@"skycon":@"CLOUDY"} mutableCopy];
 if(speed)wind[@"speed"]=speed;if(direction)wind[@"direction"]=direction;if(humidity)real[@"humidity"]=humidity;real[@"wind"]=wind;
 return @{@"status":@"ok",@"timezone":@"Asia/Shanghai",@"result":@{@"realtime":real,@"hourly":@{@"status":@"ok",@"skycon":hours?:@[]}}};
}
static CYSnapshot *parse(id speed,id direction,id humidity,NSArray *hours){return [CYCaiyunProvider parseFixture:fixture(speed,direction,humidity,hours) now:[NSDate dateWithTimeIntervalSince1970:1767225600] generation:1];}
int main(void){@autoreleasepool{
 CYSnapshot *s=parse(@12,@135,@.98,nil);NSDictionary *r=WCCRenderCaiyunSnapshot(s,@"离线测试",NO);
 assert([r[@"details"] isEqual:@"东南风3级（12.0 km/h） · 湿度98%"]);assert([r[@"outlook"] isEqual:@""]);
 for(id bad in @[@YES,@-1,@"12",NSNull.null,@(NAN),@(INFINITY)]){
  s=parse(bad,bad,bad,nil);assert(!s.windSpeedKPH && !s.windDirectionDegrees && !s.relativeHumidity);assert([WCCWeatherDetails(s) isEqual:@""]);
 }
 assert(!parse(nil,@361,@1.01,nil).windDirectionDegrees);assert(!parse(nil,@0,@1.01,nil).relativeHumidity);
 assert([WCCWeatherDetails(parse(@0,@360,@0,nil)) isEqual:@"北风0级（0.0 km/h） · 湿度0%"]);
 assert([WCCWeatherDetails(parse(nil,nil,@1,nil)) isEqual:@"湿度100%"]);
 assert([WCCWeatherDetails(parse(@12,nil,nil,nil)) isEqual:@"风3级（12.0 km/h）"]);
 NSArray *directions=@[@0,@22.49,@22.5,@90,@135,@180,@225,@270,@315,@337.5,@360];
 NSArray *names=@[@"北风",@"北风",@"东北风",@"东风",@"东南风",@"南风",@"西南风",@"西风",@"西北风",@"北风",@"北风"];
 for(int i=0;i<directions.count;i++)assert([WCCWeatherDetails(parse(nil,directions[i],nil,nil)) isEqual:names[i]]);
 double limits[]={.3,1.6,3.4,5.5,8,10.8,13.9,17.2,20.8,24.5,28.5,32.7};
 for(int i=0;i<12;i++){NSString *a=WCCWeatherDetails(parse(@((limits[i]-.0001)*3.6),nil,nil,nil));NSString *b=WCCWeatherDetails(parse(@((limits[i]+.0001)*3.6),nil,nil,nil));assert([a containsString:[NSString stringWithFormat:@"风%d级",i]]);assert([b containsString:[NSString stringWithFormat:@"风%d级",i+1]]);}
 NSMutableArray *hours=[NSMutableArray new];NSISO8601DateFormatter *iso=[NSISO8601DateFormatter new];
 NSDate *now=[NSDate dateWithTimeIntervalSince1970:1767225600];
 for(int i=-2;i<=30;i++)[hours addObject:@{@"datetime":[iso stringFromDate:[now dateByAddingTimeInterval:i*3600]],@"value":i<5?@"CLOUDY":@"LIGHT_RAIN"}];
 s=parse(@12,@135,@.98,hours);r=WCCRenderCaiyunSnapshot(s,@"A",YES);
 assert([r[@"outlook"] isEqual:@"预报 01-01 08:00–01-02 08:00：阴 / 小雨"]);assert([r[@"stale"] boolValue]);
 assert(![r[@"outlook"] containsString:@"未来24"]);
 NSArray *partial=[hours subarrayWithRange:NSMakeRange(2,3)];assert([WCCWeatherOutlook(parse(nil,nil,nil,partial)) isEqual:@"预报 01-01 08:00–01-01 10:00：阴"]);
 NSArray *gap=@[hours[2],hours[4]];assert([WCCWeatherOutlook(parse(nil,nil,nil,gap)) isEqual:@"预报 01-01 08:00–01-01 08:00：阴"]);
 assert([WCCWeatherOutlook(parse(nil,nil,nil,@[hours[5]])) isEqual:@""]);
 NSMutableDictionary *json=[fixture(nil,nil,nil,hours) mutableCopy];[json removeObjectForKey:@"timezone"];
 assert([WCCWeatherOutlook([CYCaiyunProvider parseFixture:json now:now generation:1]) isEqual:@""]);
 NSDictionary *empty=WCCRenderCaiyunSnapshot(nil,@"",NO);assert([empty[@"details"] isEqual:@""] && [empty[@"outlook"] isEqual:@""]);
 puts("PASS125 actual provider parse + render: km/h conversion/all Beaufort thresholds/FROM compass octants/360/0 humidity/100 percent/boolean-null-string-NaN-inf rejection/missing omission; timestamp timezone and 24h capped contiguous known skycon forecast/partial/gaps/stale/no timezone/no data. Offline fixtures, no live API.");
}return 0;}
