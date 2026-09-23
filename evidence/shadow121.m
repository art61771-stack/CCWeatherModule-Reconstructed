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
int main(void){@autoreleasepool{
 NSString *suite=[@"test.shadow121." stringByAppendingString:NSUUID.UUID.UUIDString];WCCTestUsePreferences(suite);
 NSArray *labels=@[[UILabel new],[UILabel new],[UILabel new]];UILabel *hourly=[UILabel new];
 for(UILabel *l in labels){l.layer.shadowOpacity=.2;l.layer.shadowRadius=4;l.layer.masksToBounds=YES;l.shadowColor=UIColor.blackColor;l.shadowOffset=CGSizeMake(2,3);}
 __block int notes=0;
 id observer=[NSNotificationCenter.defaultCenter addObserverForName:WCCRegionPositionChanged object:nil queue:nil usingBlock:^(NSNotification *n){notes++;for(int i=0;i<3;i++)WCCApplyTextEffects(labels[i],WCCTextShadowEnabled(i),WCCTextGlowEnabled(i));}];
 for(int i=0;i<3;i++){
 int before=notes;assert(WCCSetTextShadowEnabled(i,YES));assert(notes==before+1);
 for(int j=0;j<3;j++){UILabel *l=labels[j];assert(l.layer.shadowOpacity==(j==i?.9f:.2f));}
 UILabel *l=labels[i];assert(!l.shadowColor && !l.layer.masksToBounds && l.layer.shadowRadius==1.25);
 WCCApplyTextShadow(l,YES);WCCApplyTextShadow(l,YES); // Repeated source/layout/expand reapply must not overwrite captured baseline.
 assert(WCCSetTextShadowEnabled(i,NO));assert(l.shadowColor && CGSizeEqualToSize(l.shadowOffset,CGSizeMake(2,3)));
 assert(l.layer.shadowOpacity==.2f && l.layer.shadowRadius==4 && l.layer.masksToBounds);
 }
 for(int i=0;i<3;i++){
  UILabel *l=labels[i];assert(WCCSetTextGlowEnabled(i,YES));
  assert(l.layer.shadowRadius==6 && l.layer.shadowOpacity==1 && CGSizeEqualToSize(l.layer.shadowOffset,CGSizeZero));
  assert(CGColorEqualToColor(l.layer.shadowColor,l.textColor.CGColor));
  for(int j=0;j<3;j++)if(j!=i)assert(((UILabel *)labels[j]).layer.shadowOpacity==.2f);
  assert(WCCSetTextShadowEnabled(i,YES));assert(l.layer.shadowRadius==6);
  assert(WCCSetTextGlowEnabled(i,NO));assert(l.layer.shadowRadius==1.25 && l.layer.shadowOpacity==.9f);
  assert(WCCSetTextShadowEnabled(i,NO));assert(l.layer.shadowRadius==4 && l.layer.shadowOpacity==.2f && l.layer.masksToBounds);
 }
 WCCTestFailCommit(YES);int before=notes;assert(!WCCSetTextShadowEnabled(0,YES));assert(notes==before && !WCCTextShadowEnabled(0));assert(!WCCSetTextGlowEnabled(0,YES));assert(notes==before && !WCCTextGlowEnabled(0));WCCTestFailCommit(NO);
 assert(hourly.layer.shadowOpacity==0);[NSNotificationCenter.defaultCenter removeObserver:observer];[WCCPrefs() removePersistentDomainForName:suite];
 puts("PASS121 actual production Preferences -> notification -> WCCTextShadow with mock UILabel and real CALayer; independence/reapply/off restoration/failed commit. UIKit glyph rendering NOT RUN.");
}}
