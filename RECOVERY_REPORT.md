# CCWeatherModule 源码恢复报告

## 恢复性质

这是基于用户原包的可读 Objective-C 重建，不是原始源文件、逐字反编译结果或已经验证可安装的二进制。没有用空方法代替业务逻辑，也没有把原包二进制放入新源码构建流程。唯一显式空业务回调 `todayModelWantsUpdate:` 在原 arm64 地址 0x7888 本来就是直接返回。

原包：com.simon.ccweathermodule 1.0.4，rootless，最低 firmware 14.0。原 Info.plist 的 Bundle ID 实际为 com.yourname.ccweathermodule，显示名为“cc天气模块”，版本字段为 1.0.0/1；这些与 Debian 包字段不一致，恢复时没有擅自改名。

## 已产出

- `src/PrivateInterfaces.h`：实际用到的控制中心协议、天气模型 observer 协议及私有 selectors 最小声明。
- `src/WCCModule.h`、`src/WCCModule.m`：入口类、初始化检测和 contentViewController。
- `src/WCCContentViewController.h`、`src/WCCContentViewController.m`：模型初始化、观察、刷新、布局、地标交互、逆地理编码、天气与温度/降水/逐小时视图。
- `src/ConditionTables.m`：三个 48 项映射表，分别为本地中文天气、SF Symbols、原始 PNG 名称。采用分类拆分，属于重建组织形式。
- `Makefile`：Theos bundle 构建，arm64/arm64e、ARC、rootless 安装路径和私有框架依赖。
- `control`：原包 Debian control 字节复制。
- `Resources/`：29 张 PNG 与原 Info.plist，共 30 文件，全部逐字节复制；未重绘、转码或修改 plist。
- `evidence/decode.py`、`tables.py`、`materialize.py`、`validate.py`：恢复和验证脚本。
- `evidence/decoded.txt`、`annotated-arm64.txt`、`method-map.json`、`semantic.txt`、`tables.json`、`resources.sha256`、`validation.txt`：中间证据与静态检查结果。

## 方法与证据

已有 objc.txt 的 class refs 显示为 encoded pointer，不能直接当作完整 class-dump。新增脚本读取 fat Mach-O 的 arm64 slice、LC_SEGMENT_64 节地址、低位 chained pointer target、紧凑相对 method list、selector refs 和 CFString；识别 8 字节方法列表对齐，并区分重复命名的 __const 节。其解码仅针对该输入格式，不是通用 Mach-O 工具。

从 __objc_stubs 的 selector 装载恢复调用名称，为现有 arm64 反汇编增加 SEND 注释；结合分支、寄存器值、常量及 block 入口重写 Objective-C。中文天气表通过 0x6818 起的字典栈构造提取；图片映射通过 0x9008 的 48 字节跳转表及 0x6f7c 分支基址恢复；SF Symbol 名称直接读取 0xc1f8 指针表。不是凭天气常识补出的映射。

原包有 arm64 与 arm64e 两架构。源码语义主要依 arm64 分析，arm64e 的开头初始化路径及对应调用用于结构交叉核对；没有对其全部 8103 行进行逐条双架构等价证明。

## 方法覆盖（地址均为原 arm64）

| 类/方法组 | 原地址 | 恢复情况 |
|---|---|---|
| WCCModule init/contentViewController/析构 | 0x4000/0x40a0/0x40a8 | 初始化失败返回 nil；getter 和析构由 ARC 自动生成 |
| controller init / initializeWeatherModel / dealloc | 0x40b4/0x4148/0x4380 | WALockscreenWidgetViewController 生命周期、todayModel、observer、位置服务和首次更新；释放移除 observer |
| 展开协议与活跃回调 | 0x43e4–0x4454 | 返回 YES；展开高度180；展开刷新小时视图并切换 alpha；两个活跃回调刷新 |
| viewDidLoad / forceCityUpdate / viewWillLayoutSubviews | 0x4458/0x45ac/0x4698 | 初始加载、1秒和3秒延迟刷新、city自动更新；头部固定85高，小时容器占余高 |
| setupHeaderView / setupHourlyContainer | 0x4798/0x5230 | 恢复14条头部约束、8条小时约束、图标55、温度字体38、分隔线0.5、手势 |
| 双击/双指双击/自定义弹窗 | 0x56f0/0x577c/0x5780 | 三种地名模式循环；无自定义名称跳过第三种；去空白后非空才保存；无磁盘持久化 |
| updateWeatherDisplay | 0x5afc | 从 weatherModel.forecastModel.city 刷新；无数据占位、条件/温度/高低/降水/图标更新 |
| updateCityLabel及blocks | 0x5d54–0x6218 | 经纬度四位小数缓存key；subLocality→subAdministrativeArea；主线程更新，仅模式0显示地标 |
| updatePrecipitation | 0x621c | 首小时与首日降水概率取较大者；0<值<1时乘100；恰好1仍为1%，保留原边界 |
| temperatureString / highLowTemperatureString | 0x644c/0x6598 | celsius/doubleValue/字符串转换；四舍五入零位；高低分开兜底 |
| conditionString/localizedCondition | 0x6748/0x67ec | 动态 WAConditionsLineStringFromConditionCode 优先，中文48项表兜底，未知 -- |
| updateWeatherIcon / systemWeatherImage | 0x6c58/0x6dd8 | 模块资源优先、WeatherUI资源其次、SF Symbol兜底；无温度默认云 |
| imageName / systemSymbol / sfSymbol | 0x6f08/0x709c/0x7140 | 昼夜PNG选择、WASymbolGlyphFromConditionCode动态查找、48项符号表 |
| updateHourlyForecast / createHourlyItem | 0x7164/0x73bc | 清除旧子视图；最多12项、55×80、两端12；现在/time/date优先级；ah时格式；图标与温度 |
| 四个 observer 回调 | 0x7888/0x788c/0x7924/0x7984 | 第一项原本无操作；其余调度主线程刷新；没有虚构使用 forecast 参数 |
| refreshWeatherData | 0x79e4 | 重激活定位、kickstart/reload、executeModelUpdateWithCompletion或直接更新 |
| weatherModel/forecast/isInitialized 六个访问器及ARC析构 | 0x7b6c–0x7d3c | 属性自动综合及ARC释放；forecast保留但不编造赋值路径 |

共识别 46 条方法元数据记录（两个类含同名 init/.cxx_destruct）。源码有36种显式 selector，其余原访问器与析构由属性/ARC生成；验证脚本按 selector 名称集合检查，无缺失。这不是证明46条机器实现已逐指令等价，也不是运行时覆盖率。

## 已验证

执行 `python3 evidence/materialize.py` 和 `python3 evidence/validate.py`：

- 原方法 selector 集合没有未覆盖项。
- 30个资源文件与原包逐字节相同。
- 三张映射表共144项均已提取；所有生成的昼/夜PNG名称有对应资源。
- 原图、原plist和control未用新生成配置替换。

可在目录中运行 `sha256sum -c evidence/resources.sha256` 复核资源。生成器会重写 ConditionTables.m 和复制资源；修改该文件映射时应同步修改生成器/提取数据，避免之后被覆盖。

## 准确局限与待验证逻辑

1. 环境 `THEOS` 未设置；虽有 clang，但没有进行 Apple SDK 编译、链接、签名、打包或设备加载测试。不能宣称源码已经编译通过、deb已经生成或插件已经可用。主助手后续需在带 iPhoneOS SDK 和私有 framework stubs 的 Theos 环境执行 `make package` 并处理实际诊断。
2. 私有 Weather/WeatherUI API 声明来自调用点；模型具体类名、系统内部实现、授权要求及不同 iOS 版本 ABI 无法仅凭此 bundle 确认。completion block 写为无参，原 block 忽略参数；若系统接口不同，需真机核对。
3. 原包用 performSelector:withObject:@YES 设置三个开关，本重建保留此非类型安全行为，而非擅自改成 BOOL 调用。若系统实际签名是 BOOL，需要在兼容性修订中明确改动并测试。
4. 单个方法的分支、异常兜底和 UI 几何已尽量恢复，但未验证所有嵌套异常清理的完全等价；部分异常域以更可读的 @try/@catch 重写。UIKit字体权重、动态字体表现、自动布局冲突、不同屏幕下的截断需截图对照。
5. 原编译优化后的持有/释放、block capture布局、ivar顺序与链接顺序不保证一致。表从原局部NSDictionary/跳转表改为NSArray和分类，行为目标相同，二进制布局不同。Makefile显式抑制由分类拆分导致的 incomplete-implementation/protocol-method-implementation警告，不应据此忽视其他编译错误。
6. 逆地理编码保留原设计：没有请求取消或过期位置响应防护，缓存只存内存，模式0且请求完成即更新地名；坐标任意一项为0时不请求。没有新增网络天气服务、定位授权弹窗或用户默认设置，以免伪造原逻辑。
7. 原资源有部分图片并未被48项映射使用；仍全部保留。arm64e 尚未完整逐方法独立审计，需后续工具链和设备验证。
8. 现有证据足够恢复模块外部可见业务；无法恢复原注释、开发者排版、原始项目配置、所有私有头文件和构建环境版本。未添加授权、上传GitHub或CI。

## 后续验收清单

- Theos rootless 两架构实际编译、链接及最终bundle Info.plist/安装路径检查。
- 在原系统版本确认WALockscreenWidgetViewController存在、observer注册和回调可用。
- 控制中心4×1布局、展开180高、前12小时水平滚动。
- 无天气数据/无定位权限/未知天气代码/缺失私有符号场景。
- 双击地标与城市切换、双指双击名称保存、空白确认不修改；重启后不持久化。
- 降水0、0.5、1、50的边界、摄氏温度、高低温、昼夜PNG与系统符号回退。
