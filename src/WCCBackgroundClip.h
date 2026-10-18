#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WCCBackgroundClipSource) {
    WCCBackgroundClipSourceFallback = 0,
    WCCBackgroundClipSourceHostCorner = 1,
    WCCBackgroundClipSourceHostShape = 2,
};

/// Updates only the dedicated media container. It never changes root/host clipping.
FOUNDATION_EXPORT WCCBackgroundClipSource WCCUpdateBackgroundClipView(UIView *clipView, UIView *rootView);
FOUNDATION_EXPORT CGFloat WCCBackgroundFallbackRadius(CGSize size);
FOUNDATION_EXPORT BOOL WCCBackgroundPointVisible(UIView *clipView, CGPoint point);

NS_ASSUME_NONNULL_END
