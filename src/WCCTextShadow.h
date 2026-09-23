#import <UIKit/UIKit.h>
// Only call for labels owned by the module, never hourly/system labels.
void WCCApplyTextShadow(UILabel *label, BOOL enabled);
void WCCApplyTextEffects(UILabel *label, BOOL shadow, BOOL glow);

void WCCApplyConfiguredTextEffects(UILabel *label,BOOL shadow,BOOL glow,NSArray *settings,BOOL active);
void WCCApplyMainIconEffects(UIView *icon,BOOL shadow,BOOL glow,NSArray *settings,BOOL active,BOOL video);
