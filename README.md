# CCWeatherModule 1.2.10 — Sileo 官方完成动作协议

## 1.2.10
- 本版仅修复 Debian 打包协议、版本与测试；1.2.9 的生产代码、主图中心缩放和全部功能保持不变。
- `postinst` 遵循 Sileo 官方 `layout/DEBIAN/postinst.in` 语义：从 `SILEO` 读取动态控制文件描述符和协议版本，在版本 ≥ 1 时向该描述符写入唯一一行 `finish:restart`，请求 Sileo 在安装/升级完成页显示“注销/重启 SpringBoard”动作。
- 为避免 shell 重定向注入，文件描述符仅接受十进制正整数，协议版本仅接受十进制且必须 ≥ 1；缺失、空、版本 0、格式错误、恶意值或未打开描述符均静默退出 0。实现兼容 POSIX `sh`/ash，不使用 `eval`，不向 stdout 冒充协议。
- 不执行 `killall`、`sbreload`、`launchctl`、`ldrestart` 或自动注销，不删除/覆盖用户资料，不联网。CI 同时测试源码与解包后的实际 `postinst`，核验 root/wheel 0755、唯一 maintainer script、动态 fd3/fd4 捕获和异常输入静默行为。
- 截图中转换后 `Architecture: iphoneos-arm64e` 与按钮协议无关；按钮由 Sileo 注入的动态 fd 协议决定。真机 Sileo 完成页仍需复验。

# CCWeatherModule 1.2.9 — 主图原地缩放

唯一基线：1.2.8 commit `ed6aac6975b048015344b9d034be963e4ae3a222`。

## 1.2.9
- 根因：1.2.8 把 `additive=YES` 的 transform 缩放直接加在 `_iconView.layer`；而 `_iconView.transform` 同时承载用户大小与 X/Y 位移。Core Animation presentation 合成时会把既有 translation 一并参与缩放，故非零位移、非 100% 主图下呼吸端点发生中心漂移。
- 修复：`_iconView` 只保留用户最终位置、50–250%/展开50–150%大小及 shadow/glow；新增内部 `_iconContentView`，系统天气图放入 `_systemIconView`，PNG/GIF/MP4 `WCCMediaView` 也放入同一内容容器。缩放只在内部内容层使用非 additive `transform.scale`（0.94↔1.06），父层几何完全不动画，不改 anchorPoint。
- opacity 呼吸继续与内部 scale 并存；shadowOpacity 继续位于父 `_iconView.layer`，可与内容动画并存。停止、离开控制中心、打开设置、后台/不可见时仅移除各自 key，model transform 始终 identity，不累计。
- 保留主图滑块、X/Y、4×1 上下空间、shadow/glow；视频仍保持矩形 shadowPath 限制。
- 测试新增实际矩阵变换后的 bounds center 验证：50/100/200/250%、正负 X/Y、0.9/1.1 端点及100轮启停；同时先复现旧 translated-parent additive scale 漂移。历史 1.2.8–1.2.4 回归继续执行。
- 1.2.9 当时包含了错误的 stdout `finish:restart` 提示；该历史实现未使用 Sileo 注入的动态控制 fd，因此真机不显示按钮。1.2.10 已按官方协议修复。

## 真机状态
主图视觉中心、GIF/MP4、Sileo 完成按钮、iPhone 14 Pro Max iOS 16.6 RootHide 均 **NOT RUN / 待真机验证**；CI 的 C 矩阵、Apple QuartzCore/UIKit 桩和静态接线不冒充真机渲染。

---

# CCWeatherModule 1.2.8 — 问候可见文字锚点

修复基线为已确认失败的 1.2.7 commit `9a1ef30107e9e7682ef3201678fd7d7966398550`。

## 1.2.8
- 明确承认 1.2.7 未修好。真机截图 `photo_48B3ACDD.png`（长句左缘约 113）与 `photo_EBADDE2D.png`（短句左缘约 132）证明同一设置下可见左缘相差约 19px；城市天气未移动，故故障限于问候组。
- 1.2.7 只固定了 UILabel rail/translation；在 4×1、X=0 时仍继承布局默认右对齐。短句和长句即使 label frame 与 transform 完全相同，可见文字左缘仍会随文字宽度改变。旧桩只断言 translation 相同，且 X=0 不断言实际 visible edge，因此误判。
- 1.2.8 对所有折叠问候使用明确可见锚：规范化后的 X≤0（含 0、±0.49 这类取整为 0 的值）固定 rail 左缘；X>0 固定 rail 右缘。负/正饱和值仍分别到模块左/右边。Y 始终由固定 rail 求得，不依赖一行/两行文字高度。
- 折叠问候先恢复 transform、设置固定 rail，再设置最终字体、单行尾截断与明确对齐；关闭 `adjustsFontSizeToFitWidth`，避免每句按不同字体比例拟合而让肉眼锚点再漂。展开布局仍使用原来的独立 frame/左对齐，且不应用折叠偏好；收回后重新恢复折叠可见锚。
- 地区/天气/降水组保持 1.2.4 实际文字测量契约，不随本修复移动。
- 新增生产 helper、C 测试和 Apple Foundation/UIKit UILabel 桩：先复现 1.2.7 在 4×1/X=0 下短长句左缘不同，再覆盖 0、接近 0、负、正、100 次换句布局、拟合/截断宽度及一/两行高度夹具，并直接断言 actual visible left/right，而非仅断言 translation。

## 1.2.7（历史，已确认失败）
- 1.2.7 将问候组从实际 `textRect` 限幅改成固定 UILabel rail，解决了 transform 随测量宽高改变的问题，但错误地让 X=0 保留 4×1 默认右对齐，未固定实际可见文字左缘。
- 其测试未比较 X=0 时短句和长句的可见边缘，所以 CI 通过不代表真机视觉锚正确。

## 1.2.6
- 承认 1.2.5 只把详情投影接到了彩云分支，系统 Weather.framework 的 City 模型未投影风向、湿度和未来摘要，因此系统来源看不到新增详情。
- 新增 Foundation-only 的生产 helper，通过 `respondsToSelector`、`methodSignatureForSelector` 和精确 `objc_msgSend` 签名读取实际运行时对象；不使用 KVC，不链接私有 SDK，selector 缺失或签名变化时安全省略字段。
- 公开 RuntimeBrowser 头文件证据表明 City 的 `windDirection`、`windSpeed`、`humidity` 是原始 `float`，但没有证明 `windSpeed` 的单位；因此 1.2.6 仅显示有证据可归一化的方向与湿度，不盲猜 m/s 或 km/h，也不生成虚假的风级/速度文字。
- 湿度兼容运行时常见的 0…1 比率和明确的 0…100 百分数；风向接受 0…360，按气象来向映射八方位。
- 系统未来摘要只使用从当前时间起、间隔连续一小时且 conditionCode 可真实解析的 hourlyForecasts，最多24项；按实际有效条数显示“未来N小时”，遇到 gap、无日期、未知天气即停止，不从现有 conditionLabel 反推数据。
- 刷新回调重新绑定详情；折叠/展开与布局路径不清空投影；切换彩云/系统时先重置标签和来源缓存，避免显示上一来源残留。
- best-effort：不同 iOS 的私有 Weather 模型可能删除 selector 或改变签名，此时对应详情会被省略，主天气、小时卡片及彩云功能继续工作。

## 1.2.5/1.2.4 保留功能与限制

## 1.2.4 当前功能与限制
- 地区/天气/降水组按水平请求位移负左正右，0恢复布局默认；测量实际文字后限幅。
- 彩云选择1/12/24小时，旧未选择配置仍15分钟。真实provider缓存TTL、过期判断、成功时间单次NSTimer截止调度；仅可见前台运行，后台/锁屏取消，返回时补检查，**不保证后台定时联网**。手动刷新仍受60秒和失败退避限制。
- 折叠4x1主图缩放后垂直居中再位移；320×76、100%基准y从8变22（下移14pt），200–250%边长60、中性上下各8pt；到边限幅，不增加越界行程。其他布局/展开保持旧算法。
- 三组文字及独立第四组主图：阴影/发光、原生RGBA拾色器、明暗呼吸、独立速度和浓淡。周期左6/中3/右1.5秒；浓淡左0/中0.6/右1，呼吸上下限严格增强，透明色alpha=0除外。新中点比旧123阴影0.9/发光1略淡，不改变内容自身alpha。只动画shadowOpacity，各自key清理，不清除其他动画。
- v4方案含四组颜色/呼吸/速度/浓淡/主图开关，兼容v1–v3，保存隔离、读前备份及失败回滚。
- 设置owner-local会话，CC退出/后台/锁屏结束一次，仅dismiss属于本owner的root；拒绝晚回调复活，不混挂child/window。真实UIKit各转场仍待实机验收。
- 主图PNG/GIF和系统图片走合成alpha阴影；**MP4只支持容器矩形光晕，不是视频主体轮廓**。系统祖先裁剪、GIF动态轮廓、AVPlayerLayer及拾色器布局未真机验证。

## 当前测试门槛
Actions执行test124、run124-foundation.sh（真实配置持久化、生产路由提取、真实QuartzCore CALayer opacity/动画key与清理、生产source/provider离线注入clock/transport的15min/1/12/24h与单次NSTimer调度）。UIKit类用桩不等于UIKit渲染。保留旧配置路径隔离/回滚、源安全、布局、host八模式及小时回归；旧provider逐字相等改为仅TTL允许变化、source交易/epoch精确契约，不跳过安全检查。
未执行：UIKit实机/模拟器、真Keychain、live API、24小时联网耐久、RootHide实机。不得将Foundation或C测试称为真机通过。

## 以下为122历史背景（不是当前版本契约）

不是“已验证修好”：没有 crash 日志，121 双指安全模式异常栈未定位；用户彩云120单指成功、121失败的差异仍未定位。不要重复触发崩溃，不要求切换系统来源、不重填Token或改坐标。

## 本次修改
- 撤回121浮动控制器/窗口containment路径；删除WCCPanelMenu、overlay、拖动及旧浮动透明通知/构造代码。WCCFloatingPanel仅保留样式函数和兼容API，openFor转向原生设置，不再无声no-op。
- 恢复UIAlert菜单、固定位置自有导航容器（UIModalPresentationCustom + UIPresentationController）。四个子页入口共用WCCShow：主线程、window、presented/presenting/dismissing/transition检查；拒绝呈现调用完成恢复媒体，UIKit同步未接受呈现亦恢复。
- 双指入口拒绝重复tap和转场，打开暂停媒体、终结恢复。完成回调once；子页done先取出并清空回调再dismiss，防重复done。固定面板无外点自动关闭，完成/取消回菜单；天气输入清空不删Keychain。图库内部push/back保留，根页不混用pop。
- 保留折叠50–250%分段滑条、展开独立50–150%、文字阴影、七元素/小时首屏、布局与方案。
- Provider/Source/Configurations及单指action/手势仲裁与公开120源码夹具逐字节比较。未改Token、Keychain、坐标、素材或alias。

## 临时功能损失
彻底取消拖动及位置应用；保留透明按钮：实际调参页固定底栏开关兼容settingsPanelTransparent偏好。正规UIKit custom presentation由UIKit维护controller/view关系，不向UIWindow混挂child；背景/导航/表格cell透明而控件保持不透明，关闭恢复原背景。标准UIAlert菜单不透明，UI明确透明只作用实际调参页。底层模块视图保留可见；设置期间媒体暂停，不强制后台播放。不是121浮动面板回归。

## 单指调查界限
限时检查120→121控制器diff：未新增首次打开前hitTest/userInteractionEnabled/nav overlay路径。overlay仅旧浮动面板创建后存在且现已删除。taps/touches/requireFailure与handleDoubleTap原样，不认定为根因。updateCityLabel彩云snapshot分支在120已存在，不能将旧分支归为新根因；是否动作已成功后视觉覆盖未有运行时证据。不伪造地区名、不增加定位/地理编码或网络。

## 测试与证据
CI需真实Apple SDK编译arm64+arm64e生产包；test122_safety.py自包含公开120源码夹具，静态校验生产接线并提取WCCShow/WCCOnce/双指handler/子页done。route122 Foundation替身执行拒绝呈现复原、成功/关闭/重复tap、转场拒绝、重复done、selector存在。这不是UIKit运行，不能证明真实present/containment/手势安全。
保留source120离线Keychain/transport mock、host八模式、configurations121的250%、shadow121和hourly118首屏。test120_settings.py旧统一slider字面断言作为历史保留，不冒充当前测试；test121_settings.py校验现行分段滑条；source静态版本检查更新122。

NOT RUN：iOS16 UIKit runtime/手势/导航真实转场/销毁、SpringBoard安全模式实机复验、真Keychain、彩云live API、iPhone14 Pro Max iOS16.6 RootHide。无iOS16 runtime不以iOS18替代。

## 包装
control-only rootless，双arm64/arm64e；非原生RootHide，不承诺直接适配。没有维护脚本、诊断恢复、Sileo检索。Icon保持原17d095 HTTPS；Installed-Size由打包工具生成。
公开源码不含用户私密日志/附件；没有收到真实crash日志。历史说明存README-121-HISTORICAL.md，仅供历史。
