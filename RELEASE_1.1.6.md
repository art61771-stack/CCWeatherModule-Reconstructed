# 1.1.6

- 仅3×1天气组向右平衡；其他尺寸保持。展开保留原104头85、总180、六个原元素约束和小时frame，在实际layout后的空白中安放8pt问候。极端没有空白可不可见，不挪原元素。
- 每小时自己的conditionCode/严格B或c ABI isDaylight映射静态/GIF/MP4；模板需昼夜但无明确信息则原符号，不猜当前city昼夜。
- **所有当前可见小时均显示并播放各自匹配素材，无三路配额、无超额原图回退。** 静态/GIF/MP4均按小时匹配。FIFO串行准备，MP4元数据10秒超时防止后项饥饿；不是同时无限解码。离屏清理、滚回恢复、收起/退出停止小时动画；未映射/未知必要昼夜/真实素材失败保留原图。全部可见播放器的CPU/内存成本尚未经iOS16.6真机测试。事件更新路径与文件身份缓存，两阶段释放后准入；layout/scroll稳态不stat、不重复active重启。绑定边沿媒体保留安全校验，代际拒绝陈旧回调。
- 修复115首次注册无parent后无法bootstrap的代码风险，但它只是诊断候选，未确认为用户真机下拉故障根因。保留展开/收回换句。
- 双指双击模块设置→“下拉问候 · 本地诊断”→开启→退出设置→完整收起/下拉控制中心3次（不要展开模块）→返回诊断→“导出本地聚合并复制”。默认关闭，仅内存聚合类/方法ABI、安装拒绝、真实host/module/greeting调用计数，不逐事件文件IO。只有导出写 `/var/mobile/Documents/CCWeatherModule/host-diagnostics-116.json`；失败时明确提示且仍复制文本。无自动上传，不采集位置/问候正文。关闭后停止计数；计数属于当前SpringBoard进程会话。
- 主图、原生按天气分类图库、Filza、手势及五尺寸保留。control Icon严格使用用户指定URL。Sileo安装后注销按钮未实现；不添加伪字段、维护脚本、无用注入或自动注销。

## 验证

CI必须编译真实Theos bundle，并运行test116.py（生产几何/144昼夜/1000准入/其他尺寸不变/实际接线/Icon）、hourly116.c、runtime115.c、host115.m八独立Foundation模式、114映射C/Objective-C/源码接线回归。旧test115.py的禁止展开问候和小时源码不变断言不适用116，仅历史归档。

macOS Foundation mock不是UIKit执行。iOS16 simulator及iPhone 14 Pro Max/iOS16.6 RootHide均NOT RUN，不用iOS18替代。GIF连续计时、MP4播放/回收、真实字体和长城市名、展开过渡及真实宿主selector行为仍需目标设备验证。包是rootless /var/jb arm64+arm64e，不是原生RootHide。
