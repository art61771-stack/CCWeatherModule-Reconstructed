#import "WCCMedia.h"
#import "WCCAssetKeys.h"
#include <sys/stat.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>

// FIFO serial preparation, independent of the number of visible players.
// Waiting MP4 metadata has a timeout, so a broken asset cannot starve the tail.
static dispatch_queue_t WCCPreparationQueue(void) {
    static dispatch_queue_t queue; static dispatch_once_t once;
    dispatch_once(&once, ^{ queue=dispatch_queue_create("com.simon.ccweather.prepare",DISPATCH_QUEUE_SERIAL); });
    return queue;
}
static CGImageSourceRef WCCSource(NSString *path) {
    NSDictionary *a = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
    if (![a[NSFileType] isEqual:NSFileTypeRegular] || [a[NSFileSize] unsignedLongLongValue] > 8*1024*1024) return NULL;
    CGImageSourceRef s = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
    if (!s) return NULL;
    NSDictionary *p = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(s, 0, NULL));
    NSUInteger w = [p[(__bridge NSString *)kCGImagePropertyPixelWidth] unsignedIntegerValue];
    NSUInteger h = [p[(__bridge NSString *)kCGImagePropertyPixelHeight] unsignedIntegerValue];
    if (!w || !h || w > 8192 || h > 8192 || w*h > 32000000 || CGImageSourceGetCount(s) > 120) { CFRelease(s); return NULL; }
    return s;
}
static UIImage *WCCFrame(CGImageSourceRef s, NSUInteger i) {
    if (!s) return nil;
    CGImageRef im = CGImageSourceCreateThumbnailAtIndex(s, i, (__bridge CFDictionaryRef)@{
        (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways:@YES,
        (__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform:@YES,
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately:@YES,
        (__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize:@256});
    if (!im) return nil;
    UIImage *result = [UIImage imageWithCGImage:im]; CGImageRelease(im); return result;
}
UIImage *WCCDecode(NSString *path) {
    CGImageSourceRef s = WCCSource(path); UIImage *im = WCCFrame(s, 0); if (s) CFRelease(s); return im;
}
NSData *WCCPreview(NSString *path) { UIImage *im = WCCDecode(path); return im ? UIImagePNGRepresentation(im) : nil; }

@implementation WCCMediaView {
    UIImageView *_image;
    CGImageSourceRef _source;
    NSUInteger _frame, _generation;
    NSTimer *_timer;
    AVQueuePlayer *_player;
    AVPlayerLooper *_looper;
    AVPlayerLayer *_layer;
    NSString *_path, *_identity;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        _image = [[UIImageView alloc] initWithFrame:self.bounds];
        _image.contentMode = UIViewContentModeScaleAspectFit; _image.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:_image];
    } return self;
}
- (BOOL)hasMedia { return _image.image != nil || (_layer.readyForDisplay && _player.status != AVPlayerStatusFailed && _looper.status != AVPlayerLooperStatusFailed); }
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)self) {
        NSUInteger generation=_generation;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!WCCMediaCallbackCurrent(generation,self->_generation,object==self->_layer || object==self->_player || object==self->_looper)) return;
            [self notifyMedia];
        });
    } else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
- (void)notifyMedia { if (self.mediaChanged) self.mediaChanged(); }
- (void)layoutSubviews { [super layoutSubviews]; _layer.frame = self.bounds; }
- (void)clear {
    [_layer removeObserver:self forKeyPath:@"readyForDisplay" context:(__bridge void *)self];
    [_player removeObserver:self forKeyPath:@"status" context:(__bridge void *)self];
    [_looper removeObserver:self forKeyPath:@"status" context:(__bridge void *)self];
    [_timer invalidate]; _timer = nil; [_player pause]; [_looper disableLooping];
    [_player removeAllItems]; _looper = nil; _player = nil; [_layer removeFromSuperlayer]; _layer = nil;
    if (_source) { CFRelease(_source); _source = NULL; } _image.image = nil; _frame = 0;
}
- (void)dealloc { [self clear]; }
- (void)didMoveToWindow { [super didMoveToWindow]; if (!self.window) { [_timer invalidate]; _timer = nil; [_player pause]; } else [self resume]; }
- (void)setActive:(BOOL)active {
    if (_active == active) return; // Never reset the GIF deadline on steady state.
    _active = active; [_timer invalidate]; _timer = nil;
    if (!active) [_player pause]; else [self resume];
}
- (void)resume {
    if (!_active || !self.window) return;
    if (_player) [_player play];
    if (!_source || CGImageSourceGetCount(_source) < 2 || _timer) return;
    NSDictionary *props = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(_source, _frame, NULL));
    NSDictionary *gif = props[(__bridge NSString *)kCGImagePropertyGIFDictionary];
    NSNumber *delay = gif[(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime] ?: gif[(__bridge NSString *)kCGImagePropertyGIFDelayTime];
    NSTimeInterval duration = MAX(.05, MIN(2.0, delay ? delay.doubleValue : .1));
    __weak typeof(self) weak = self;
    _timer = [NSTimer scheduledTimerWithTimeInterval:duration repeats:NO block:^(NSTimer *t) {
        typeof(self) self = weak; if (!self) return; self->_timer = nil;
        if (!self->_source || !self->_active || !self.window) return;
        self->_frame = (self->_frame + 1) % CGImageSourceGetCount(self->_source);
        UIImage *frame = WCCFrame(self->_source, self->_frame);
        if (!frame) { CFRelease(self->_source); self->_source = NULL; return; }
        self->_image.image = frame; [self resume];
    }];
}
- (void)loadPath:(NSString *)path {
    // Nanosecond stat identity: stable layout/weather refreshes preserve playback;
    // in-place writes, atomic replacements and deletions invalidate the cache.
    struct stat st; NSString *identity=nil;
    if (path && stat(path.fileSystemRepresentation,&st)==0 && S_ISREG(st.st_mode))
        identity=[NSString stringWithFormat:@"%@:%llu:%llu:%lld:%lld:%ld:%lld:%ld",path,(unsigned long long)st.st_dev,(unsigned long long)st.st_ino,(long long)st.st_size,(long long)st.st_mtimespec.tv_sec,st.st_mtimespec.tv_nsec,(long long)st.st_ctimespec.tv_sec,st.st_ctimespec.tv_nsec];
    if (!identity) path=nil;
    if ((!path && !_path) || ([_path isEqual:path] && [_identity isEqual:identity])) { [self notifyMedia]; [self resume]; return; }
    _path=[path copy]; _identity=identity;
    NSUInteger generation=++_generation; [self clear]; [self notifyMedia]; if (!path) return;
    if ([path.pathExtension.lowercaseString isEqual:@"mp4"]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
        __weak typeof(self) weak = self;
        dispatch_async(WCCPreparationQueue(), ^{
            __block BOOL current=NO;
            dispatch_sync(dispatch_get_main_queue(), ^{ typeof(self) self=weak; current=self && generation==self->_generation; });
            if (!current) return;
            dispatch_semaphore_t done=dispatch_semaphore_create(0);
            [asset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration", @"playable"] completionHandler:^{ dispatch_semaphore_signal(done); }];
            if (dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,10*NSEC_PER_SEC))) [asset cancelLoading];
            dispatch_sync(dispatch_get_main_queue(), ^{
                typeof(self) self = weak; if (!self || generation != self->_generation) return;
                if ([asset statusOfValueForKey:@"tracks" error:nil] != AVKeyValueStatusLoaded || [asset statusOfValueForKey:@"duration" error:nil] != AVKeyValueStatusLoaded || [asset statusOfValueForKey:@"playable" error:nil] != AVKeyValueStatusLoaded || !asset.playable) { if (self.mediaFailed) self.mediaFailed(@"视频读取或解码失败（请检查 MP4 编码及文件权限）"); return; }
                AVAssetTrack *video = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
                CGSize size = video.naturalSize; double duration = CMTimeGetSeconds(asset.duration);
                if (!video || !isfinite(duration) || duration <= 0 || duration > 30 || fabs(size.width) > 1920 || fabs(size.height) > 1920) { if (self.mediaFailed) self.mediaFailed(@"视频无有效画面，或超过30秒/1920px限制"); return; }
                // Compose video only: no audio track and no audio session activation.
                AVMutableComposition *composition = [AVMutableComposition composition];
                AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                NSError *compositionError = nil;
                if (![track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:video atTime:kCMTimeZero error:&compositionError]) { if (self.mediaFailed) self.mediaFailed(compositionError.localizedDescription ?: @"视频轨道读取失败"); return; }
                track.preferredTransform = video.preferredTransform;
                AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:composition];
                self->_player = [AVQueuePlayer new]; self->_player.muted = YES;
                self->_looper = [AVPlayerLooper playerLooperWithPlayer:self->_player templateItem:item];
                self->_layer = [AVPlayerLayer playerLayerWithPlayer:self->_player]; self->_layer.videoGravity = AVLayerVideoGravityResizeAspect;
                [self->_layer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:(__bridge void *)self];
                [self->_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void *)self];
                [self->_looper addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void *)self];
                self->_layer.frame = self.bounds; [self.layer addSublayer:self->_layer]; [self notifyMedia]; [self resume];
            });
        }];
    } else {
        __weak typeof(self) weak=self;
        dispatch_async(WCCPreparationQueue(), ^{
            __block BOOL current=NO;
            dispatch_sync(dispatch_get_main_queue(), ^{ typeof(self) self=weak; current=self && generation==self->_generation; });
            if (!current) return;
            CGImageSourceRef source=WCCSource(path); UIImage *first=WCCFrame(source,0);
            dispatch_sync(dispatch_get_main_queue(), ^{
                typeof(self) self=weak;
                if (!self || generation != self->_generation) { if (source) CFRelease(source); return; }
                self->_source=source; self->_image.image=first;
                if (!first && self.mediaFailed) self.mediaFailed(@"图片读取/解码失败，或超过尺寸/帧数限制；请刷新图库。");
                [self notifyMedia]; [self resume];
            });
        });
    }
}
@end
