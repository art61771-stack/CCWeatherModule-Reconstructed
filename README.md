# CCWeatherModule 1.2.2 / build122 — 安全降级候选

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
