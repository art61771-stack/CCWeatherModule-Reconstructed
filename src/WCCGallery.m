#import "WCCFloatingPanel.h"
#import "WCCGallery.h"
#import "WCCPreferences.h"
#import "WCCMedia.h"
@interface WCCGallery () <UITableViewDataSource, UITableViewDelegate>
@end
@implementation WCCGallery {
    WCCMediaView *_preview;
    UITableView *_table;
    UILabel *_status;
    NSArray<NSString *> *_names;
    NSString *_scanMessage, *_pendingName;
    NSUInteger _generation;
    BOOL _scanning;
    dispatch_queue_t _scanQueue;
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=[@"替换 · " stringByAppendingString:self.targetKey ?: @"未选天气"]; self.view.backgroundColor=UIColor.systemBackgroundColor;
    _preview=[[WCCMediaView alloc] initWithFrame:CGRectZero]; [self.view addSubview:_preview];
    __weak typeof(self) weak=self; _preview.mediaFailed=^(NSString *reason){ typeof(self) owner=weak; if (owner) owner->_pendingName=nil; [weak showFailure:reason]; };
    _preview.mediaChanged=^{ [weak commitPreviewSelection]; };
    _status=[UILabel new]; _status.font=[UIFont systemFontOfSize:11]; _status.textColor=UIColor.secondaryLabelColor; _status.numberOfLines=3; [self.view addSubview:_status];
    _table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain]; _table.dataSource=self; _table.delegate=self; [self.view addSubview:_table];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    [self reload];
}
- (void)applySettingsPanelStyle {
    _table.backgroundColor=WCCPanelTransparent()?UIColor.clearColor:UIColor.systemBackgroundColor;
    _status.textColor=WCCPanelTransparent()?UIColor.whiteColor:UIColor.secondaryLabelColor;
    [_table reloadData];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; CGFloat top=self.view.safeAreaInsets.top,w=self.view.bounds.size.width;
    _preview.frame=CGRectMake(16,top+8,64,64);
    _status.frame=CGRectMake(92,top+8,MAX(0,w-108),72);
    _table.frame=CGRectMake(0,top+88,w,MAX(0,self.view.bounds.size.height-top-88-self.view.safeAreaInsets.bottom));
}
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; _preview.active=YES; }
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated]; _pendingName=nil; [_preview loadPath:nil]; _preview.active=NO; }
- (void)reload {
    if (_scanning) return; _scanning=YES;
    if (!_scanQueue) _scanQueue=dispatch_queue_create("weather.gallery.scan",DISPATCH_QUEUE_SERIAL);
    NSUInteger generation=++_generation; _status.text=@"正在读取素材目录…";
    __weak typeof(self) weak=self;
    dispatch_async(_scanQueue, ^{
        NSError *error=nil; NSArray *files=[[NSFileManager.defaultManager contentsOfDirectoryAtPath:WCCRoot() error:&error] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        NSMutableArray *names=[NSMutableArray array], *failures=[NSMutableArray array];
        for (NSString *name in files) {
            NSString *reason=nil,*path=WCCCheckedPath(WCCRoot(),name,&reason);
            if (!path) { [failures addObject:[NSString stringWithFormat:@"%@：%@",name,reason]]; continue; }
            if (names.count>=60) { [failures addObject:[name stringByAppendingString:@"：超过60项显示限额"]]; continue; }
            [names addObject:name];
        }
        NSString *message=[NSString stringWithFormat:@"目录：%@\n实际读取：%@\n扫描%lu项，列出%lu项（选择时验证解码）%@%@",WCCRoot(),WCCRoot().stringByResolvingSymlinksInPath,(unsigned long)files.count,(unsigned long)names.count,error?[NSString stringWithFormat:@"\n目录读取失败 %@/%ld：%@",error.domain,(long)error.code,error.localizedDescription]:(!files.count?@"\n目录为空，请直接导入文件而不是子目录":@""),failures.count?[@"\n" stringByAppendingString:[failures componentsJoinedByString:@"\n"]]:@""];
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self=weak; if (!self || generation!=self->_generation) return;
            self->_scanning=NO; self->_names=names; self->_scanMessage=message;
            [self->_table reloadData]; self->_status.text=@"轻触条目验证后应用；上方原生动态预览。刷新重新扫描同一 Icons 目录。";
        });
    });
    _pendingName=nil; [_preview loadPath:WCCSafePath(WCCRoot(),WCCMappedName(self.targetKey))];
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
    cell.textLabel.text=_names[index.row]; cell.textLabel.numberOfLines=2; cell.detailTextLabel.text=@"轻触应用 · 原生预览 GIF / MP4 / 图片"; cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator; WCCPanelStyleCell(cell); return cell;
}
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section { return _scanMessage; }
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index { [table deselectRowAtIndexPath:index animated:YES]; [self choose:index.row]; }
- (void)choose:(NSInteger)index {
    if (![WCCAssetKeys() containsObject:self.targetKey ?: @""] || _scanning || index<0 || index>=(NSInteger)_names.count) return;
    NSString *name=_names[index],*reason=nil,*path=WCCCheckedPath(WCCRoot(),name,&reason);
    if (!path) { [self showFailure:reason]; return; }
    _pendingName=name; self.title=[@"验证 · " stringByAppendingString:self.targetKey ?: @"未选天气"]; [_preview loadPath:path];
}
- (void)commitPreviewSelection {
    if (!_pendingName || !_preview.hasMedia) return;
    NSString *name=_pendingName; _pendingName=nil;
    if (!WCCSetMappedName(self.targetKey,name)) { [self showFailure:@"目标天气无效、素材已失效或保存未确认；请重新选择。"]; return; }
    [NSNotificationCenter.defaultCenter postNotificationName:WCCPreferencesChanged object:nil]; self.title=[@"已绑定 · " stringByAppendingString:self.targetKey];
}
@end
