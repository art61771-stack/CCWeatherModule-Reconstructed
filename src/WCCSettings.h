#import <UIKit/UIKit.h>
@interface WCCSettings : NSObject
+ (void)cancelFrom:(UIViewController *)presenter;
+ (void)presentFrom:(UIViewController *)presenter completion:(void (^)(void))completion;
+ (void)editLandmarkFrom:(UIViewController *)presenter completion:(void (^)(void))completion;
@end
