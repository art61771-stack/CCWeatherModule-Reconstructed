#import "WCCGallery.h"
#import "WCCPreferences.h"
#import "WCCMedia.h"
#import "WCCGalleryBridge.h"
@interface WCCGallery () <WKNavigationDelegate, UITableViewDataSource, UITableViewDelegate>
@end
@implementation WCCGallery {
    WKWebView *_web;
    WCCGalleryBridge *_bridge;
    WCCMediaView *_preview;
    UITableView *_table;
    UILabel *_status;
    UISegmentedControl *_mode;
    NSArray<NSString *> *_names;
    NSArray<NSDictionary *> *_items;
    NSString *_scanMessage, *_pendingName;
    NSUInteger _generation, _webFailures;
    BOOL _ready, _native, _retryUsed, _scanning;
    dispatch_queue_t _scanQueue;
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"动态图标图库"; self.view.backgroundColor=UIColor.systemBackgroundColor;
    _preview=[[WCCMediaView alloc] initWithFrame:CGRectZero]; [self.view addSubview:_preview];
    __weak typeof(self) weak=self; _preview.mediaFailed=^(NSString *reason){ typeof(self) owner=weak; if (owner) owner->_pendingName=nil; [weak showFailure:reason]; };
    _preview.mediaChanged=^{ [weak commitPreviewSelection]; };
    _mode=[[UISegmentedControl alloc] initWithItems:@[@"HTML 动态图库",@"原生列表"]]; _mode.selectedSegmentIndex=0;
    [_mode addTarget:self action:@selector(changeMode) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:_mode];
    _status=[UILabel new]; _status.font=[UIFont systemFontOfSize:11]; _status.textColor=UIColor.secondaryLabelColor; _status.numberOfLines=3; [self.view addSubview:_status];
    _table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain]; _table.dataSource=self; _table.delegate=self; _table.hidden=YES; [self.view addSubview:_table];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    [self buildWeb]; [self reload];
}
- (void)buildWeb {
    [_bridge invalidate]; [_web stopLoading]; _web.navigationDelegate=nil; [_web removeFromSuperview]; _ready=NO;
    _bridge=[WCCGalleryBridge new]; _bridge.names=_names;
    WKWebViewConfiguration *config=[WKWebViewConfiguration new];
    config.websiteDataStore=WKWebsiteDataStore.nonPersistentDataStore;
    config.allowsInlineMediaPlayback=YES; config.mediaTypesRequiringUserActionForPlayback=WKAudiovisualMediaTypeNone;
    [config setURLSchemeHandler:_bridge forURLScheme:@"wcc-media"];
    _web=[[WKWebView alloc] initWithFrame:CGRectZero configuration:config]; _web.navigationDelegate=self; [self.view addSubview:_web];
    NSString *path=[[NSBundle bundleForClass:self.class] pathForResource:@"Gallery" ofType:@"html"];
    NSString *shell=path ? [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] : nil;
    if (!shell) { [self webUnavailable:@"HTML资源缺失，请重新安装；原生列表仍可选择素材。"]; return; }
    [_web loadHTMLString:shell baseURL:nil]; [self.view setNeedsLayout];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; CGFloat top=self.view.safeAreaInsets.top,w=self.view.bounds.size.width;
    _preview.frame=CGRectMake(16,top+8,64,64); _mode.frame=CGRectMake(92,top+8,MAX(0,w-108),30);
    _status.frame=CGRectMake(92,top+41,MAX(0,w-108),48);
    CGRect area=CGRectMake(0,top+96,w,MAX(0,self.view.bounds.size.height-top-96-self.view.safeAreaInsets.bottom)); _web.frame=area; _table.frame=area;
    _web.hidden=_native; _table.hidden=!_native;
}
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; _preview.active=YES; if (!_native) [_web evaluateJavaScript:@"window.resumeGallery&&resumeGallery()" completionHandler:nil]; }
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated]; _preview.active=NO; [_web evaluateJavaScript:@"window.pauseGallery&&pauseGallery()" completionHandler:nil]; }
- (void)dealloc { [_bridge invalidate]; _web.navigationDelegate=nil; }
- (void)changeMode {
    if (_mode.selectedSegmentIndex==0 && _webFailures) {
        _mode.selectedSegmentIndex=1;
        if (_retryUsed) { _status.text=@"网页再次停止，本次使用原生列表。重新打开图库可重试；请保留系统进程日志。"; return; }
        UIAlertController *a=[UIAlertController alertControllerWithTitle:@"重试 HTML 图库一次？" message:@"网页进程退出原因尚未确定；原生列表不依赖网页进程。不会自动循环刷新。" preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"继续原生列表" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"重试一次" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){ self->_retryUsed=YES; self->_webFailures=0; self->_native=NO; self->_mode.selectedSegmentIndex=0; [self buildWeb]; }]];
        [self presentViewController:a animated:YES completion:nil]; return;
    }
    _native=_mode.selectedSegmentIndex==1; [_web evaluateJavaScript:_native?@"window.pauseGallery&&pauseGallery()":@"window.resumeGallery&&resumeGallery()" completionHandler:nil]; [self.view setNeedsLayout];
}
- (void)reload {
    if (_scanning) return; _scanning=YES;
    if (!_scanQueue) _scanQueue=dispatch_queue_create("weather.gallery.scan",DISPATCH_QUEUE_SERIAL);
    NSUInteger generation=++_generation; _status.text=@"正在读取素材目录…";
    [_bridge invalidate]; [_web evaluateJavaScript:@"window.pauseGallery&&pauseGallery()" completionHandler:nil];
    __weak typeof(self) weak=self;
    dispatch_async(_scanQueue, ^{
        NSError *error=nil; NSArray *files=[[NSFileManager.defaultManager contentsOfDirectoryAtPath:WCCRoot() error:&error] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        NSMutableArray *names=[NSMutableArray array], *items=[NSMutableArray array], *failures=[NSMutableArray array];
        for (NSString *name in files) {
            NSString *reason=nil,*path=WCCCheckedPath(WCCRoot(),name,&reason);
            if (!path) { [failures addObject:[NSString stringWithFormat:@"%@：%@",name,reason]]; continue; }
            if (names.count>=60) { [failures addObject:[name stringByAppendingString:@"：超过60项显示限额"]]; continue; }
            [items addObject:@{@"id":@(names.count),@"name":name,@"video":@([path.pathExtension.lowercaseString isEqual:@"mp4"])}]; [names addObject:name];
        }
        NSString *message=[NSString stringWithFormat:@"目录：%@\n实际读取：%@\n扫描%lu项，列出%lu项（选择时验证解码）%@%@",WCCRoot(),WCCRoot().stringByResolvingSymlinksInPath,(unsigned long)files.count,(unsigned long)names.count,error?[NSString stringWithFormat:@"\n目录读取失败 %@/%ld：%@",error.domain,(long)error.code,error.localizedDescription]:(!files.count?@"\n目录为空，请直接导入文件而不是子目录":@""),failures.count?[@"\n" stringByAppendingString:[failures componentsJoinedByString:@"\n"]]:@""];
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self=weak; if (!self || generation!=self->_generation) return;
            self->_scanning=NO; self->_names=names; self->_items=items; self->_scanMessage=message; self->_bridge.names=names;
            [self->_table reloadData]; self->_status.text=self->_webFailures?@"网页进程不可用，原生列表可预览/选择。刷新只重新扫描文件，不重启网页。":@"轻触条目应用；上方原生预览。刷新重新扫描同一 Icons 目录。";
            [self populate];
        });
    });
    _pendingName=nil; [_preview loadPath:WCCSafePath(WCCRoot(),[WCCPrefs() stringForKey:@"icon"])];
}
- (void)populate {
    if (!_ready || !_items) return;
    NSData *json=[NSJSONSerialization dataWithJSONObject:@[_items,_scanMessage?:@""] options:0 error:nil];
    NSString *script=[NSString stringWithFormat:@"window.populate.apply(null,%@)",[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    [_web evaluateJavaScript:script completionHandler:nil];
    if (!_native && self.view.window) [_web evaluateJavaScript:@"window.resumeGallery&&resumeGallery()" completionHandler:nil];
}
- (void)webUnavailable:(NSString *)reason {
    _webFailures++; _native=YES; _ready=NO; _mode.selectedSegmentIndex=1; [_bridge invalidate]; [_web stopLoading]; _status.text=reason; [self.view setNeedsLayout];
}
- (void)showFailure:(NSString *)reason {
    _status.text=reason;
    if (!self.view.window || self.presentedViewController) return;
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"素材预览未完成" message:reason preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:a animated:YES completion:nil];
}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section { return _names.count; }
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell=[table dequeueReusableCellWithIdentifier:@"file"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"file"];
    cell.textLabel.text=_names[index.row]; cell.textLabel.numberOfLines=2; cell.detailTextLabel.text=@"轻触应用 · 原生预览 GIF / MP4 / 图片"; cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator; return cell;
}
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section { return _scanMessage; }
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index { [table deselectRowAtIndexPath:index animated:YES]; [self choose:index.row]; }
- (void)choose:(NSInteger)index {
    if (_scanning || index<0 || index>=(NSInteger)_names.count) return;
    NSString *name=_names[index],*reason=nil,*path=WCCCheckedPath(WCCRoot(),name,&reason);
    if (!path) { [self showFailure:reason]; return; }
    _pendingName=name; self.title=@"正在验证素材…"; [_preview loadPath:path];
}
- (void)commitPreviewSelection {
    if (!_pendingName || !_preview.hasMedia) return;
    NSString *name=_pendingName; _pendingName=nil;
    [WCCPrefs() setObject:name forKey:@"icon"]; [WCCPrefs() setBool:YES forKey:@"customIcon"]; [WCCPrefs() synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:WCCPreferencesChanged object:nil]; self.title=@"已应用 · 原生预览";
}
- (void)webView:(WKWebView *)web didFinishNavigation:(WKNavigation *)navigation { if (web!=_web) return; _ready=YES; [self populate]; }
- (void)webView:(WKWebView *)web didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error { if (web==_web && error.code!=NSURLErrorCancelled) [self webUnavailable:[NSString stringWithFormat:@"网页加载失败 %@/%ld：%@；已切换原生列表。",error.domain,(long)error.code,error.localizedDescription]]; }
- (void)webView:(WKWebView *)web didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error { [self webView:web didFailNavigation:navigation withError:error]; }
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)web { if (web==_web) [self webUnavailable:@"图库网页进程已停止（原因未确定），已切换原生列表。可选 HTML 手动重试一次。不是目录读取错误。 "]; }
- (void)webView:(WKWebView *)web decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    NSURL *url=action.request.URL;
    if ([url.scheme isEqual:@"about"] && action.navigationType==WKNavigationTypeOther) { handler(WKNavigationActionPolicyAllow); return; }
    handler(WKNavigationActionPolicyCancel);
    if (!action.targetFrame.isMainFrame || ![url.scheme isEqual:@"wcc-select"] || ![url.host isEqual:@"item"]) return;
    NSInteger index; NSScanner *scanner=[NSScanner scannerWithString:url.lastPathComponent]; if ([scanner scanInteger:&index] && scanner.isAtEnd) [self choose:index];
}
@end
