#import <Foundation/Foundation.h>
#import "../src/WCCPreferences.h"
#import "../src/WCCConfigurations.h"
#include <assert.h>
int main(void){@autoreleasepool{
 NSString *suite=[@"test.weather124." stringByAppendingString:NSUUID.UUID.UUIDString];WCCTestUsePreferences(suite);
 NSString *dir=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];WCCTestUseConfigurationDirectory(dir);NSError *error=nil;
 for(int i=0;i<4;i++){assert(!WCCTextShadowEnabled(i)&&!WCCTextGlowEnabled(i));assert(([WCCTextEffectSettings(i) isEqual:@[@[],@NO,@0,@0]]));}
 assert(WCCSetCustomGreeting(YES,@"不换句"));assert(WCCSaveGreetingEntry(nil,@"独立列表"));assert(WCCSetRandomGreetingEnabled(YES));
 for(int i=0;i<4;i++){
  NSArray *before=WCCTextEffectSettings((i+1)%4);
  assert(WCCSetTextEffectSettings(i,@[@[@.2,@.4,@.6,@.8],@YES,@((i-1)/2.0),@((i-2)/2.0)]));
  assert([before isEqual:WCCTextEffectSettings((i+1)%4)]);
  assert(WCCSetTextShadowEnabled(i,YES));assert(WCCSetTextGlowEnabled(i,YES));
 }
 NSDictionary *snapshot=WCCCurrentSliderValues();assert(snapshot.count==26);
 assert(WCCSaveConfiguration(@"四组完整",nil,&error));NSString *identifier=WCCConfigurations(&error)[0][@"id"];
 assert(WCCSetTextEffectSettings(3,@[@[],@NO,@0,@1]));assert(WCCSetTextGlowEnabled(0,NO));
 NSDictionary *changed=WCCCurrentSliderValues();assert(WCCLoadConfiguration(identifier,&error));assert([snapshot isEqual:WCCCurrentSliderValues()]);
 assert(WCCLoadConfiguration(@"00000000-0000-0000-0000-000000000000",&error));assert([changed isEqual:WCCCurrentSliderValues()]);
 NSDictionary *stable=WCCCurrentSliderValues();WCCTestFailCommit(YES);
 assert(!WCCSetTextEffectSettings(0,@[@[],@NO,@0,@0]));assert(!WCCSetTextGlowEnabled(3,NO));assert([stable isEqual:WCCCurrentSliderValues()]);WCCTestFailCommit(NO);
 assert(!WCCSetTextEffectSettings(0,@[@[],@1,@0,@0]));assert(!WCCSetTextEffectSettings(3,@[@[],@YES,@0,@2]));assert(!WCCSetTextEffectSettings(1,@[@[@2,@0,@0,@1],@NO,@0,@0]));
 assert(WCCSetTextEffectSettings(0,@[@[],@YES,@0]));assert([WCCTextEffectSettings(0)[3] isEqual:@0]);
 // v3 leaves v4-only settings intact; v4 missing fields explicitly restore defaults.
 NSDictionary *old=WCCNormalizePresentationValues(@{},3);assert(!old[@"textEffect124_0"]);assert(WCCCommitSliderValues(old));assert([WCCTextEffectSettings(0)[1] boolValue]);
 NSDictionary *defaults=WCCNormalizePresentationValues(@{},4);assert(WCCCommitSliderValues(defaults));for(int i=0;i<4;i++)assert(([WCCTextEffectSettings(i) isEqual:@[@[],@NO,@0,@0]]));
 [WCCPrefs() removePersistentDomainForName:suite];[NSFileManager.defaultManager removeItemAtPath:dir error:NULL];
 puts("PASS124 production Foundation: four-group isolation, RGBA/speed/density, v4 save/backup/restore, rollback/types, v3 preservation");
}return 0;}
