#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSUserDefaults *WCCPrefs(void);
FOUNDATION_EXPORT NSString *WCCRoot(void);
FOUNDATION_EXPORT NSString *WCCSafePath(NSString *root, NSString *name);
FOUNDATION_EXPORT BOOL WCCAllowedRoot(NSString *path);
FOUNDATION_EXPORT NSString * const WCCPreferencesChanged;
