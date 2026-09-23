#import <Foundation/Foundation.h>
#import "../src/WCCPreferences.h"
#import "../src/WCCConfigurations.h"
#include <assert.h>
int main(void){@autoreleasepool{
 NSString *suite=[@"test.weather123." stringByAppendingString:NSUUID.UUID.UUIDString];WCCTestUsePreferences(suite);
 NSString *dir=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];WCCTestUseConfigurationDirectory(dir);NSError *error=nil;
 NSDictionary *protected=@{@"weatherProvider":@"caiyun",@"source":@"unchanged",@"moduleSize":@"4x1",@"mapping":@{@"clear":@"my.png"},@"customIcon":@YES};
 for(NSString *k in protected)[WCCPrefs() setObject:protected[k] forKey:k];
 assert(WCCSetCustomGreeting(YES,@"旧句"));assert(WCCGreetingEntries().count==1);
 assert(![WCCPrefs() objectForKey:@"greetingEntries122"]); // read-only migration
 assert(WCCSaveGreetingEntry(nil,@"第二句"));NSString *second=WCCGreetingEntries()[1][@"id"];
 assert(WCCSaveGreetingEntry(second,@"修改第二句"));assert([WCCGreetingEntries()[0][@"text"] isEqual:@"旧句"]);
 assert(WCCSaveGreetingEntry(nil,@"旧句"));assert(WCCGreetingEntries().count==3 && WCCGreetingCandidates().count==2);
 assert(WCCDeleteGreetingEntry(second));assert(WCCGreetingEntries().count==2 && WCCGreetingCandidates().count==1);
 assert(!WCCDeleteGreetingEntry(second) && !WCCSaveGreetingEntry(second,@"已删除"));
 assert(!WCCSaveGreetingEntry(nil,@" \n "));
 // No artificial row/text cap; also exceed the old 16KB config limit.
 for(int i=0;i<160;i++)assert(WCCSaveGreetingEntry(nil,[[NSString stringWithFormat:@"%d ",i] stringByPaddingToLength:180 withString:@"长句" startingAtIndex:0]));
 assert(WCCGreetingEntries().count==162);
 assert(WCCSetRandomGreetingEnabled(YES));for(int i=0;i<3;i++)assert(WCCSetTextGlowEnabled(i,YES));
 NSDictionary *snapshot=WCCCurrentSliderValues();assert(snapshot.count==26);
 assert(WCCSaveConfiguration(@"完整列表",nil,&error));NSString *identifier=WCCConfigurations(&error)[0][@"id"];
 assert(WCCSetTextGlowEnabled(1,NO));assert(WCCSetRandomGreetingEnabled(NO));assert(WCCDeleteGreetingEntry(WCCGreetingEntries()[0][@"id"]));
 NSDictionary *before=WCCCurrentSliderValues();assert(WCCLoadConfiguration(identifier,&error));assert([snapshot isEqual:WCCCurrentSliderValues()]);
 NSString *backup=@"00000000-0000-0000-0000-000000000000";
 assert(WCCLoadConfiguration(backup,&error));assert([before isEqual:WCCCurrentSliderValues()]);
 // Old v2 changes its own fields but preserves every new field.
 NSString *old=NSUUID.UUID.UUIDString;
 NSDictionary *document=@{@"schema":@"CCWeatherSliderConfiguration",@"version":@2,@"name":@"旧v2",@"modified":@1,@"values":@{@"temperatureOffsetX":@(-100)}};
 NSString *file=[dir stringByAppendingPathComponent:[old stringByAppendingString:@".json"]];
 assert([[NSJSONSerialization dataWithJSONObject:document options:0 error:&error] writeToFile:file atomically:YES]);
 assert(WCCLoadConfiguration(old,&error));assert(WCCRegionOffset(0)==-100);
 for(NSString *k in @[@"greetingEntries122",@"randomGreeting122",@"temperatureGlow122",@"informationGlow122",@"greetingGlow122"])assert([WCCCurrentSliderValues()[k] isEqual:before[k]]);
 for(NSString *k in protected)assert([[WCCPrefs() objectForKey:k] isEqual:protected[k]]);
 NSDictionary *stable=WCCCurrentSliderValues();WCCTestFailCommit(YES);
 assert(!WCCSaveGreetingEntry(nil,@"不能保存"));assert(!WCCSetRandomGreetingEnabled(YES));assert(!WCCSetTextGlowEnabled(1,YES));assert([stable isEqual:WCCCurrentSliderValues()]);WCCTestFailCommit(NO);
 NSMutableDictionary *bad=[snapshot mutableCopy];bad[@"greetingEntries122"]=@[@{@"id":@"same",@"text":@"one"},@{@"id":@"same",@"text":@"two"}];assert(!WCCCommitSliderValues(bad));
 bad=[snapshot mutableCopy];bad[@"randomGreeting122"]=@1;assert(!WCCCommitSliderValues(bad));
 for(NSDictionary *row in [WCCGreetingEntries() copy])assert(WCCDeleteGreetingEntry(row[@"id"]));
 assert(WCCGreetingEntries().count==0);assert(WCCGreetingCandidates().count==0);
 [WCCPrefs() removePersistentDomainForName:suite];[NSFileManager.defaultManager removeItemAtPath:dir error:NULL];
 puts("PASS123 actual production Foundation: legacy virtual migration, independent 162-row CRUD, >16KB v3 snapshot/backup/restore, old-v2 preserves new settings, provider/mapping unchanged, rollback and strict types");
}return 0;}
