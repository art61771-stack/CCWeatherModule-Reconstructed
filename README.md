# CCWeatherModule 1.1.7 — 实测宽平衡布局与小时原图同名绑定

仅3×1折叠内容按最终UIFont真实测宽调整整体对称留白；图标按城市至降水信息区垂直居中，问候独立。其他尺寸、展开原约束、主图、原生图库及手势保持。

每hour保留自身conditionCode和原resolver；在原imageNamed位置回传basename并直接绑定该资源名自定义素材。移除116额外forecast.isDaylight准入阻断。原resolver歧义昼夜依旧采用city.isDay：仅保证与内置小时图标同名，不宣称未来小时昼夜精度提升。

全部可见小时素材准入、离屏暂停/滚回恢复、缓存身份、异步代际、问候事件保持。用户本轮未反馈下拉换句结果，不判定已修好或继续失败。默认关闭本地诊断导出更新为 `/var/mobile/Documents/CCWeatherModule/host-diagnostics-117.json`，含小时映射聚合计数，不导出素材路径/位置。

CI从真实ObjC resolver/createHourlyItem/refreshHourlyMedia及ConditionTables抽取编译macOS Foundation测试；布局调用生产C几何，SVG使用显式测宽fixture，不是UIKit真机截图。保留runtime115、host115八种observer模式、114映射回归及116有效媒体/事件/展开断言；旧116证据归档，不执行已撤掉的严格isDaylight断言。hourly116仅作为旧纯函数映射回归，不代表117接线。

rootless /var/jb，arm64+arm64e，control-only；非原生RootHide。iOS16模拟器和iPhone14 Pro Max iOS16.6 RootHide均NOT RUN，不以iOS18替代。不改Sileo检索/注销，无维护脚本。实际构建结果及SHA以独立交付证据为准。

## 以下1.1.6及更早内容仅历史记录，不代表当前实现

# CCWeatherModule 1.1.6 — 小时素材、空白问候与宿主诊断

当前说明见 RELEASE_1.1.6.md。仅3×1天气组向右平衡；展开保留原104头高85/总高180及小时位置，在实际元素frame空白中放8pt问候；极端无空白时可能不可见。

**全部当前可见小时均显示并播放各自匹配的GIF/MP4或静态素材，不设三路播放配额、不因数量回退。** 素材准备使用FIFO串行队列（MP4元数据10秒超时防止阻塞后项），逐步让全部可见项播放；离屏清理、滚回恢复，收起/退出停止小时动画。未映射、昼夜不明确或单素材安全检查/解码失败才保留原图。全可见播放的性能成本尚未经iOS16.6真机验证。 每小时独立conditionCode和严格ABI isDaylight映射；缺明确昼夜且模板需要昼夜时回退原符号，不猜昼夜。两阶段装卸、事件路径/文件身份缓存、媒体代际保护；layout/scroll稳态不stat、不重复重启active。

默认关闭的“下拉问候 · 本地诊断”记录类/方法ABI、安装拒绝及host/module/greeting计数，只在导出时写 `/var/mobile/Documents/CCWeatherModule/host-diagnostics-116.json` 并复制。开启后退出设置，完整收起/下拉控制中心3次（不展开模块），再导出。115迟挂parent bootstrap风险已修，但不宣称是真机故障根因或已修复用户下拉问题；展开/收回换句保留。

CI运行test116/hourly116/runtime115、host115八种Foundation模式及114映射回归。macOS mock不是UIKit；iOS16模拟器和iOS16.6真机均NOT RUN。保留主图、原生分类图库、手势、Filza和五尺寸。rootless arm64+arm64e，非原生RootHide。Sileo安装后注销按钮未实现，无维护脚本、伪control字段或自动注销。

## 以下1.1.5及更早内容仅历史记录，不代表当前实现

# CCWeatherModule 1.1.5 — 3×1紧凑布局与宿主会话问候

当前说明见 RELEASE_1.1.5.md。仅重新紧凑化3×1折叠布局，展开恢复1.0.4重建版约束和小时预报，无新增问候行。CC宿主会话监听采用严格ABI、主线程、弱引用、原IMP链及继承隔离；保留展开/收回换句。天气映射与原生图库不变。

当前CI执行 runtime115.c、test115.py、host115.m八独立模式、114映射C/ObjC/接线回归；runtime114与test114_wiring等旧布局/事件断言仅归档，不冒充当前通过。macOS Foundation runtime测试不等于UIKit或iOS16实机。rootless /var/jb，arm64+arm64e，非原生RootHide；iOS16.6真机 NOT RUN。

## 以下1.1.4及更早内容仅历史记录，不代表当前实现

# CCWeatherModule 1.1.4 — 原生按天气分类素材与全部横条布局

当前实现与测试边界见 **RELEASE_1.1.4.md**。原生列表取代所有网页实现；按原天气 basename 逐类绑定，旧全局 icon 不再适用。三种横条均采用新布局。rootless arm64+arm64e，非原生 RootHide；iOS16.6 真机 NOT RUN。

## 以下1.1.3及更早内容仅历史记录，不代表当前实现

# CCWeatherModule 1.1.3 — 轻量动态图库、原生备用入口与天气网格

当前版本说明见 `RELEASE_1.1.3.md`。旧版全量 base64 图库已替换为轻量 HTML + 可见最多两项异步媒体；网页进程失败自动进入原生列表，仅允许一次人工网页重试。生产可执行回归：`cc evidence/runtime113.c -lm -o /tmp/runtime113 && /tmp/runtime113`、`node evidence/gallery113.js`。这些不是 UIKit/CC 真机测试，目标 iOS16.6 实测仍 NOT RUN。

## 以下为1.1.2历史说明（不代表当前实现）

# CCWeatherModule 1.1.2 — 图库诊断、动态预览、问候语与自适应布局

单指双击模块切换附近/城市；双指同时双击打开紧凑居中系统弹窗设置。设置按图标、尺寸、地标分层，保留全部功能；HTML 图库使用有完成按钮的居中 popover，不强制全屏。保留天气与展开后的小时预报。

1.1.2 回归：`python3 evidence/test_112.py`（生产 C 几何/问候/文件校验和 Objective-C 接线断言）。CI 和下载校验结果以独立交付目录的 run/jobs、artifact-verification、local-verification 和 github-state 证据为准；源码说明不构成真机验收。

- 图库固定读取真实 Icons 路径，显示枚举错误、规范路径与逐文件过滤原因；预览预算耗尽不终止条目枚举。
- HTML 内嵌原始 GIF bytes（image/gif）和 MP4 bytes（video/mp4），配置 inline/autoplay/muted/loop 与 media-src data；不是将 PNG 缩略图冒充动画。8MB 总预览预算之外显示“点击顶部预览”，点击后由原生媒体视图解码播放。iOS WebKit 实际自动播放行为尚需真机确认。
- 按设备本地时区分六时段随机中文问候语；同次 CC 会话不重复抽取，相邻会话避免同一句。
- 五尺寸按实际 bounds 同步布局媒体与文字；3×1、4×1、方形及展开布局保留高低温和降水，2×1 紧凑折叠布局省略这两行，展开可见；没有全局删除天气字段。问候语采用次级字体。
- 源码来自 1.1.1 父提交，发布仅写入独立 1.1.2 分支；main 和历史分支保持不变。

- 素材目录：`/var/mobile/Documents/CCWeatherModule/Icons`，首次进入设置创建；提供 Filza 入口。
- 支持 PNG/JPG、GIF 和 MP4。HTML 安全图库显示缩略图，点击选择后顶部原生播放并应用；可关闭自定义图标恢复天气图。
- 文件最大 8MB；图片最大 8192 边长/3200万像素，GIF 最多120帧，解码缩至256px；视频最大30秒/1920px。
- MP4 用仅视频轨道的 composition 静音循环，不调用 AVAudioSession；离屏暂停。不中断其他音频的实际设备验证仍待执行。
- 尺寸开关支持2×1、3×1、4×1、2×2、3×3（列宽×行高），默认关闭，关闭恢复4×1。`moduleSize` 存储白名单字符串，旧版 `columns` 偏好映射为单行。CCSupport `moduleSizeForOrientation:(int)` 实际返回两个 NSUInteger 字段，宽高同时在首次查询快照；更改后手动注销 SpringBoard 重建模块及控制中心布局缓存，不自动注销、不删除系统偏好。
- Filza 入口先创建目录，使用严格路径 URL 编码，优先 SpringBoard `openURL:withCompletionHandler:`，无私有接口时用公开打开 API。创建失败、打开失败/回调超时均提供可见错误和复制路径入口（需控制中心仍可呈现界面）。
- 构建为 **rootless `/var/jb`、arm64 + arm64e**，不是原生 RootHide 包。iPhone 14 Pro Max / iOS16.6 RootHide 安装兼容性尚未验证，不应直接宣称兼容。
- 不含 preinst/postinst/prerm/postrm/config 维护脚本。不自动注销。
- iOS16 模拟器和目标真机测试：**NOT RUN**；不以 iOS18 模拟器冒充。
- macOS Theos CI：`.github/workflows/build.yml`，构建日志和产物验证单独归档；以下是旧版重建历史，旧版“未编译”描述仅针对1.0.4备份。

## 1.0.4 重建历史

# CCWeatherModule 1.0.4 — 源码重建备份

根据用户提供的 `com.simon.ccweathermodule` 1.0.4 Debian 安装包静态逆向重建。不是遗失原始源码的逐字恢复，也不保证与原二进制完全等价。

## 内容
- `src/`：模块入口、天气控制器、私有接口及天气条件映射。
- `Resources/`：原样提取的29张PNG及Info.plist。
- `Makefile`、`control`：重建Theos工程及原始包元信息。
- `original/package.deb`：原始安装包备份。
- `package/`：原包提取内容，仅用于分析对照。
- `evidence/`：反汇编、方法映射、恢复脚本及静态验证。
- `RECOVERY_REPORT.md`：逐方法覆盖、证据与局限。

恢复功能包括系统天气模型接入、定位与逆地理编码、天气/温度/降水显示、最多12小时预报、展开布局、双击切换地点名称及双指双击编辑名称。

## 验证边界
静态验证覆盖46条方法元数据；显式实现36种selector，其余为属性访问器/ARC析构。方法名覆盖不是行为等价证明。144项天气映射已核对，30个资源文件与原包字节一致。

**尚未Apple SDK编译、链接或真机测试，未生成重建版deb。** 私有接口、不同系统兼容性及界面效果仍需验证。原始注释、局部变量名和构建历史无法从deb完整恢复。

运行静态验证：`python3 evidence/validate.py`。
构建需要另行配置Theos及合适的iPhoneOS SDK/私有框架；本次仅保存恢复工程，没有触发CI。
