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
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
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
- (void)reload {
    NSMutableArray *names = [NSMutableArray array];
    NSArray *files = [[NSFileManager.defaultManager contentsOfDirectoryAtPath:WCCRoot() error:nil] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableString *html = [NSMutableString stringWithString:@"<!doctype html><meta name='viewport' content='width=device-width,initial-scale=1'><meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; img-src data:; style-src 'unsafe-inline'\"><style>:root{color-scheme:light dark}body{font:15px -apple-system;margin:16px}main{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}a{color:inherit;text-decoration:none;border:1px solid #8884;border-radius:18px;padding:12px 6px;text-align:center;overflow-wrap:anywhere;background:#8881}img{width:64px;height:64px;object-fit:contain}small{display:block;opacity:.65}h2{font-weight:650}p{color:#888;font-size:13px}</style><h2>让天气，多一点个性</h2><p>轻触选择 · 顶部播放所选动画 · 最多显示60项。PNG/JPG/GIF/MP4 ≤8MB；GIF ≤120帧；视频 ≤30秒/1920px。导入后点刷新。</p><main>"];
    NSUInteger previewBytes = 0;
    for (NSString *name in files) {
        if (names.count >= 60) break;
        NSString *path = WCCSafePath(WCCRoot(), name); if (!path) continue;
        BOOL video = [name.pathExtension.lowercaseString isEqual:@"mp4"];
        NSData *data = video ? nil : WCCPreview(path); if (!video && !data) continue;
        if (previewBytes + data.length > 4*1024*1024) break; previewBytes += data.length;
        NSString *escaped = [[[[name stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"] stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
        [html appendFormat:@"<a href='wcc-select://item/%lu'>%@<small>%@</small></a>",(unsigned long)names.count,video ? @"<div style='height:64px;font-size:40px'>▷</div>" : [NSString stringWithFormat:@"<img src='data:image/png;base64,%@'>",[data base64EncodedStringWithOptions:0]],escaped];
        [names addObject:name];
    }
    [html appendString:@"</main>"]; if (!names.count) [html appendString:@"<p>目录中暂无可用图标。请返回设置，用 Filza 导入。</p>"];
    _names = names; [_web loadHTMLString:html baseURL:nil];
    [_preview loadPath:WCCSafePath(WCCRoot(), [WCCPrefs() stringForKey:@"icon"])];
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    NSURL *url = action.request.URL;
    if ([url.scheme isEqual:@"about"] && action.navigationType == WKNavigationTypeOther) { handler(WKNavigationActionPolicyAllow); return; }
    handler(WKNavigationActionPolicyCancel);
    if (!action.targetFrame.isMainFrame || ![url.scheme isEqual:@"wcc-select"] || ![url.host isEqual:@"item"]) return;
    NSString *component = url.lastPathComponent;
    NSScanner *scanner = [NSScanner scannerWithString:component]; NSInteger index;
    if (![scanner scanInteger:&index] || !scanner.isAtEnd || index < 0 || index >= (NSInteger)_names.count) return;
    NSString *name = _names[index], *path = WCCSafePath(WCCRoot(), name); if (!path) return;
    [WCCPrefs() setObject:name forKey:@"icon"]; [WCCPrefs() setBool:YES forKey:@"customIcon"]; [WCCPrefs() synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:WCCPreferencesChanged object:nil];
    [_preview loadPath:path]; self.title = @"已应用 · 可继续选择";
}
@end
