#import "WCCGallery.h"
#import "WCCPreferences.h"
#import "WCCMedia.h"
#import <WebKit/WebKit.h>
@interface WCCGallery () <WKNavigationDelegate>
@end
@implementation WCCGallery {
    WKWebView *_web;
    WCCMediaView *_preview;
    NSArray<NSString *> *_names;
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"动态图标图库"; self.view.backgroundColor = UIColor.systemBackgroundColor;
    _preview = [[WCCMediaView alloc] initWithFrame:CGRectZero]; [self.view addSubview:_preview];
    __weak typeof(self) weak = self;
    _preview.mediaFailed = ^(NSString *reason) { [weak showFailure:reason]; };
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
    config.allowsInlineMediaPlayback = YES;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    _web = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config]; _web.navigationDelegate = self; [self.view addSubview:_web];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    [self reload];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; CGFloat top = self.view.safeAreaInsets.top;
    _preview.frame = CGRectMake((self.view.bounds.size.width-96)/2, top+8,96,96);
    _web.frame = CGRectMake(0,top+112,self.view.bounds.size.width,MAX(0,self.view.bounds.size.height-top-112));
}
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; _preview.active = YES; }
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated]; _preview.active = NO; }
static NSString *WCCEscape(NSString *text) {
    return [[[[[text ?: @"" stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"] stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"] stringByReplacingOccurrencesOfString:@"'" withString:@"&#39;"];
}
- (void)reload {
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *failures = [NSMutableArray array];
    NSError *directoryError = nil;
    NSArray *files = [[NSFileManager.defaultManager contentsOfDirectoryAtPath:WCCRoot() error:&directoryError] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableString *html = [NSMutableString stringWithString:@"<!doctype html><meta name='viewport' content='width=device-width,initial-scale=1'><meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; img-src data:; media-src data:; style-src 'unsafe-inline'\"><style>:root{color-scheme:light dark}body{font:15px -apple-system;margin:16px}main{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}a{color:inherit;text-decoration:none;border:1px solid #8884;border-radius:18px;padding:12px 6px;text-align:center;overflow-wrap:anywhere;background:#8881}img,video{width:64px;height:64px;object-fit:contain}small{display:block;opacity:.65}h2{font-weight:650}p{color:#888;font-size:13px;white-space:pre-wrap}</style><h2>让天气，多一点个性</h2><p>GIF/MP4 卡片动态预览（总预算8MB，超额点击顶部播放）· 轻触应用 · 最多显示60项。PNG/JPG/GIF/MP4 ≤8MB；GIF ≤120帧；视频 ≤30秒/1920px。导入后点刷新。</p><main>"];
    NSUInteger previewBytes = 0;
    for (NSString *name in files) {
        NSString *reason = nil;
        NSString *path = WCCCheckedPath(WCCRoot(), name, &reason);
        if (!path) { [failures addObject:[NSString stringWithFormat:@"%@：%@", name, reason]]; continue; }
        if (names.count >= 60) { [failures addObject:[name stringByAppendingString:@"：超过60项显示限额"]]; continue; }
        BOOL video = [path.pathExtension.lowercaseString isEqual:@"mp4"];
        NSData *data = video ? nil : WCCPreview(path);
        if (!video && !data) { [failures addObject:[name stringByAppendingString:@"：图片解码失败或超过8192px/3200万像素/120帧限制"]]; continue; }
        // Preserve GIF bytes and MP4 bytes for genuine HTML animation, not PNG stand-ins.
        BOOL gif = [path.pathExtension.lowercaseString isEqual:@"gif"];
        NSString *mime = video ? @"video/mp4" : (gif ? @"image/gif" : @"image/png");
        if (video || gif) data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
        if (previewBytes + data.length > 8*1024*1024) data = nil;
        previewBytes += data.length;
        NSString *card = @"<div style='height:64px;font-size:30px'>▷</div><small>点击顶部预览</small>";
        if (data) {
            NSString *uri = [NSString stringWithFormat:@"data:%@;base64,%@",mime,[data base64EncodedStringWithOptions:0]];
            card = video ? [NSString stringWithFormat:@"<video autoplay muted loop playsinline preload='metadata' src='%@'></video><small>视频预览·点击应用</small>",uri] : [NSString stringWithFormat:@"<img src='%@'>",uri];
        }
        [html appendFormat:@"<a href='wcc-select://item/%lu'>%@<small>%@</small></a>",(unsigned long)names.count,card,WCCEscape(name)];
        [names addObject:name];
    }
    [html appendString:@"</main>"];
    [html appendFormat:@"<p>导入目录：%@<br>实际读取：%@<br>刷新时间：%@<br>扫描 %lu 项，显示 %lu 项。仅扫描当前目录；导入或替换后点右上角刷新。</p>", WCCEscape(WCCRoot()), WCCEscape(WCCRoot().stringByResolvingSymlinksInPath), WCCEscape(NSDate.date.description), (unsigned long)files.count, (unsigned long)names.count];
    if (directoryError) [html appendFormat:@"<p>目录读取失败（%@/%ld）：%@</p>", WCCEscape(directoryError.domain), (long)directoryError.code, WCCEscape(directoryError.localizedDescription)];
    else if (!files.count) [html appendString:@"<p>目录为空。请将素材文件直接导入上方目录（不是其子文件夹）。</p>"];
    if (failures.count) [html appendFormat:@"<details open><summary>未显示原因（%lu 项）</summary><p>%@</p></details>", (unsigned long)failures.count, WCCEscape([failures componentsJoinedByString:@"\n"])];
    // Native process reads files. WebKit receives embedded PNG/GIF/MP4 data URLs,
    // never file:// URLs: no sandbox read grant or file-name URL encoding is needed.
    _names = names; [_web loadHTMLString:html baseURL:nil];
    [_preview loadPath:WCCSafePath(WCCRoot(), [WCCPrefs() stringForKey:@"icon"])];
}
- (void)showFailure:(NSString *)reason {
    if (!self.view.window || self.presentedViewController) return;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"素材读取失败" message:reason preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error { [self showFailure:error.localizedDescription]; }
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error { [self showFailure:error.localizedDescription]; }
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView { [self showFailure:@"图库网页进程已停止，请点右上角刷新。"]; }
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    NSURL *url = action.request.URL;
    if ([url.scheme isEqual:@"about"] && action.navigationType == WKNavigationTypeOther) { handler(WKNavigationActionPolicyAllow); return; }
    handler(WKNavigationActionPolicyCancel);
    if (!action.targetFrame.isMainFrame || ![url.scheme isEqual:@"wcc-select"] || ![url.host isEqual:@"item"]) return;
    NSString *component = url.lastPathComponent;
    NSScanner *scanner = [NSScanner scannerWithString:component]; NSInteger index;
    if (![scanner scanInteger:&index] || !scanner.isAtEnd || index < 0 || index >= (NSInteger)_names.count) return;
    NSString *name = _names[index], *reason = nil;
    NSString *path = WCCCheckedPath(WCCRoot(), name, &reason);
    if (!path) { [self showFailure:[NSString stringWithFormat:@"%@：%@。请刷新图库。", name, reason]]; return; }
    [WCCPrefs() setObject:name forKey:@"icon"]; [WCCPrefs() setBool:YES forKey:@"customIcon"]; [WCCPrefs() synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:WCCPreferencesChanged object:nil];
    [_preview loadPath:path]; self.title = @"已应用 · 可继续选择";
}
@end
