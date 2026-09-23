#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
@interface UIColor : NSObject
@property(nonatomic,readonly) CGColorRef CGColor;
+ (instancetype)whiteColor;
+ (instancetype)blackColor;
+ (instancetype)colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a;
+ (instancetype)colorWithCGColor:(CGColorRef)color;
- (instancetype)resolvedColorWithTraitCollection:(id)traits;
- (BOOL)getRed:(CGFloat *)r green:(CGFloat *)g blue:(CGFloat *)b alpha:(CGFloat *)a;
- (BOOL)getWhite:(CGFloat *)w alpha:(CGFloat *)a;
@end
@interface UIView : NSObject
@property(nonatomic,strong) CALayer *layer;
@property(nonatomic) CGRect bounds;
@end
@interface UIBezierPath : NSObject
@property(nonatomic,readonly) CGPathRef CGPath;
+ (instancetype)bezierPathWithRect:(CGRect)rect;
@end
@interface UILabel : UIView
@property(nonatomic,strong) UIColor *textColor;
@property(nonatomic,strong) UIColor *shadowColor;
@property(nonatomic) CGSize shadowOffset;
@property(nonatomic,strong) id traitCollection;
@end
