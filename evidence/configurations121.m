// Compile against actual production .m files, never mock JSON/filesystem/defaults.
#import <Foundation/Foundation.h>
#import "../src/WCCConfigurations.h"
#import "../src/WCCPreferences.h"
#include <assert.h>
#include <math.h>
static NSString *path(NSString *i){return [WCCConfigurationDirectory() stringByAppendingPathComponent:[i stringByAppendingString:@".json"]];}
static NSMutableDictionary *doc(NSString *i){return [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path(i)] options:NSJSONReadingMutableContainers error:NULL] mutableCopy];}
static void writeDoc(NSString *i,NSDictionary *d){assert([[NSJSONSerialization dataWithJSONObject:d options:0 error:NULL] writeToFile:path(i) atomically:YES]);}
int main(void){@autoreleasepool{
 NSFileManager *fm=NSFileManager.defaultManager;
 NSString *suite=[@"test.weather121." stringByAppendingString:NSUUID.UUID.UUIDString];
 WCCTestUsePreferences(suite);
 NSString *tmp=[NSTemporaryDirectory().stringByResolvingSymlinksInPath stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
 NSString *directory=[tmp stringByAppendingPathComponent:@"Configurations"];
 WCCTestUseConfigurationDirectory(directory);
 NSError *e=nil;
 __block NSUInteger notes=0;
 id token=[NSNotificationCenter.defaultCenter addObserverForName:WCCRegionPositionChanged object:nil queue:nil usingBlock:^(NSNotification *n){notes++;}];
 [WCCPrefs() setDouble:125 forKey:@"mainCustomIconPercent"];
 assert(WCCMainIconPercentForMode(NO)==125 && WCCMainIconPercentForMode(YES)==125);
 assert(WCCSetMainIconPercentForMode(NO,75));assert(WCCMainIconPercentForMode(YES)==125);
 assert(WCCSetMainIconPercentForMode(YES,150));assert(WCCMainIconPercentForMode(NO)==75);
 assert(WCCSetMainIconPercentForMode(NO,100));assert(WCCSetMainIconPercentForMode(YES,100));
 for(int i=0;i<8;i++){assert(WCCSetRegionOffset(i,i%2?40:1366));assert(WCCRegionOffset(i)==(i%2?40:1366));}
 assert(WCCResetRegionOffsets(-1));
 for(int i=0;i<3;i++){assert(!WCCTextShadowEnabled(i));assert(WCCSetTextShadowEnabled(i,YES));assert(WCCTextShadowEnabled(i));assert(WCCSetTextShadowEnabled(i,NO));}
 assert(!WCCSetCustomGreeting(YES,@"  "));assert(WCCSetCustomGreeting(YES,@"  你好  "));
 assert(WCCCustomGreetingEnabled() && [WCCCustomGreetingText() isEqual:@"你好"]);
 assert(WCCSetCustomGreeting(NO,@""));
 NSDictionary *defaults=WCCCurrentSliderValues();
 assert(defaults.count==26 && [defaults[@"mainIconCollapsedPercent"] intValue]==100);
 for(NSNumber *invalid in @[@(NAN),@(INFINITY),@YES]) { NSMutableDictionary *v=[defaults mutableCopy];v[@"temperatureOffsetX"]=invalid;assert(!WCCCommitSliderValues(v));assert([WCCCurrentSliderValues() isEqual:defaults]); }
 for(NSString *k in WCCRegionPositionKeys())assert([defaults[k] intValue]==0);
 assert(WCCSaveConfiguration(@"一套",nil,&e));
 NSArray *list=WCCConfigurations(&e);assert(list.count==1);
 NSString *identifier=list[0][@"id"];
 assert(![identifier containsString:@"一套"]);
 assert(!WCCSaveConfiguration(@"一套",nil,&e));
 assert(!WCCSaveConfiguration(@"../逃逸",nil,&e));
 assert(!WCCLoadConfiguration(@"../../escape",&e));
 NSMutableDictionary *target=[defaults mutableCopy];target[@"temperatureOffsetX"]=@27;target[@"mainIconCollapsedPercent"]=@250;target[@"mainIconExpandedPercent"]=@75;target[@"greetingShadow"]=@YES;target[@"customGreetingEnabled"]=@YES;target[@"customGreetingText"]=@"固定句子";
 assert(WCCCommitSliderValues(target));
 [WCCPrefs() setObject:@"keep" forKey:@"unrelated"];
 assert(WCCSaveConfiguration(@"一套",identifier,&e));
 assert([doc(identifier)[@"values"] isEqual:target]);
 assert(WCCCommitSliderValues(defaults));
 notes=0;assert(WCCLoadConfiguration(identifier,&e));assert(notes==1);
 assert([WCCCurrentSliderValues() isEqual:target]);assert([[WCCPrefs() objectForKey:@"unrelated"] isEqual:@"keep"]);
 NSString *backup=@"00000000-0000-0000-0000-000000000000";
 assert([doc(backup)[@"values"] isEqual:defaults]);
 assert(WCCConfigurations(&e).count==2);
 // Compatibility: absent old slider fields default to 0 / 100.
 NSMutableDictionary *good=doc(identifier),*legacy=[good mutableCopy];legacy[@"values"]=@{};
 writeDoc(identifier,legacy);assert(WCCLoadConfiguration(identifier,&e));assert([WCCCurrentSliderValues() isEqual:defaults]);
 // Legacy v1 nine-value migration and explicit defaults, without changing unrelated prefs.
 legacy[@"version"]=@1;legacy[@"values"]=@{@"mainCustomIconPercent":@125,@"temperatureOffsetX":@40};
 writeDoc(identifier,legacy);assert(WCCLoadConfiguration(identifier,&e));
 assert(WCCMainIconPercentForMode(NO)==125 && WCCMainIconPercentForMode(YES)==125);
 assert(!WCCCustomGreetingEnabled() && WCCCustomGreetingText().length==0 && !WCCTextShadowEnabled(2));
 assert([[WCCPrefs() objectForKey:@"unrelated"] isEqual:@"keep"]);
 assert(WCCCommitSliderValues(defaults));
 for(NSDictionary *v in @[@{@"mainIconCollapsedPercent":@255},@{@"mainIconExpandedPercent":@250},@{@"greetingShadow":@1},@{@"customGreetingEnabled":@1},@{@"customGreetingEnabled":@YES,@"customGreetingText":@"  "},@{@"customGreetingText":[@"x" stringByPaddingToLength:81 withString:@"x" startingAtIndex:0]},@{@"temperatureOffsetY":@41},@{@"mainIconExpandedPercent":@101},@{@"token":@"forbidden"}]){
  NSMutableDictionary *bad=[good mutableCopy];bad[@"values"]=v;writeDoc(identifier,bad);assert(!WCCLoadConfiguration(identifier,&e));assert([WCCCurrentSliderValues() isEqual:defaults]);
 }
 // Schema whitelist, types, finite/range/step, version and malformed documents.
 for(id invalid in @[@YES,@"4",@1367,@(-1367),@1.5,NSNull.null]){
  NSMutableDictionary *bad=[good mutableCopy];NSMutableDictionary *v=[target mutableCopy];v[@"temperatureOffsetX"]=invalid;bad[@"values"]=v;writeDoc(identifier,bad);
  notes=0;assert(!WCCLoadConfiguration(identifier,&e));assert(e && notes==0);assert([WCCCurrentSliderValues() isEqual:defaults]);
 }
 for(NSDictionary *v in @[@{@"mainCustomIconPercent":@155},@{@"mainCustomIconPercent":@101},@{@"customIcon":@1}]){
  NSMutableDictionary *bad=[good mutableCopy];bad[@"values"]=v;writeDoc(identifier,bad);assert(!WCCLoadConfiguration(identifier,&e));
 }
 for(id version in @[@YES,@5,@"1"]){NSMutableDictionary *bad=[good mutableCopy];bad[@"version"]=version;writeDoc(identifier,bad);assert(!WCCLoadConfiguration(identifier,&e));}
 NSMutableDictionary *bad=[good mutableCopy];bad[@"extra"]=@1;writeDoc(identifier,bad);assert(!WCCLoadConfiguration(identifier,&e));
 assert([@"{broken" writeToFile:path(identifier) atomically:YES encoding:NSUTF8StringEncoding error:&e]);assert(!WCCLoadConfiguration(identifier,&e));
 assert([[NSMutableData dataWithLength:16385] writeToFile:path(identifier) atomically:YES]);assert(!WCCLoadConfiguration(identifier,&e));
 writeDoc(identifier,good);
 // A real non-file backup destination must fail before preferences or notification.
 assert([fm removeItemAtPath:path(backup) error:&e]);
 assert([fm createDirectoryAtPath:path(backup) withIntermediateDirectories:NO attributes:nil error:&e]);
 notes=0;assert(!WCCLoadConfiguration(identifier,&e));assert(e && notes==0);assert([WCCCurrentSliderValues() isEqual:defaults]);
 assert([fm removeItemAtPath:path(backup) error:&e]);
 // Inject only synchronize failure; real persistent-domain commit and rollback execute.
 WCCTestFailCommit(YES);notes=0;assert(!WCCLoadConfiguration(identifier,&e));assert(notes==0);assert([WCCCurrentSliderValues() isEqual:defaults]);WCCTestFailCommit(NO);
 // File symlink: read/save/delete must not touch its target.
 NSString *outside=[tmp stringByAppendingPathComponent:@"outside.json"];
 assert([fm moveItemAtPath:path(identifier) toPath:outside error:&e]);
 assert([fm createSymbolicLinkAtPath:path(identifier) withDestinationPath:outside error:&e]);
 assert(!WCCLoadConfiguration(identifier,&e));assert(!WCCSaveConfiguration(@"一套",identifier,&e));assert(!WCCDeleteConfiguration(identifier,&e));
 assert([fm fileExistsAtPath:outside]);assert([fm removeItemAtPath:path(identifier) error:&e]);
 assert([fm moveItemAtPath:outside toPath:path(identifier) error:&e]);
 // Directory symlink rejected by all public file operations.
 NSString *moved=[tmp stringByAppendingPathComponent:@"moved"];
 assert([fm moveItemAtPath:directory toPath:moved error:&e]);
 assert([fm createSymbolicLinkAtPath:directory withDestinationPath:moved error:&e]);
 assert(!WCCConfigurations(&e));assert(!WCCLoadConfiguration(identifier,&e));assert(!WCCSaveConfiguration(@"新",nil,&e));assert(!WCCDeleteConfiguration(identifier,&e));
 assert([fm removeItemAtPath:directory error:&e]);assert([fm moveItemAtPath:moved toPath:directory error:&e]);
 assert(WCCLoadConfiguration(identifier,&e));assert([WCCCurrentSliderValues() isEqual:target]);
 assert(WCCDeleteConfiguration(identifier,&e));assert(!WCCLoadConfiguration(identifier,&e));
 [NSNotificationCenter.defaultCenter removeObserver:token];[WCCPrefs() removePersistentDomainForName:suite];[fm removeItemAtPath:tmp error:NULL];
 puts("PASS 120 actual Foundation production config: real temporary file writes, overwrite, load, compatibility, whitelist, corrupt/oversize, backup failure, commit rollback, symlinks, delete");
}return 0;}
