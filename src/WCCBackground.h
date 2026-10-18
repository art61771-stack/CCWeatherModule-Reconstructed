#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,WCCBackgroundKind) { WCCBackgroundKindNone=0, WCCBackgroundKindImage=1, WCCBackgroundKindVideo=2 };
FOUNDATION_EXPORT NSString * const WCCBackgroundChanged;
FOUNDATION_EXPORT NSString *WCCBackgroundRoot(void);
FOUNDATION_EXPORT BOOL WCCBackgroundAllowedRoot(NSString *path);
FOUNDATION_EXPORT NSString *WCCBackgroundRelativeName(void);
FOUNDATION_EXPORT WCCBackgroundKind WCCBackgroundType(void);
FOUNDATION_EXPORT CGFloat WCCBackgroundMask(void);
FOUNDATION_EXPORT NSString *WCCBackgroundPath(void);
FOUNDATION_EXPORT BOOL WCCSetBackgroundMask(CGFloat value);
FOUNDATION_EXPORT BOOL WCCInstallBackgroundFile(NSURL *source,WCCBackgroundKind kind,NSError **error);
FOUNDATION_EXPORT BOOL WCCClearBackground(NSError **error);
FOUNDATION_EXPORT BOOL WCCBackgroundPickerGenerationCurrent(NSUInteger expected,NSUInteger current,BOOL ended,BOOL ownerCurrent);
#ifdef WCC_TESTING
FOUNDATION_EXPORT void WCCTestUseBackgroundDirectory(NSString *directory);
FOUNDATION_EXPORT void WCCTestFailBackgroundCommit(BOOL fail);
#endif
