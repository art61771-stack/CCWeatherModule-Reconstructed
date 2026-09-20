#import "WCCGalleryBridge.h"
#import "WCCPreferences.h"
#import "WCCMedia.h"
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
@implementation WCCGalleryBridge {
    NSHashTable *_tasks;
    dispatch_queue_t _queue;
}
- (instancetype)init { if ((self=[super init])) { _tasks=[NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality]; _queue=dispatch_queue_create("weather.gallery.media", DISPATCH_QUEUE_SERIAL); } return self; }
- (void)invalidate { [_tasks removeAllObjects]; }
- (void)webView:(WKWebView *)web stopURLSchemeTask:(id<WKURLSchemeTask>)task { [_tasks removeObject:task]; }
- (void)webView:(WKWebView *)web startURLSchemeTask:(id<WKURLSchemeTask>)task {
    NSURL *url=task.request.URL; NSInteger index=-1; NSScanner *scan=[NSScanner scannerWithString:url.lastPathComponent];
    BOOL valid=[url.host isEqual:@"media"] && [scan scanInteger:&index] && scan.isAtEnd && index>=0 && index<(NSInteger)self.names.count && [url.path isEqual:[@"/" stringByAppendingString:url.lastPathComponent]];
    if (!valid || _tasks.count>=2) { [task didFailWithError:[NSError errorWithDomain:@"WCCGallery" code:1 userInfo:@{NSLocalizedDescriptionKey:@"无效或超出并发预算的媒体请求"}]]; return; }
    NSString *name=self.names[index]; [_tasks addObject:task];
    __weak typeof(self) weak=self;
    dispatch_async(_queue, ^{ @autoreleasepool {
        __block BOOL live=NO; dispatch_sync(dispatch_get_main_queue(), ^{ typeof(self) owner=weak; live=owner && [owner->_tasks containsObject:task]; }); if (!live) return;
        NSString *reason=nil, *path=WCCCheckedPath(WCCRoot(),name,&reason), *mime=@"image/png"; NSData *data=nil;
        if (path) {
            NSString *ext=path.pathExtension.lowercaseString;
            if ([ext isEqual:@"mp4"]) {
                AVURLAsset *asset=[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
                AVAssetTrack *track=[asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
                CGSize size=track.naturalSize; double duration=CMTimeGetSeconds(asset.duration);
                if (asset.playable && track && isfinite(duration) && duration>0 && duration<=30 && fabs(size.width)<=1920 && fabs(size.height)<=1920) { data=[NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil]; mime=@"video/mp4"; }
                else reason=@"视频不可播放或超出30秒/1920px限制";
            } else if ([ext isEqual:@"gif"]) {
                CGImageSourceRef source=CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path],NULL);
                NSDictionary *p=source ? CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL)) : nil;
                double w=[p[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue], h=[p[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
                size_t count=source ? CGImageSourceGetCount(source) : 0;
                // A compressed byte limit alone does not bound animated decode memory.
                if (count>0 && count<=120 && w>0 && h>0 && w<=1024 && h<=1024 && w*h*4*count<=16*1024*1024) { data=[NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil]; mime=@"image/gif"; }
                else reason=@"GIF超过网页动态预算，请使用上方原生预览（未删除素材）";
                if (source) CFRelease(source);
            } else { data=WCCPreview(path); if (!data) reason=@"图片解码失败或超出像素/帧数限制"; }
        }
        NSError *error=data ? nil : [NSError errorWithDomain:@"WCCGallery" code:2 userInfo:@{NSLocalizedDescriptionKey:reason ?: @"素材读取失败"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self=weak; if (!self || ![self->_tasks containsObject:task]) return;
            [self->_tasks removeObject:task];
            if (error) { [task didFailWithError:error]; return; }
            [task didReceiveResponse:[[NSURLResponse alloc] initWithURL:url MIMEType:mime expectedContentLength:data.length textEncodingName:nil]];
            [task didReceiveData:data]; [task didFinish];
        });
    }});
}
@end
