#import "WCCRegionSettings.h"
#import "WCCPreferences.h"
#import "WCCConfigurations.h"
#include <math.h>
@implementation WCCRegionSettings
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"区域位置"; self.tableView.rowHeight=72;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sync) name:WCCRegionPositionChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sync) name:WCCMainIconScaleChanged object:nil];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)done { [self dismissViewControllerAnimated:YES completion:self.onDone]; }
- (void)sync { [self.tableView reloadData]; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller { return UIModalPresentationNone; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traits { return UIModalPresentationNone; }
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popover { return NO; }
- (void)error:(NSError *)error { if (!error) return; UIAlertController *a=[UIAlertController alertControllerWithTitle:@"未完成" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert]; [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
- (void)confirm:(NSString *)title work:(void (^)(void))work {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:@"取消不会修改任何设置或文件。" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){ dispatch_async(dispatch_get_main_queue(),work); }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table { return 5; }
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section { return section<4?3:3; }
- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section { return @[@"温度（含高低温）",@"主天气图标",@"地区 · 天气 · 降水",@"问候语",@"配置方案"][section]; }
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section { return section==0?@"仅主页面，不影响展开页面。水平：左 −40 / 中点 0 / 右 +40；垂直：上 −40 / 中点 0 / 下 +40。步长 1pt，实时保存；边界处显示位移受限。":section==4?@"方案仅保存八个位置值及主图大小。不含素材映射、开关或模块规格。读取前自动备份当前九值；主图大小仍作用主页面及展开头部。":nil; }
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if(index.section<4 && index.row<2) {
        NSInteger tag=index.section*2+index.row; UISlider *slider=[UISlider new]; slider.minimumValue=-40; slider.maximumValue=40; slider.value=WCCRegionOffset(tag); slider.tag=tag;
        UILabel *label=[UILabel new]; label.font=[UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular]; label.tag=100;
        label.text=[NSString stringWithFormat:@"%@  %+.0f pt",index.row?@"上 ← 垂直 → 下":@"左 ← 水平 → 右",slider.value];
        slider.accessibilityLabel=[NSString stringWithFormat:@"%@ %@",[self tableView:table titleForHeaderInSection:index.section],index.row?@"垂直":@"水平"];
        slider.accessibilityValue=[NSString stringWithFormat:@"%+.0f pt",slider.value];
        [slider addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
        UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[label,slider]]; stack.axis=UILayoutConstraintAxisVertical; stack.translatesAutoresizingMaskIntoConstraints=NO; [cell.contentView addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],[stack.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],[stack.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:4],[stack.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-4]]];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    } else { cell.textLabel.text=index.section<4?@"重置本区域":@[@"命名保存 / 新建方案",@"读取 / 覆盖 / 删除方案",@"重置全部位置"][index.row]; cell.textLabel.font=[UIFont systemFontOfSize:15]; cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator; }
    return cell;
}
- (void)changed:(UISlider *)slider {
    double value=round(slider.value); // Avoid replacing the actively tracking slider during notification.
    [NSNotificationCenter.defaultCenter removeObserver:self name:WCCRegionPositionChanged object:nil];
    BOOL ok=WCCSetRegionOffset(slider.tag,value);
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sync) name:WCCRegionPositionChanged object:nil];
    slider.value=WCCRegionOffset(slider.tag); UILabel *label=[slider.superview viewWithTag:100]; label.text=[NSString stringWithFormat:@"%@  %+.0f pt",slider.tag%2?@"上 ← 垂直 → 下":@"左 ← 水平 → 右",slider.value]; slider.accessibilityValue=[NSString stringWithFormat:@"%+.0f pt",slider.value];
    if(!ok)[self error:[NSError errorWithDomain:@"WCC" code:1 userInfo:@{NSLocalizedDescriptionKey:@"偏好同步失败，请重试。"}]];
}
- (void)saveName {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"保存配置方案" message:@"1–40字；同名覆盖需要再次确认。" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *field){field.placeholder=@"方案名称";}];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        NSString *name=[a.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(),^{ NSError *error=nil; NSArray *list=WCCConfigurations(&error); if(!list){[self error:error];return;}
            for(NSDictionary *item in list) if([item[@"name"] caseInsensitiveCompare:name]==NSOrderedSame){[self confirm:@"覆盖同名方案？" work:^{NSError *e=nil; WCCSaveConfiguration(name,item[@"id"],&e); [self error:e];}];return;}
            WCCSaveConfiguration(name,nil,&error); [self error:error];
        });
    }]]; [self presentViewController:a animated:YES completion:nil];
}
- (void)plans {
    NSError *error=nil; NSArray *list=WCCConfigurations(&error); if(!list){[self error:error];return;}
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"配置方案" message:list.count?@"选择方案以读取、覆盖或删除。":@"尚无方案，请先命名保存。" preferredStyle:UIAlertControllerStyleAlert];
    for(NSDictionary *item in list)[a addAction:[UIAlertAction actionWithTitle:item[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){dispatch_async(dispatch_get_main_queue(),^{[self plan:item];});}]];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:a animated:YES completion:nil];
}
- (void)plan:(NSDictionary *)item {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:item[@"name"] message:@"读取立即生效，无需注销；读取失败保留当前设置。" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"读取" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){dispatch_async(dispatch_get_main_queue(),^{NSError *e=nil; WCCLoadConfiguration(item[@"id"],&e); [self error:e];});}]];
    [a addAction:[UIAlertAction actionWithTitle:@"用当前值覆盖" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){dispatch_async(dispatch_get_main_queue(),^{[self confirm:@"确认覆盖？" work:^{NSError *e=nil; WCCSaveConfiguration(item[@"name"],item[@"id"],&e); [self error:e];}];});}]];
    [a addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){dispatch_async(dispatch_get_main_queue(),^{[self confirm:@"确认删除方案？" work:^{NSError *e=nil; WCCDeleteConfiguration(item[@"id"],&e); [self error:e];}];});}]];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:a animated:YES completion:nil];
}
- (void)resetRegion:(NSInteger)region {
    if (!WCCResetRegionOffsets(region)) [self error:[NSError errorWithDomain:@"WCC" code:1 userInfo:@{NSLocalizedDescriptionKey:@"重置同步失败，请重试。"}]];
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index {
    [table deselectRowAtIndexPath:index animated:YES];
    if(index.section<4 && index.row==2) [self confirm:@"重置本区域位置？" work:^{[self resetRegion:index.section];}];
    if(index.section==4){ if(index.row==0)[self saveName]; else if(index.row==1)[self plans]; else [self confirm:@"重置全部八个位置？" work:^{[self resetRegion:-1];}]; }
}
@end
