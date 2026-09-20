#import <WebKit/WebKit.h>
// Files are looked up by opaque numeric IDs, never by URL-supplied paths.
@interface WCCGalleryBridge : NSObject <WKURLSchemeHandler>
@property(nonatomic,copy) NSArray<NSString *> *names;
- (void)invalidate;
@end
