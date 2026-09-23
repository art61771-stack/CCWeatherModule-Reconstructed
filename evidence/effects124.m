#import "mock124.inc"
#import "../src/WCCRefreshPolicy.h"
static void near(double a,double b){assert(fabs(a-b)<.00001);}
int main(void){@autoreleasepool{
 NSString *suite=[@"effects124." stringByAppendingString:NSUUID.UUID.UUIDString];WCCTestUsePreferences(suite);
 NSArray *views=@[[UILabel new],[UILabel new],[UILabel new],[UIView new]];
 NSString *text=@"wcc.text.shadowOpacity.breathe124",*icon=@"wcc.icon.shadowOpacity.breathe124";
 for(int g=0;g<4;g++){
  UIView *v=views[g];v.bounds=CGRectMake(0,0,32,32);v.layer.shadowOpacity=.17;v.layer.shadowRadius=2;v.layer.masksToBounds=YES;
  CABasicAnimation *other=[CABasicAnimation animationWithKeyPath:@"opacity"];other.duration=999;[v.layer addAnimation:other forKey:@"unrelated"];
  for(int mode=0;mode<2;mode++)for(int breath=0;breath<2;breath++)for(int speed=-1;speed<=1;speed++)for(int d=-10;d<=10;d++){
   double density=d/10.;NSArray *settings=@[@[@.2,@.4,@.6,@.8],@(breath!=0),@(speed),@(density)];
   assert(WCCSetTextEffectSettings(g,settings));
   for(int j=0;j<4;j++)if(j!=g)assert(((UIView *)views[j]).layer.shadowOpacity==0 || fabs(((UIView *)views[j]).layer.shadowOpacity-.17)<.00001);
   if(g==3)WCCApplyMainIconEffects(v,!mode,mode,settings,YES,YES);else WCCApplyConfiguredTextEffects((UILabel *)v,!mode,mode,settings,YES);
   double high=WCCEffectOpacity(.6,density);near(v.layer.shadowOpacity,high);near(CGColorGetAlpha(v.layer.shadowColor),.8);
   NSString *key=g==3?icon:text;CABasicAnimation *a=(id)[v.layer animationForKey:key];
   if(breath){assert(a);near(a.duration,WCCBreathDuration(speed)/2);near([a.toValue doubleValue],high);near([a.fromValue doubleValue],WCCEffectLow(high,.6));assert(a.autoreverses);}
   else assert(!a);
   if(g==3)assert(v.layer.shadowPath);
   if(g==3)WCCApplyMainIconEffects(v,!mode,mode,settings,NO,NO);else WCCApplyConfiguredTextEffects((UILabel *)v,!mode,mode,settings,NO);
   assert(![v.layer animationForKey:key]);assert([v.layer animationForKey:@"unrelated"]);
   if(g==3)WCCApplyMainIconEffects(v,NO,NO,settings,NO,NO);else WCCApplyConfiguredTextEffects((UILabel *)v,NO,NO,settings,NO);
   near(v.layer.shadowOpacity,.17);assert(v.layer.shadowRadius==2 && v.layer.masksToBounds);assert(!v.layer.shadowPath);
  }
 }
 [WCCPrefs() removePersistentDomainForName:suite];
 puts("PASS124 production effect functions + real QuartzCore CALayer: four groups, shadow/glow, 21 densities, 3 speeds, RGBA alpha, animation endpoints/keys/inactive cleanup/unrelated key preservation/original restore; mock UIKit only, NOT glyph/video rendering");
}return 0;}
