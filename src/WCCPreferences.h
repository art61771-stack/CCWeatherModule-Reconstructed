#import <Foundation/Foundation.h>
// CCSupport ABI: columns (width), then rows (height).
typedef struct { NSUInteger width; NSUInteger height; } WCCLayoutSize;
FOUNDATION_EXPORT NSArray<NSString *> *WCCSizeOptions(void);
FOUNDATION_EXPORT NSString *WCCSelectedSize(void);
FOUNDATION_EXPORT BOOL WCCSetSelectedSize(NSString *size);
FOUNDATION_EXPORT WCCLayoutSize WCCEffectiveSize(void);
FOUNDATION_EXPORT NSUserDefaults *WCCPrefs(void);
FOUNDATION_EXPORT BOOL WCCCommitSliderValues(NSDictionary *values);
#ifdef WCC_TESTING
FOUNDATION_EXPORT void WCCTestUsePreferences(NSString *suite);
FOUNDATION_EXPORT void WCCTestFailCommit(BOOL fail);
#endif
FOUNDATION_EXPORT NSString *WCCRoot(void);
FOUNDATION_EXPORT NSString *WCCCheckedPath(NSString *root, NSString *name, NSString **reason);
FOUNDATION_EXPORT NSString *WCCSafePath(NSString *root, NSString *name);
FOUNDATION_EXPORT BOOL WCCAllowedRoot(NSString *path);
FOUNDATION_EXPORT NSString * const WCCPreferencesChanged;
FOUNDATION_EXPORT NSString * const WCCMainIconScaleChanged;
FOUNDATION_EXPORT NSString * const WCCRegionPositionChanged;
FOUNDATION_EXPORT NSArray<NSString *> *WCCRegionPositionKeys(void);
FOUNDATION_EXPORT double WCCRegionOffset(NSInteger index);
FOUNDATION_EXPORT BOOL WCCSetRegionOffset(NSInteger index, double value);
// -1 resets all eight keys; 0...3 resets only one region.
FOUNDATION_EXPORT BOOL WCCResetRegionOffsets(NSInteger region);
FOUNDATION_EXPORT double WCCMainIconPercent(void);
FOUNDATION_EXPORT BOOL WCCSetMainIconPercent(double value);

FOUNDATION_EXPORT NSString *WCCAssetKey(NSInteger code, BOOL night);
FOUNDATION_EXPORT NSArray<NSString *> *WCCAssetKeys(void);
FOUNDATION_EXPORT NSString *WCCMappedNameForKey(NSDictionary *mappings, NSString *key);
FOUNDATION_EXPORT NSString *WCCMappedName(NSString *key);
FOUNDATION_EXPORT BOOL WCCSetMappedName(NSString *key, NSString *name);

// v2 local presentation schema only. Missing fields receive explicit defaults.
FOUNDATION_EXPORT NSDictionary *WCCNormalizePresentationValues(NSDictionary *values, NSInteger version);
FOUNDATION_EXPORT double WCCMainIconPercentForMode(BOOL expanded);
FOUNDATION_EXPORT BOOL WCCSetMainIconPercentForMode(BOOL expanded, double value);
FOUNDATION_EXPORT BOOL WCCTextShadowEnabled(NSInteger group);
FOUNDATION_EXPORT BOOL WCCSetTextShadowEnabled(NSInteger group, BOOL enabled);
FOUNDATION_EXPORT BOOL WCCCustomGreetingEnabled(void);
FOUNDATION_EXPORT NSString *WCCCustomGreetingText(void);
FOUNDATION_EXPORT BOOL WCCSetCustomGreeting(BOOL enabled, NSString *text);
FOUNDATION_EXPORT BOOL WCCCustomGreetingList(void);
FOUNDATION_EXPORT BOOL WCCSetCustomGreetingList(NSArray *list);
FOUNDATION_EXPORT BOOL WCCCustomGreetingRandomEnabled(void);
FOUNDATION_EXPORT BOOL WCCSetCustomGreetingRandomEnabled(BOOL enabled);
FOUNDATION_EXPORT BOOL WCCTextShadowGlowEnabled(NSInteger group);
FOUNDATION_EXPORT BOOL WCCSetTextShadowGlowEnabled(NSInteger group, BOOL enabled);
FOUNDATION_EXPORT CGFloat WCCTextShadowGlowRadius(NSInteger group);
FOUNDATION_EXPORT BOOL WCCSetTextShadowGlowRadius(NSInteger group, CGFloat radius);
