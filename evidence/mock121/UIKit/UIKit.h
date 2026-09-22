#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
@interface UIColor : NSObject
@property(nonatomic,readonly) CGColorRef CGColor;
+ (instancetype)whiteColor;
+ (instancetype)blackColor;
+ (instancetype)colorWithCGColor:(CGColorRef)color;
- (instancetype)resolvedColorWithTraitCollection:(id)traits;
- (BOOL)getRed:(CGFloat *)r green:(CGFloat *)g blue:(CGFloat *)b alpha:(CGFloat *)a;
- (BOOL)getWhite:(CGFloat *)w alpha:(CGFloat *)a;
@end
@interface UILabel : NSObject
@property(nonatomic,strong) UIColor *textColor;
@property(nonatomic,strong) UIColor *shadowColor;
@property(nonatomic) CGSize shadowOffset;
@property(nonatomic,strong) CALayer *layer;
@property(nonatomic,strong) id traitCollection;
@end
