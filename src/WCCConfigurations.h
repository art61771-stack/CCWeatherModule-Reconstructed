#import <Foundation/Foundation.h>
#ifdef WCC_TESTING
FOUNDATION_EXPORT void WCCTestUseConfigurationDirectory(NSString *directory);
#endif
FOUNDATION_EXPORT NSString *WCCConfigurationDirectory(void);
FOUNDATION_EXPORT NSDictionary *WCCCurrentSliderValues(void);
FOUNDATION_EXPORT NSArray<NSDictionary *> *WCCConfigurations(NSError **error);
FOUNDATION_EXPORT BOOL WCCSaveConfiguration(NSString *name,NSString *overwriteID,NSError **error);
FOUNDATION_EXPORT BOOL WCCLoadConfiguration(NSString *identifier,NSError **error);
FOUNDATION_EXPORT BOOL WCCDeleteConfiguration(NSString *identifier,NSError **error);
