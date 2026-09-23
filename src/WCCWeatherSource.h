#import <Foundation/Foundation.h>
@class CYSnapshot;
FOUNDATION_EXPORT NSString * const WCCWeatherSourceChanged;
FOUNDATION_EXPORT NSNumber *WCCParseCoordinate(NSString *text, BOOL longitude);
// Foundation-only immutable render projection. No City or device daylight dependency.
FOUNDATION_EXPORT NSDictionary *WCCRenderCaiyunSnapshot(CYSnapshot *snapshot, NSString *alias, BOOL stale);
@interface WCCWeatherSource : NSObject
+ (instancetype)shared;
@property(nonatomic,readonly) BOOL caiyun;
@property(nonatomic,readonly) NSUInteger generation;
@property(nonatomic,strong,readonly) CYSnapshot *snapshot;
@property(nonatomic,copy,readonly) NSString *status;
@property(nonatomic,readonly) BOOL stale;
- (void)setAutomaticActive:(BOOL)active;
- (BOOL)setRefreshHours:(NSInteger)hours;
- (BOOL)hasToken;
- (BOOL)applyCaiyun:(BOOL)enabled longitude:(NSNumber *)longitude latitude:(NSNumber *)latitude alias:(NSString *)alias token:(NSString *)token;
- (BOOL)deleteToken;
- (void)refreshManual:(BOOL)manual;
- (void)cancel; // background/dismiss; retains same-configuration snapshot
@end
