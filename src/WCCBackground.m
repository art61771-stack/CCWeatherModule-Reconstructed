#import "WCCBackground.h"
#import "WCCPreferences.h"
#import <CoreFoundation/CoreFoundation.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

NSString * const WCCBackgroundChanged=@"WCCBackgroundChanged";
static const unsigned long long WCCBackgroundLimit=64ULL*1024ULL*1024ULL;
#ifdef WCC_TESTING
static NSString *WCCTestBackgroundDirectory;
static BOOL WCCTestBackgroundCommitFailure;
void WCCTestUseBackgroundDirectory(NSString *directory){WCCTestBackgroundDirectory=[directory copy];}
void WCCTestFailBackgroundCommit(BOOL fail){WCCTestBackgroundCommitFailure=fail;}
#endif
NSString *WCCBackgroundRoot(void){
#ifdef WCC_TESTING
 if(WCCTestBackgroundDirectory)return WCCTestBackgroundDirectory;
#endif
 return @"/var/mobile/Documents/CCWeatherModule/Background";
}
BOOL WCCBackgroundAllowedRoot(NSString *path){
 if(![path isKindOfClass:NSString.class]||!path.isAbsolutePath)return NO;
#ifdef WCC_TESTING
 if(WCCTestBackgroundDirectory)return [path.stringByStandardizingPath isEqual:WCCTestBackgroundDirectory.stringByStandardizingPath];
#endif
 NSString *base=@"/var/mobile/Documents".stringByResolvingSymlinksInPath;
 NSString *expected=[base stringByAppendingPathComponent:@"CCWeatherModule/Background"];
 return [path.stringByResolvingSymlinksInPath isEqual:expected];
}
static BOOL WCCRegular(NSString *path,unsigned long long *size){struct stat st;if(lstat(path.fileSystemRepresentation,&st)||!S_ISREG(st.st_mode)||st.st_size<1)return NO;if(size)*size=st.st_size;return YES;}
static NSString *WCCNameFor(WCCBackgroundKind kind){return kind==WCCBackgroundKindImage?@"current-image.jpg":kind==WCCBackgroundKindVideo?@"current-video.mp4":nil;}
NSString *WCCBackgroundRelativeName(void){id v=[WCCPrefs() objectForKey:@"backgroundFile1212"];return [v isKindOfClass:NSString.class]?v:nil;}
WCCBackgroundKind WCCBackgroundType(void){id v=[WCCPrefs() objectForKey:@"backgroundType1212"];NSInteger n=[v isKindOfClass:NSNumber.class]?[v integerValue]:0;return n==1||n==2?n:0;}
CGFloat WCCBackgroundMask(void){id v=[WCCPrefs() objectForKey:@"backgroundMask1212"];double n=[v isKindOfClass:NSNumber.class]?[v doubleValue]:.35;if(!isfinite(n))n=.35;return MIN(1,MAX(0,n));}
NSString *WCCBackgroundPath(void){WCCBackgroundKind kind=WCCBackgroundType();NSString *name=WCCBackgroundRelativeName();if(!kind||![name isEqual:WCCNameFor(kind)]||!WCCBackgroundAllowedRoot(WCCBackgroundRoot()))return nil;NSString *path=[WCCBackgroundRoot() stringByAppendingPathComponent:name];unsigned long long size=0;return WCCRegular(path,&size)&&size<=WCCBackgroundLimit?path:nil;}
static BOOL WCCCommit(NSDictionary *values){
 NSUserDefaults *p=WCCPrefs();NSDictionary *before=[p persistentDomainForName:@"com.simon.ccweathermodule.custom"]?:@{};NSMutableDictionary *after=[before mutableCopy];[after addEntriesFromDictionary:values];[p setPersistentDomain:after forName:@"com.simon.ccweathermodule.custom"];BOOL ok=[p synchronize];
#ifdef WCC_TESTING
 if(WCCTestBackgroundCommitFailure)ok=NO;
#endif
 if(!ok){[p setPersistentDomain:before forName:@"com.simon.ccweathermodule.custom"];[p synchronize];}return ok;
}
static void WCCNotify(void){dispatch_async(dispatch_get_main_queue(),^{[NSNotificationCenter.defaultCenter postNotificationName:WCCBackgroundChanged object:nil];});}
BOOL WCCSetBackgroundMask(CGFloat value){if(!NSThread.isMainThread||!isfinite(value))return NO;BOOL ok=WCCCommit(@{@"backgroundMask1212":@(MIN(1,MAX(0,value)))});if(ok)WCCNotify();return ok;}
static NSError *WCCError(NSString *s){return [NSError errorWithDomain:@"WCCBackground" code:1 userInfo:@{NSLocalizedDescriptionKey:s}];}
BOOL WCCInstallBackgroundFile(NSURL *source,WCCBackgroundKind kind,NSError **error){
 if(!source.isFileURL||(kind!=WCCBackgroundKindImage&&kind!=WCCBackgroundKindVideo)){if(error)*error=WCCError(@"选择结果无效。");return NO;}
 NSString *ext=source.pathExtension.lowercaseString;NSArray *allowed=kind==WCCBackgroundKindImage?@[@"jpg",@"jpeg",@"png",@"heic"]:@[@"mp4",@"mov",@"m4v"];
 if(![allowed containsObject:ext]){if(error)*error=WCCError(@"格式不支持：图片限 JPG/PNG/HEIC，视频限 MP4/MOV/M4V。");return NO;}
 unsigned long long size=0;if(!WCCRegular(source.path,&size)||size>WCCBackgroundLimit){if(error)*error=WCCError(@"文件须为不超过64MB的普通文件，不能是符号链接。");return NO;}
 NSString *root=WCCBackgroundRoot();if(!WCCBackgroundAllowedRoot(root)){if(error)*error=WCCError(@"背景目录不安全，操作已取消。");return NO;}
 NSFileManager *fm=NSFileManager.defaultManager;if(![fm createDirectoryAtPath:root withIntermediateDirectories:YES attributes:nil error:error]||!WCCBackgroundAllowedRoot(root))return NO;
 NSString *name=WCCNameFor(kind),*target=[root stringByAppendingPathComponent:name],*temp=[root stringByAppendingPathComponent:[@".incoming-" stringByAppendingString:NSUUID.UUID.UUIDString]];
 int in=open(source.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW),out=-1;BOOL copied=NO;if(in>=0)out=open(temp.fileSystemRepresentation,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0600);
 if(in>=0&&out>=0){char b[65536];unsigned long long total=0;ssize_t n;copied=YES;while((n=read(in,b,sizeof(b)))>0){total+=(unsigned long long)n;if(total>WCCBackgroundLimit){copied=NO;break;}char *p=b;ssize_t left=n;while(left>0){ssize_t w=write(out,p,left);if(w<=0){copied=NO;break;}p+=w;left-=w;}if(!copied)break;}if(n<0||fsync(out))copied=NO;}if(in>=0)close(in);if(out>=0)close(out);
 unsigned long long finalSize=0;if(!copied||!WCCRegular(temp,&finalSize)||finalSize!=size){[fm removeItemAtPath:temp error:nil];if(error)*error=WCCError(@"安全复制失败，旧背景已保留。");return NO;}
 NSString *backup=[target stringByAppendingString:@".previous"];[fm removeItemAtPath:backup error:nil];BOOL had=[fm fileExistsAtPath:target];if(had&&![fm moveItemAtPath:target toPath:backup error:error]){[fm removeItemAtPath:temp error:nil];return NO;}
 if(![fm moveItemAtPath:temp toPath:target error:error]){if(had)[fm moveItemAtPath:backup toPath:target error:nil];[fm removeItemAtPath:temp error:nil];return NO;}
 CGFloat mask=[WCCPrefs() objectForKey:@"backgroundMask1212"]?WCCBackgroundMask():.35;
 if(!WCCCommit(@{@"backgroundType1212":@(kind),@"backgroundFile1212":name,@"backgroundMask1212":@(mask)})){[fm removeItemAtPath:target error:nil];if(had)[fm moveItemAtPath:backup toPath:target error:nil];if(error)*error=WCCError(@"偏好保存失败，旧背景已恢复。");return NO;}
 [fm removeItemAtPath:backup error:nil];NSString *other=[root stringByAppendingPathComponent:WCCNameFor(kind==WCCBackgroundKindImage?WCCBackgroundKindVideo:WCCBackgroundKindImage)];[fm removeItemAtPath:other error:nil];WCCNotify();return YES;
}
BOOL WCCClearBackground(NSError **error){if(!WCCBackgroundAllowedRoot(WCCBackgroundRoot())){if(error)*error=WCCError(@"背景目录不安全。");return NO;}if(!WCCCommit(@{@"backgroundType1212":@0,@"backgroundFile1212":@""}))return NO;NSFileManager *fm=NSFileManager.defaultManager;for(NSString *n in @[@"current-image.jpg",@"current-video.mp4"])[fm removeItemAtPath:[WCCBackgroundRoot() stringByAppendingPathComponent:n] error:nil];WCCNotify();return YES;}
BOOL WCCBackgroundPickerGenerationCurrent(NSUInteger expected,NSUInteger current,BOOL ended,BOOL ownerCurrent){return expected==current&&!ended&&ownerCurrent;}
