#import "WCCFloatingPanel.h"
#import "WCCRegionSettings.h"
#import "WCCPreferences.h"
#import "WCCConfigurations.h"
#include <math.h>
#import "WCCRuntime.h"
@interface WCCRegionSettings () <UIColorPickerViewControllerDelegate>
@property(nonatomic) NSInteger colorGroup;
@end
@implementation WCCRegionSettings
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"布局与文字"; self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=100;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sync) name:WCCRegionPositionChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sync) name:WCCMainIconScaleChanged object:nil];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)done { void (^done)(void)=self.onDone; self.onDone=nil; if(done) [self dismissViewControllerAnimated:YES completion:done]; }
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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table { return 13; }
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section { return section==12?7:section>=9?5:section==8?WCCGreetingEntries().count+1:section==6?3:3; }
- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section { return @[@"温度（含高低温）",@"主天气图标",@"地区 · 天气 · 降水",@"问候语",@"配置方案",@"文字阴影",@"自定义问候",@"文字发光",@"问候语列表（每条独立保存）",@"温度阴影 / 发光颜色与动态",@"地区阴影 / 发光颜色与动态",@"问候阴影 / 发光颜色与动态",@"主图阴影 / 发光（独立第四组）"][section]; }
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section {
    if(section==12)return @"仅主图；阴影/发光默认关闭。系统图、PNG/GIF按合成透明度投影；MP4仅矩形容器光晕，不识别视频主体。呼吸中心标准3秒，左慢右快。颜色浓淡左淡右深：左端0%，中点新标准60%，右端100%；阴影/发光一致，与拾色器透明度相乘。模块外缘仍可能被系统容器裁剪，动态轮廓未真机验证。";
    if(section>=9)return @"自定义颜色同时作用该组阴影/发光。呼吸默认关闭；速度中心标准3秒，左慢6秒，右快1.5秒。颜色浓淡独立于速度，左淡右深：左端0%，中点新标准60%，右端100%。阴影/发光一致，新中点比旧1.2.3效果略淡。拾色器透明度与浓淡相乘，不改原内容透明度。仅可见控制中心运行；关闭效果后不动画。";
    if(section==0)return @"八个位置仅作用折叠五种尺寸；展开保持原布局。水平 −1366…+1366 pt 可到左右边缘，垂直 −40…+40 pt。当前值为请求位移，边界处限幅；用 −1/+1 精调或点击数值输入。";
    if(section==4)return @"v4方案保存颜色、呼吸开关及速度，另含八个位置、两种主图大小、三组阴影/发光、自定义问候及完整列表和随机开关。不含天气来源、定位、token、映射或模块尺寸。读取前备份成功才提交；旧版方案大小迁移到两模式，缺少阴影和自定义问候明确恢复关闭/空文本。";
    if(section==5)return @"三组独立，默认关闭；折叠与展开同组生效，不改变小时文字。";
    if(section==6)return @"旧固定句保留（最多80字符）。启用自定义后：随机关闭固定显示旧句，无旧句显示列表首句；随机开启仅在下拉控制中心或展开/收回时切换。位置、阴影与布局不抽句。";
    if(section==7)return @"三组独立默认关闭，仅主页面文字；同组发光开启时替代普通阴影，关闭后恢复阴影或原始样式。边缘光晕可能被容器裁剪；未真机验证。";
    if(section==8)return @"无条数或单条长度人为上限。点击编辑，左滑删除；新增/编辑只保存当前条，取消不保存。重复文本可存但随机候选去重；空列表回退旧固定句。v3方案完整保存列表、随机和发光；读取旧v1/v2方案保留这些新设置。";
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if(index.section>=9) {
        NSInteger group=index.section-9;NSArray *v=WCCTextEffectSettings(group);
        cell.textLabel.text=@[@"自定义颜色…",@"恢复自动颜色",@"明暗呼吸",@"左慢 · 标准 · 右快",@"颜色浓淡 · 中点标准",@"主图阴影",@"主图发光"][index.row];
        if(index.row>=5) { UISwitch *on=[UISwitch new];on.tag=index.row;on.on=index.row==5?WCCTextShadowEnabled(3):WCCTextGlowEnabled(3);[on addTarget:self action:@selector(iconEffect:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=on; }
        if(index.row==2) { UISwitch *on=[UISwitch new];on.tag=group;on.on=[v[1] boolValue];[on addTarget:self action:@selector(breathe:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=on; }
        if(index.row==4) { UISlider *density=[UISlider new];density.minimumValue=-1;density.maximumValue=1;density.value=[v[3] doubleValue];density.tag=group;density.continuous=NO;density.frame=CGRectMake(0,0,140,40);density.accessibilityLabel=@"颜色浓淡，左淡，中点标准，右深";[density addTarget:self action:@selector(density:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=density; }
        if(index.row==3) { UISlider *speed=[UISlider new];speed.minimumValue=-1;speed.maximumValue=1;speed.value=[v[2] doubleValue];speed.tag=group;speed.continuous=NO;speed.frame=CGRectMake(0,0,140,40);speed.accessibilityLabel=@"呼吸速度，中心标准，左慢右快";[speed addTarget:self action:@selector(speed:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=speed; }
    } else if(index.section==8) {
        cell.textLabel.text=index.row==0?@"＋ 新增一句":WCCGreetingEntries()[index.row-1][@"text"];
        cell.textLabel.numberOfLines=0;cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    } else if(index.section==7 || (index.section==6 && index.row==2)) {
        UISwitch *toggle=[UISwitch new];toggle.tag=index.section==7?10+index.row:20;
        toggle.on=index.section==7?WCCTextGlowEnabled(index.row):WCCRandomGreetingEnabled();
        [toggle addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=toggle;
        cell.textLabel.text=index.section==7?@[@"温度 · 高低温",@"城市 · 天气 · 降水",@"问候"][index.row]:@"随机语句（需启用自定义）";
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    } else if(index.section==5 || (index.section==6 && index.row==0)) {
        UISwitch *toggle=[UISwitch new];toggle.tag=index.section==5?index.row:3;
        toggle.on=index.section==5?WCCTextShadowEnabled(index.row):WCCCustomGreetingEnabled();
        [toggle addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=toggle;
        cell.textLabel.text=index.section==5?@[@"温度 · 高低温",@"城市 · 天气 · 降水",@"问候"] [index.row]:@"启用自定义问候";
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
- (void)iconEffect:(UISwitch *)sender { BOOL ok=sender.tag==5?WCCSetTextShadowEnabled(3,sender.on):WCCSetTextGlowEnabled(3,sender.on);if(!ok)[self failed]; }
- (void)density:(UISlider *)sender { NSMutableArray *v=[WCCTextEffectSettings(sender.tag) mutableCopy];v[3]=@(sender.value);if(!WCCSetTextEffectSettings(sender.tag,v))[self failed]; }
- (void)breathe:(UISwitch *)sender { NSMutableArray *v=[WCCTextEffectSettings(sender.tag) mutableCopy];v[1]=@(sender.on);if(!WCCSetTextEffectSettings(sender.tag,v))[self failed]; }
- (void)speed:(UISlider *)sender { NSMutableArray *v=[WCCTextEffectSettings(sender.tag) mutableCopy];v[2]=@(sender.value);if(!WCCSetTextEffectSettings(sender.tag,v))[self failed]; }
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)picker {
    CGFloat r,g,b,a;if(![picker.selectedColor getRed:&r green:&g blue:&b alpha:&a])return;
    NSMutableArray *v=[WCCTextEffectSettings(self.colorGroup) mutableCopy];v[0]=@[@(r),@(g),@(b),@(a)];
    if(!WCCSetTextEffectSettings(self.colorGroup,v))[self failed];
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
    BOOL ok=sender.tag==20?WCCSetRandomGreetingEnabled(sender.on):sender.tag>=10?WCCSetTextGlowEnabled(sender.tag-10,sender.on):sender.tag<3?WCCSetTextShadowEnabled(sender.tag,sender.on):WCCSetCustomGreeting(sender.on,WCCCustomGreetingText());
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
- (void)editEntry:(NSDictionary *)entry {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:entry?@"编辑这一句":@"新增一句" message:@"非空且无控制字符；保存仅修改这一条。" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.text=entry[@"text"]?:@"";}];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        if(!WCCSaveGreetingEntry(entry[@"id"],a.textFields.firstObject.text))
            dispatch_async(dispatch_get_main_queue(),^{[self error:[NSError errorWithDomain:@"WCC" code:1 userInfo:@{NSLocalizedDescriptionKey:@"未保存：文字不能为空或包含控制字符；原列表保留。"}]];});
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)index { return index.section==8 && index.row>0; }
- (void)tableView:(UITableView *)table commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)index {
    if(style!=UITableViewCellEditingStyleDelete || index.section!=8 || index.row==0)return;
    NSArray *rows=WCCGreetingEntries(); if(index.row>rows.count)return;
    if(!WCCDeleteGreetingEntry(rows[index.row-1][@"id"]))[self failed];
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
    if(index.section>=9 && index.row<2) {
        self.colorGroup=index.section-9;NSMutableArray *v=[WCCTextEffectSettings(self.colorGroup) mutableCopy];
        if(index.row==1) { v[0]=@[];if(!WCCSetTextEffectSettings(self.colorGroup,v))[self failed]; }
        else if(@available(iOS 14.0,*)) {
            UIColorPickerViewController *picker=[UIColorPickerViewController new];picker.delegate=self;picker.supportsAlpha=YES;
            NSArray *c=v[0];picker.selectedColor=c.count==4?[UIColor colorWithRed:[c[0] doubleValue] green:[c[1] doubleValue] blue:[c[2] doubleValue] alpha:[c[3] doubleValue]]:UIColor.whiteColor;
            [self presentViewController:picker animated:YES completion:nil];
        }
    }
    if(index.section<4 && index.row==2) [self confirm:@"重置本区域位置？" work:^{[self resetRegion:index.section];}];
    if(index.section==6 && index.row==1)[self editGreeting];
    if(index.section==8) { NSArray *rows=WCCGreetingEntries(); if(index.row==0)[self editEntry:nil]; else if(index.row<=rows.count)[self editEntry:rows[index.row-1]]; }
    if(index.section==4){ if(index.row==0)[self saveName]; else if(index.row==1)[self plans]; else [self confirm:@"重置全部八个位置？" work:^{[self resetRegion:-1];}]; }
}
- (void)tableView:(UITableView *)table willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)index { WCCPanelStyleCell(cell); }
- (void)tableView:(UITableView *)table willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section { WCCPanelStyleSection(view); }
- (void)tableView:(UITableView *)table willDisplayFooterView:(UIView *)view forSection:(NSInteger)section { WCCPanelStyleSection(view); }
@end
