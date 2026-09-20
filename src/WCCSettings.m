#import "WCCSettings.h"
#import "WCCPreferences.h"
#import "WCCGallery.h"
@implementation WCCSettings
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"天气 · 设置";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [NSFileManager.defaultManager createDirectoryAtPath:WCCRoot() withIntermediateDirectories:YES attributes:nil error:nil];
}
- (void)done { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 3 : 2; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @[@"自定义图标",@"模块尺寸",@"地标显示"][section]; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @[@"关闭后立即恢复天气原图。素材目录：Documents/CCWeatherModule/Icons。动画仅在可见时播放；超限或损坏素材不加载。",@"列 × 行。保存后请手动注销 SpringBoard 生效；不会自动注销。关闭恢复原始 4×1。需要 CCSupport 的运行时尺寸支持。",@"地标名称与显示方式立即保存。留空自定义地标可恢复自动显示。"][section];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    NSInteger s = index.section, r = index.row;
    if ((s == 0 || s == 1) && r == 0) {
        cell.textLabel.text = s == 0 ? @"使用自定义图标" : @"使用自定义尺寸";
        UISwitch *toggle = [UISwitch new]; toggle.tag = s; toggle.on = [WCCPrefs() boolForKey:s == 0 ? @"customIcon" : @"customSize"];
        [toggle addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged]; cell.accessoryView = toggle;
    } else if (s == 0) {
        cell.textLabel.text = r == 1 ? @"浏览 HTML 动态图库" : @"用 Filza 打开素材目录";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (s == 1) {
        cell.textLabel.text = @"列 × 行"; UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"2×1",@"3×1",@"4×1"]];
        NSInteger cols = [WCCPrefs() integerForKey:@"columns"]; seg.selectedSegmentIndex = cols >= 2 && cols <= 4 ? cols-2 : 2;
        [seg addTarget:self action:@selector(size:) forControlEvents:UIControlEventValueChanged]; cell.accessoryView = seg;
    } else if (r == 0) {
        cell.textLabel.text = @"地标模式"; UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"附近",@"城市",@"自定"]];
        seg.selectedSegmentIndex = MAX(0,MIN(2,[WCCPrefs() integerForKey:@"displayMode"]));
        [seg addTarget:self action:@selector(mode:) forControlEvents:UIControlEventValueChanged]; cell.accessoryView = seg;
    } else { cell.textLabel.text = @"编辑自定义地标"; cell.detailTextLabel.text = [WCCPrefs() stringForKey:@"landmark"] ?: @"未设置"; }
    return cell;
}
- (void)save { [WCCPrefs() synchronize]; [NSNotificationCenter.defaultCenter postNotificationName:WCCPreferencesChanged object:nil]; }
- (void)toggle:(UISwitch *)sender { [WCCPrefs() setBool:sender.on forKey:sender.tag == 0 ? @"customIcon" : @"customSize"]; [self save]; }
- (void)size:(UISegmentedControl *)sender { [WCCPrefs() setInteger:sender.selectedSegmentIndex+2 forKey:@"columns"]; [self save]; }
- (void)mode:(UISegmentedControl *)sender { [WCCPrefs() setInteger:sender.selectedSegmentIndex forKey:@"displayMode"]; [self save]; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index {
    [tableView deselectRowAtIndexPath:index animated:YES];
    if (index.section == 0 && index.row == 1) { [self.navigationController pushViewController:[WCCGallery new] animated:YES]; return; }
    if (index.section == 0 && index.row == 2) {
        NSString *url = [@"filza://view" stringByAppendingString:[WCCRoot() stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet]];
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:url] options:@{} completionHandler:^(BOOL ok) {
            if (!ok) dispatch_async(dispatch_get_main_queue(), ^{ UIAlertController *a = [UIAlertController alertControllerWithTitle:@"无法打开 Filza" message:WCCRoot() preferredStyle:UIAlertControllerStyleAlert]; [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]]; [self presentViewController:a animated:YES completion:nil]; });
        }]; return;
    }
    if (index.section != 2 || index.row != 1) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义地标" message:@"留空恢复附近地标" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.text = [WCCPrefs() stringForKey:@"landmark"]; field.placeholder = @"例如：我的家"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *name = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (name.length > 80) name = [name substringToIndex:80];
        [WCCPrefs() setObject:name forKey:@"landmark"]; [WCCPrefs() setInteger:name.length ? 2 : 0 forKey:@"displayMode"]; [self save]; [self.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
