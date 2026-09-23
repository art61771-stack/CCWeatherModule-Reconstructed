#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString * const CYErrorDomain;
typedef NS_ENUM(NSInteger, CYErrorCode) {
    CYNotConfigured=1, CYInvalidInput, CYKeychainFailure, CYNetworkFailure,
    CYInvalidResponse, CYRequestRejected, CYPermissionDenied, CYAccessRestricted,
    CYRateLimited, CYServerFailure, CYThrottled, CYCancelled
};
@interface CYCondition : NSObject
@property(nonatomic,copy,readonly,nullable) NSString *skycon;
@property(nonatomic,copy,readonly) NSString *text;
@property(nonatomic,copy,readonly,nullable) NSString *basename;
@property(nonatomic,copy,readonly) NSString *symbol;
@end
@interface CYHour : NSObject
@property(nonatomic,strong,readonly) NSDate *date;
@property(nonatomic,strong,readonly,nullable) NSNumber *temperature;
// Already percent, 1 means 1%, never multiply by 100.
@property(nonatomic,strong,readonly,nullable) NSNumber *probability;
@property(nonatomic,strong,readonly) CYCondition *condition;
@end
@interface CYSnapshot : NSObject
@property(nonatomic,copy,readonly) NSString *source; // caiyun
@property(nonatomic,readonly) NSUInteger configGeneration;
@property(nonatomic,strong,readonly) NSDate *timestamp; // local successful receipt
@property(nonatomic,strong,readonly,nullable) NSDate *serverTimestamp;
@property(nonatomic,strong,readonly,nullable) NSTimeZone *timezone;
@property(nonatomic,strong,readonly,nullable) NSNumber *currentTemperature;
@property(nonatomic,strong,readonly,nullable) NSNumber *maximum;
@property(nonatomic,strong,readonly,nullable) NSNumber *minimum;
@property(nonatomic,strong,readonly) CYCondition *condition;
@property(nonatomic,copy,readonly) NSArray<CYHour *> *hours;
@end
@interface CYResult : NSObject
@property(nonatomic,strong,readonly,nullable) CYSnapshot *snapshot;
@property(nonatomic,strong,readonly,nullable) NSError *error; // only local sanitized errors
@property(nonatomic,readonly) BOOL stale;
@property(nonatomic,readonly) NSUInteger configGeneration;
@property(nonatomic,strong,readonly,nullable) NSDate *nextAllowedRefresh;
@end

#ifdef CY_TESTING
// TEST BUILD ONLY. No real NSURLSession/Keychain is needed for injected tests.
typedef void (^CYWireReply)(NSData * _Nullable, NSInteger, NSDictionary *, NSError * _Nullable);
typedef dispatch_block_t _Nonnull (^CYTransport)(NSURLRequest *, CYWireReply);
@protocol CYTokenStore <NSObject>
- (nullable NSString *)readToken:(NSError * _Nullable * _Nullable)error;
- (BOOL)writeToken:(NSString *)token error:(NSError * _Nullable * _Nullable)error;
- (BOOL)removeToken:(NSError * _Nullable * _Nullable)error;
@end
#endif

@interface CYCaiyunProvider : NSObject
// All public instance calls must be on main thread; callbacks always on main thread.
// One instance per module; same-process SpringBoard keychain, no access group.
- (instancetype)init;
+ (BOOL)validateLongitude:(nullable NSNumber *)longitude latitude:(nullable NSNumber *)latitude;
+ (BOOL)validateToken:(NSString *)token;
- (BOOL)hasToken:(NSError * _Nullable * _Nullable)error;
// Every save/delete attempt invalidates pending work and cached data, even on failure.
- (BOOL)saveToken:(NSString *)token error:(NSError * _Nullable * _Nullable)error;
- (BOOL)deleteToken:(NSError * _Nullable * _Nullable)error;
// nil,nil = missing; 0,0 = valid. Alias/provider prefs remain integrator-owned.
// Invalid input invalidates old configuration and leaves provider unconfigured.
- (BOOL)setLongitude:(nullable NSNumber *)longitude latitude:(nullable NSNumber *)latitude error:(NSError * _Nullable * _Nullable)error;
- (CYResult *)currentResult;
@property(nonatomic) NSTimeInterval cacheTTL;
// Nonmanual respects cacheTTL (unset/invalid = 15min); manual bypasses TTL, not 60s throttle/backoff.
// Concurrent callers join one request; automatic callers use a single deadline, never polling.
- (void)refreshManual:(BOOL)manual completion:(void (^)(CYResult *))completion;
- (void)cancel; // cancels all waiters with CYCancelled; preserves same-config cache
- (void)clearCache; // cancels requests and increments config generation, keeps throttle
#ifdef CY_TESTING
- (instancetype)initWithStore:(id<CYTokenStore>)store transport:(CYTransport)transport clock:(NSDate *(^)(void))clock;
+ (nullable CYSnapshot *)parseFixture:(NSDictionary *)json now:(NSDate *)now generation:(NSUInteger)generation;
#endif
@end
NS_ASSUME_NONNULL_END
