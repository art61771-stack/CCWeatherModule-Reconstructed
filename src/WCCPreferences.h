#import <Foundation/Foundation.h>
// CCSupport ABI: columns (width), then rows (height).
typedef struct { NSUInteger width; NSUInteger height; } WCCLayoutSize;
FOUNDATION_EXPORT NSArray<NSString *> *WCCSizeOptions(void);
FOUNDATION_EXPORT NSString *WCCSelectedSize(void);
FOUNDATION_EXPORT BOOL WCCSetSelectedSize(NSString *size);
FOUNDATION_EXPORT WCCLayoutSize WCCEffectiveSize(void);
FOUNDATION_EXPORT NSUserDefaults *WCCPrefs(void);
FOUNDATION_EXPORT NSString *WCCRoot(void);
FOUNDATION_EXPORT NSString *WCCSafePath(NSString *root, NSString *name);
FOUNDATION_EXPORT BOOL WCCAllowedRoot(NSString *path);
FOUNDATION_EXPORT NSString * const WCCPreferencesChanged;
