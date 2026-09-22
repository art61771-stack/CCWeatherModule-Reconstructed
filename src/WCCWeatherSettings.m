#import "WCCFloatingPanel.h"
#import "WCCWeatherSettings.h"
#import "WCCWeatherSource.h"
#import "WCCPreferences.h"
@interface WCCWeatherSettings ()
@property(nonatomic,strong) UISegmentedControl *source;
@property(nonatomic,strong) NSArray<UITextField *> *fields;
@end
@implementation WCCWeatherSettings
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popover { return NO; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"天气来源";
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(done)];
    self.source=[[UISegmentedControl alloc] initWithItems:@[@"系统（默认）",@"彩云"]];
    self.source.selectedSegmentIndex=WCCWeatherSource.shared.caiyun?1:0;
    NSMutableArray *fields=[NSMutableArray array];
    NSArray *placeholders=@[@"Token（留空保留；不回显）",@"经度 -180 … 180",@"纬度 -90 … 90",@"显示别名（可选）"];
    for(NSInteger i=0;i<4;i++) {
        UITextField *f=[UITextField new]; f.placeholder=placeholders[i];
        f.autocorrectionType=UITextAutocorrectionTypeNo; f.autocapitalizationType=UITextAutocapitalizationTypeNone;
        f.secureTextEntry=i==0; f.keyboardType=(i==1||i==2)?UIKeyboardTypeNumbersAndPunctuation:UIKeyboardTypeDefault;
        f.clearButtonMode=UITextFieldViewModeWhileEditing;
        [fields addObject:f];
    }
    self.fields=fields;
    self.fields[1].text=[[WCCPrefs() objectForKey:@"caiyunLongitude"] description];
    self.fields[2].text=[[WCCPrefs() objectForKey:@"caiyunLatitude"] description];
    self.fields[3].text=[WCCPrefs() stringForKey:@"caiyunAlias"];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(changed) name:WCCWeatherSourceChanged object:nil];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)changed { [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2,2)] withRowAnimation:UITableViewRowAnimationNone]; }
- (void)done { self.fields[0].text=@""; void (^done)(void)=self.onDone; self.onDone=nil; if(done) [self dismissViewControllerAnimated:YES completion:done]; }
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller { return UIModalPresentationNone; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table { return 4; }
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section { return section==0?1:section==1?4:section==2?4:1; }
- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section { return @[@"来源（保存后生效）",@"彩云配置",@"操作（只使用已保存配置）",@"公开连接状态"][section]; }
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section {
    if(section==1)return @"经度在前、纬度在后，0,0 有效。未保存输入不请求网络。Token 仅存本机 Keychain，取消不会保存；别名为空显示“彩云地点”。不读取设备位置。";
    if(section==2)return @"保存/应用不发请求。测试连接与刷新均访问彩云综合接口并受60秒间隔和退避保护；可能计费。未启用彩云不读取Token、不发彩云请求。缓存15分钟，失败保留同配置旧数据。";
    return nil;
}
- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)index { return index.section==3?120:50; }
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    if(index.section==0 || index.section==1) {
        UIView *v=index.section==0?self.source:self.fields[index.row];
        v.frame=CGRectMake(14,5,MAX(180,table.bounds.size.width-28),40); v.autoresizingMask=UIViewAutoresizingFlexibleWidth;
        [cell.contentView addSubview:v]; cell.selectionStyle=UITableViewCellSelectionStyleNone;
    } else if(index.section==2) {
        cell.textLabel.text=@[@"保存 / 应用",@"测试已保存连接",@"刷新天气",@"删除已保存 Token…"][index.row];
        cell.textLabel.textColor=index.row==3?UIColor.systemRedColor:UIColor.systemBlueColor;
    } else {
        WCCWeatherSource *s=WCCWeatherSource.shared;
        NSString *token=s.caiyun?([s hasToken]?@"Token：已设置":@"Token：未设置 / 不可用"):@"系统模式：不读取 Token";
        cell.textLabel.numberOfLines=0; cell.textLabel.font=[UIFont systemFontOfSize:13];
        cell.textLabel.text=[NSString stringWithFormat:@"%@\n%@",token,s.status];
    } return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index {
    [table deselectRowAtIndexPath:index animated:YES]; if(index.section!=2)return;
    WCCWeatherSource *s=WCCWeatherSource.shared;
    if(index.row==0) {
        [self.view endEditing:YES];
        BOOL ok=[s applyCaiyun:self.source.selectedSegmentIndex==1 longitude:WCCParseCoordinate(self.fields[1].text,YES) latitude:WCCParseCoordinate(self.fields[2].text,NO) alias:self.fields[3].text token:self.fields[0].text];
        self.fields[0].text=@"";
        UIAlertController *a=[UIAlertController alertControllerWithTitle:ok?@"已应用":@"未应用" message:s.status preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:a animated:YES completion:nil];
    } else if(index.row==3) {
        UIAlertController *a=[UIAlertController alertControllerWithTitle:@"删除 Token？" message:@"删除将取消请求并清除彩云缓存，不影响布局方案。取消不作改动。" preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){self.fields[0].text=@"";[s deleteToken];}]];
        [self presentViewController:a animated:YES completion:nil];
    } else [s refreshManual:YES];
}
- (void)clearSensitiveInput { for(UITextField *field in self.fields)field.text=@""; }
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated];self.fields[0].text=@""; }
- (void)tableView:(UITableView *)table willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)index { WCCPanelStyleCell(cell); }
- (void)tableView:(UITableView *)table willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section { WCCPanelStyleSection(view); }
- (void)tableView:(UITableView *)table willDisplayFooterView:(UIView *)view forSection:(NSInteger)section { WCCPanelStyleSection(view); }
@end
