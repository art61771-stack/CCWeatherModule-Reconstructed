#import "WCCFloatingPanel.h"
#import "WCCRegionSettings.h"
#import "WCCPreferences.h"
#import "WCCConfigurations.h"
#include <math.h>
#import "WCCRuntime.h"
@implementation WCCRegionSettings
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"布局与文字"; self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=100;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sync) name:WCCRegionPositionChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sync) name:WCCMainIconScaleChanged object:nil];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)done { [self.navigationController popViewControllerAnimated:YES]; }
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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table { return 7; }
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section { return section==6?2:3; }
- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section { return @[@"温度（含高低温）",@"主天气图标",@"地区 · 天气 · 降水",@"问候语",@"配置方案",@"文字阴影",@"自定义问候"][section]; }
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section {
    if(section==0)return @"八个位置仅作用折叠五种尺寸；展开保持原布局。水平 −1366…+1366 pt 可到左右边缘，垂直 −40…+40 pt。当前值为请求位移，边界处限幅；用 −1/+1 精调或点击数值输入。";
    if(section==4)return @"v2方案保存八个位置、折叠/展开两个主图大小、三组阴影及自定义问候开关/文本。不含天气来源、定位、token、映射或模块尺寸。读取前备份成功才提交；旧版方案大小迁移到两模式，缺少阴影和自定义问候明确恢复关闭/空文本。";
    if(section==5)return @"三组独立，默认关闭；折叠与展开同组生效，不改变小时文字。";
    if(section==6)return @"固定句子最多80个UTF-16字符，不接受空白或控制字符。关闭恢复分时随机去重；编辑取消保留原句。位置和阴影调整不会重新抽句。";
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if(index.section==5 || (index.section==6 && index.row==0)) {
        UISwitch *toggle=[UISwitch new];toggle.tag=index.section==5?index.row:3;
        toggle.on=index.section==5?WCCTextShadowEnabled(index.row):WCCCustomGreetingEnabled();
        [toggle addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=toggle;
        cell.textLabel.text=index.section==5?@[@"温度 · 高低温",@"城市 · 天气 · 降水",@"问候"] [index.row]:@"启用固定问候";
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    } else if(index.section==6) {
        cell.textLabel.text=WCCCustomGreetingText().length?WCCCustomGreetingText():@"编辑问候文本";cell.textLabel.numberOfLines=2;cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    } else if(index.section<4 && index.row<2) {
        NSInteger tag=index.section*2+index.row; UISlider *slider=[UISlider new]; slider.minimumValue=tag%2?-40:-1366; slider.maximumValue=tag%2?40:1366; slider.value=WCCRegionOffset(tag); slider.tag=tag;
        UILabel *label=[UILabel new]; label.font=[UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular]; label.tag=100;
        label.text=[NSString stringWithFormat:@"%@  %+.0f pt",index.row?@"上 ← 垂直 → 下":@"左 ← 水平 → 右",slider.value];
        slider.accessibilityLabel=[NSString stringWithFormat:@"%@ %@",[self tableView:table titleForHeaderInSection:index.section],index.row?@"垂直":@"水平"];
        slider.accessibilityValue=[NSString stringWithFormat:@"%+.0f pt",slider.value];
        [slider addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
        UIButton *minus=[UIButton buttonWithType:UIButtonTypeSystem];[minus setTitle:@"−1 pt" forState:UIControlStateNormal];minus.tag=tag*2;
        UIButton *plus=[UIButton buttonWithType:UIButtonTypeSystem];[plus setTitle:@"+1 pt" forState:UIControlStateNormal];plus.tag=tag*2+1;
        [minus addTarget:self action:@selector(step:) forControlEvents:UIControlEventTouchUpInside];[plus addTarget:self action:@selector(step:) forControlEvents:UIControlEventTouchUpInside];
        UIButton *entry=[UIButton buttonWithType:UIButtonTypeSystem];[entry setTitle:@"输入 pt" forState:UIControlStateNormal];entry.tag=tag;[entry addTarget:self action:@selector(enterOffset:) forControlEvents:UIControlEventTouchUpInside];
        UIStackView *buttons=[[UIStackView alloc] initWithArrangedSubviews:@[minus,entry,plus]];buttons.distribution=UIStackViewDistributionFillEqually;
        UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[label,slider,buttons]]; stack.axis=UILayoutConstraintAxisVertical; stack.translatesAutoresizingMaskIntoConstraints=NO; [cell.contentView addSubview:stack];
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
- (void)failed {
    [self error:[NSError errorWithDomain:@"WCC" code:1 userInfo:@{NSLocalizedDescriptionKey:@"未保存：请检查范围或文本（1–80字符且非空白）；原设置保持不变。"}]];
}
- (void)toggle:(UISwitch *)sender {
    BOOL ok=sender.tag<3?WCCSetTextShadowEnabled(sender.tag,sender.on):WCCSetCustomGreeting(sender.on,WCCCustomGreetingText());
    if(!ok){[self sync];[self failed];}
}
- (void)editGreeting {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"编辑固定问候" message:@"最多80字符；保存不改变开关。取消保留旧文本。" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.text=WCCCustomGreetingText();f.placeholder=@"例如：愿你今天一切顺利";}];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        NSString *text=[a.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        BOOL ok=text.length>0 && WCCSetCustomGreeting(WCCCustomGreetingEnabled(),text);
        if(!ok)dispatch_async(dispatch_get_main_queue(),^{[self failed];});
    }]];[self presentViewController:a animated:YES completion:nil];
}
- (void)step:(UIButton *)sender {
    NSInteger index=sender.tag/2;
    double limit=index%2?40:1366;
    double value=fmax(-limit,fmin(limit,WCCRegionOffset(index)+(sender.tag%2?1:-1)));
    if(!WCCSetRegionOffset(index,value))[self failed];
}
- (void)enterOffset:(UIButton *)sender {
    NSInteger index=sender.tag;
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"位置（pt）" message:index%2?@"垂直 −40…+40，整数":@"水平 −1366…+1366，整数；0恢复原位" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.text=[NSString stringWithFormat:@"%.0f",WCCRegionOffset(index)];f.keyboardType=UIKeyboardTypeNumbersAndPunctuation;}];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        NSScanner *scan=[NSScanner scannerWithString:a.textFields.firstObject.text?:@""];double n=0;
        BOOL valid=[scan scanDouble:&n] && scan.isAtEnd && isfinite(n) && n==WCCNormalizePositionOffset((int)index,n);
        if(!valid || !WCCSetRegionOffset(index,n))dispatch_async(dispatch_get_main_queue(),^{[self failed];});
    }]];[self presentViewController:a animated:YES completion:nil];
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
    if(index.section==6 && index.row==1)[self editGreeting];
    if(index.section==4){ if(index.row==0)[self saveName]; else if(index.row==1)[self plans]; else [self confirm:@"重置全部八个位置？" work:^{[self resetRegion:-1];}]; }
}
- (void)tableView:(UITableView *)table willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)index { WCCPanelStyleCell(cell); }
- (void)tableView:(UITableView *)table willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section { WCCPanelStyleSection(view); }
- (void)tableView:(UITableView *)table willDisplayFooterView:(UIView *)view forSection:(NSInteger)section { WCCPanelStyleSection(view); }
@end
