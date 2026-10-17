#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NSString * _Nullable (^WCCSystemConditionName)(NSInteger code);
// Best-effort projection from runtime Weather.framework objects. It never uses KVC.
FOUNDATION_EXPORT NSDictionary<NSString *, NSString *> *WCCRenderSystemWeatherDetails(id _Nullable city, NSDate *now, WCCSystemConditionName _Nullable conditionName);
NS_ASSUME_NONNULL_END
