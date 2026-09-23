#import "../src/WCCTextShadow.h"
#import "../src/WCCPreferences.h"
#include <assert.h>
@implementation UIColor { CGColorRef _color; }
+ (instancetype)colorWithCGColor:(CGColorRef)c { UIColor *v=[self new];v->_color=CGColorRetain(c);return v; }
+ (instancetype)colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a { CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();CGFloat components[]={r,g,b,a};CGColorRef c=CGColorCreate(space,components);id v=[self colorWithCGColor:c];CGColorRelease(c);CGColorSpaceRelease(space);return v; }
+ (instancetype)whiteColor { CGColorRef c=CGColorCreateGenericGray(1,1);id v=[self colorWithCGColor:c];CGColorRelease(c);return v; }
+ (instancetype)blackColor { CGColorRef c=CGColorCreateGenericGray(0,1);id v=[self colorWithCGColor:c];CGColorRelease(c);return v; }
- (CGColorRef)CGColor{return _color;}
- (instancetype)resolvedColorWithTraitCollection:(id)t{return self;}
- (BOOL)getRed:(CGFloat *)r green:(CGFloat *)g blue:(CGFloat *)b alpha:(CGFloat *)a{return NO;}
- (BOOL)getWhite:(CGFloat *)w alpha:(CGFloat *)a{*w=CGColorGetComponents(_color)[0];*a=1;return YES;}
- (void)dealloc {if(_color)CGColorRelease(_color);}
@end
@implementation UIView
- (instancetype)init {if((self=[super init]))self.layer=[CALayer layer];return self;}
@end
@implementation UIBezierPath { CGPathRef _path; }
+ (instancetype)bezierPathWithRect:(CGRect)r { UIBezierPath *v=[self new];v->_path=CGPathCreateWithRect(r,NULL);return v;}
- (CGPathRef)CGPath{return _path;}
- (void)dealloc{if(_path)CGPathRelease(_path);}
@end
@implementation UILabel
- (instancetype)init {if((self=[super init])){self.layer=[CALayer layer];self.textColor=UIColor.whiteColor;}return self;}
@end
