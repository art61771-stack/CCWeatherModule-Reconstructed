#import "mock124.inc"
#import "../src/WCCRefreshPolicy.h"
#import "../src/WCCConfigurations.h"
static void near125(double a,double b){assert(fabs(a-b)<.00001);}
int main(void){@autoreleasepool{
 NSString *suite=[@"features125." stringByAppendingString:NSUUID.UUID.UUIDString];WCCTestUsePreferences(suite);
 NSString *dir=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];WCCTestUseConfigurationDirectory(dir);NSError *error=nil;
 UIView *v=[UIView new];v.layer.opacity=.8;CATransform3D base=CATransform3DMakeScale(1.42,.73,1);base.m41=17;base.m42=-12;v.layer.transform=base;
 NSArray *keys=@[@"wcc.icon.opacity.breathe125",@"wcc.icon.transform.scale125"];
 CABasicAnimation *other=[CABasicAnimation animationWithKeyPath:@"position"];other.duration=9;[v.layer addAnimation:other forKey:@"other"];
 assert(([WCCMainContentSettings(0) isEqual:@[@NO,@0]]));assert(([WCCMainContentSettings(1) isEqual:@[@NO,@0]]));
 for(int opacity=0;opacity<2;opacity++)for(int scale=0;scale<2;scale++)for(int x=-1;x<=1;x++)for(int y=-1;y<=1;y++){
  NSArray *a=@[@((BOOL)opacity),@(x)],*b=@[@((BOOL)scale),@(y)];
  assert(WCCSetMainContentSettings(0,a));assert(WCCSetMainContentSettings(1,b));
  WCCApplyMainIconEffects(v,NO,YES,@[@[],@YES,@0,@0],YES,NO);
  for(int active=1;active>=0;active--){
   WCCApplyMainContentAnimations(v,a,b,active);
   assert(CATransform3DEqualToTransform(v.layer.transform,base));near125(v.layer.opacity,.8);
   assert([v.layer animationForKey:@"other"]);assert([v.layer animationForKey:@"wcc.icon.shadowOpacity.breathe124"]);
   for(int i=0;i<2;i++){
    CABasicAnimation *anim=(id)[v.layer animationForKey:keys[i]];
    if(active && (i?scale:opacity)){
     assert(anim && anim.autoreverses);near125(anim.duration,WCCBreathDuration(i?y:x)/2);
     if(i){assert(!anim.additive);assert([anim.keyPath isEqual:@"transform.scale"]);near125([anim.fromValue doubleValue],.94);near125([anim.toValue doubleValue],1.06);}
     else {near125([anim.fromValue doubleValue],.8*.45);near125([anim.toValue doubleValue],.8);}
    }else assert(!anim);
   }
  }
  WCCApplyMainContentAnimations(v,a,b,YES);assert((BOOL)[v.layer animationForKey:keys[0]]==(BOOL)opacity);assert((BOOL)[v.layer animationForKey:keys[1]]==(BOOL)scale);
 }
 assert(WCCSetMainContentSettings(0,@[@YES,@-1]));assert(WCCSetMainContentSettings(1,@[@YES,@1]));
 NSDictionary *snapshot=WCCCurrentSliderValues();assert(snapshot.count==29);assert(WCCSaveConfiguration(@"v5",nil,&error));NSString *identifier=WCCConfigurations(&error)[0][@"id"];
 assert(WCCSetMainContentSettings(0,@[@NO,@0]));NSDictionary *changed=WCCCurrentSliderValues();assert(WCCLoadConfiguration(identifier,&error));assert([snapshot isEqual:WCCCurrentSliderValues()]);
 assert(WCCLoadConfiguration(@"00000000-0000-0000-0000-000000000000",&error));assert([changed isEqual:WCCCurrentSliderValues()]);
 WCCTestFailCommit(YES);assert(!WCCSetMainContentSettings(0,@[@YES,@1]));assert(!WCCLoadConfiguration(identifier,&error));assert([changed isEqual:WCCCurrentSliderValues()]);WCCTestFailCommit(NO);
 assert(!WCCSetMainContentSettings(0,@[@1,@0]));assert(!WCCSetMainContentSettings(1,@[@YES,@2]));assert(!WCCSetMainContentSettings(1,@[@YES,@YES]));assert(!WCCSetMainContentSettings(2,@[@YES,@0]));
 assert(!WCCNormalizePresentationValues(@{@"mainOpacity125":@[@YES,@(NAN)]},5));
 for(int version=1;version<=4;version++){NSDictionary *old=WCCNormalizePresentationValues(@{},version);assert(old && !old[@"mainOpacity125"]);assert(WCCCommitSliderValues(old));assert([WCCMainContentSettings(0) isEqual:changed[@"mainOpacity125"]]);assert([WCCMainContentSettings(1) isEqual:changed[@"mainScale125"]]);}
 assert(WCCCommitSliderValues(WCCNormalizePresentationValues(@{},5)));assert(([WCCMainContentSettings(0) isEqual:@[@NO,@0]]));
 [WCCPrefs() removePersistentDomainForName:suite];[NSFileManager.defaultManager removeItemAtPath:dir error:NULL];
 puts("PASS125 production preferences/config transaction + real CALayer: independent opacity/scale/shadow coexisting; 36 speed/switch combinations; endpoints/non-additive child transform/base opacity and position preserved; inactive removes own keys and resumes; v5 backup/load/rollback; v1..v4 preservation. UIKit shim; no device pixel rendering.");
}return 0;}
