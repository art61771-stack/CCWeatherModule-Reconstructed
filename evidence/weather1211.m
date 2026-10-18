#import <Foundation/Foundation.h>
#import "../src/WCCPreferences.h"
#import "../src/WCCConfigurations.h"
#import "../src/WCCWeatherDetailProjection.h"
#include <assert.h>
static void Project(BOOL on,NSString *expectCondition,NSString *expectPrecip) {
 NSDictionary *p=WCCProjectWeatherText(@"晴",@"降水概率: 20%",@"东风 · 风速12km/h · 2级 · 湿度60%",@"未来3小时 晴 / 多云",on);
 assert([p[@"condition"] isEqual:expectCondition]);assert([p[@"precipitation"] isEqual:expectPrecip]);
}
int main(void){@autoreleasepool{
 NSString*suite=[@"test.weather1211." stringByAppendingString:NSUUID.UUID.UUIDString];WCCTestUsePreferences(suite);
 NSString*dir=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];WCCTestUseConfigurationDirectory(dir);NSError*e=nil;
 assert(WCCWeatherDetailsEnabled());Project(YES,@"晴 · 东风 · 风速12km/h · 2级 · 湿度60%",@"未来3小时 晴 / 多云 · 降水概率: 20%");
 assert(WCCSetWeatherDetailsEnabled(NO));assert(!WCCWeatherDetailsEnabled());Project(NO,@"晴",@"降水概率: 20%");
 for(int i=0;i<100;i++){BOOL on=i&1;assert(WCCSetWeatherDetailsEnabled(on));Project(on,on?@"晴 · 东风 · 风速12km/h · 2级 · 湿度60%":@"晴",on?@"未来3小时 晴 / 多云 · 降水概率: 20%":@"降水概率: 20%");}assert(WCCSetWeatherDetailsEnabled(NO));
 assert(WCCSaveConfiguration(@"关闭详情",nil,&e));NSString*identifier=WCCConfigurations(&e)[0][@"id"];
 assert(WCCSetWeatherDetailsEnabled(YES));assert(WCCLoadConfiguration(identifier,&e));assert(!WCCWeatherDetailsEnabled());
 NSDictionary*v6=WCCNormalizePresentationValues(@{},6);assert([v6[@"weatherDetailsEnabled1211"] isEqual:@YES]);
 for(int version=1;version<=5;version++){NSDictionary*old=WCCNormalizePresentationValues(@{},version);assert(old && !old[@"weatherDetailsEnabled1211"]);}
 assert(WCCSetWeatherDetailsEnabled(YES));NSDictionary*stable=WCCCurrentSliderValues();WCCTestFailCommit(YES);assert(!WCCSetWeatherDetailsEnabled(NO));assert(WCCWeatherDetailsEnabled());assert([stable isEqual:WCCCurrentSliderValues()]);WCCTestFailCommit(NO);
 NSMutableDictionary*bad=[WCCCurrentSliderValues() mutableCopy];bad[@"weatherDetailsEnabled1211"]=@1;assert(!WCCCommitSliderValues(bad));
 NSDictionary*empty=WCCProjectWeatherText(@"多云",@"降水概率: 0%",nil,nil,YES);assert([empty[@"condition"] isEqual:@"多云"]&&[empty[@"precipitation"] isEqual:@"降水概率: 0%"]);
 [WCCPrefs() removePersistentDomainForName:suite];[NSFileManager.defaultManager removeItemAtPath:dir error:NULL];
 puts("PASS1211 Foundation production: default-on/persistent-off, strict v6 default, v1-v5 preserve semantics, transactional rollback, immediate in-memory projection, 100 toggles without serial contamination, original condition/precip retained.");
}return 0;}
