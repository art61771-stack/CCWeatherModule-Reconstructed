# 1.1.3 修复与验证边界

## 进程退出调查
用户截图对应1.1.2的 `webViewWebContentProcessDidTerminate`，说明WebContent进程停止，不代表目录无权限或已确认OOM。截图遮盖天气模块，无法据此评价旧天气完整布局。

1.1.2在SpringBoard的ControlCenter bundle内创建WKWebView；Makefile无定制签名entitlements，已交付bundle的entitlements输出为空。Bundle签名不等于SpringBoard宿主/其WebContent子进程的真实权限，增加bundle entitlement不能自动赋权宿主。尚无SpringBoard/WebContent crash、jetsam或sandbox denial日志，未读取真实宿主签名，无法区分运行权限、JIT策略、沙盒、WebKit进程启动配置或解码压力。

对照只读的CCDynamicExperimental 0.1.9：图库在PreferenceBundle控制器中，使用nonPersistentDataStore、独立HTML模板、WKURLSchemeHandler映射文件，页面按需调度。天气原版同样是nonPersistentDataStore，因此不能把非持久data store说成已证实差异根因。两者宿主不同，Settings中的成功不证明SpringBoard里可启动；参考实现没有通过随意注入JIT权限解决问题。

确定的实现差异是天气1.1.2枚举时生成全部GIF/MP4 base64并塞入一个HTML字符串，压缩8MB总预算不能约束解码帧与并发播放器内存，还有base64与字符串复制开销。这是可修复风险而非已确认唯一根因。

## 实际更改
- `Resources/Gallery.html`初始壳约3KB，无素材base64。目录在后台串行读取，加载壳后注入仅文件名/ID元数据。
- 真实生产JS只加载当前可见的最多两项媒体；滚离/切换原生/隐藏时卸载src，暂停视频。失败卡片显示原生预览入口。
- `WCCGalleryBridge`串行异步读取，最多两个未完成请求，取消和失效任务不回调，数值ID映射经过既有路径校验的文件；不向WebKit授予file目录访问权。静态图片缩略图，GIF原始字节和MP4真实媒体保留。
- 网页GIF预算额外限制1024px、120帧和总帧RGBA估算16MB；超额仍可在原生逐帧预览/选择，不删除文件。MP4检查可播放、轨道、30秒/1920px，文件仍受8MB约束。
- 同一图库始终有“原生列表”分段入口；网页进程失败立即切换UITableView，准确说明原因未定，不再用素材目录失败弹窗混淆；一次人工确认重建网页，绝不自动reload循环。刷新只重新扫描同一Icons目录。
- 原生条目经WCCMediaView成功解码/显示后才提交偏好，失败保留原选择。文件名用JSON及textContent，不插入HTML。
- 问候语生产状态机与UILabel绑定分离：会话提前开始也会重新绑定标签，默认非空；公开UIKit loadView/didMoveToWindow/viewDidAppear/viewDidDisappear与布局可见兜底，并保留CC回调。按NSCalendar本地时区选时段，同会话稳定、下次避开上句，呈现设置时不主动结束会话。
- 重排温度主视觉、地名天气列、完整详情行与独立底部问候区域。五种尺寸和展开使用同一生产bounds计算，媒体容器同步bounds、aspect-fit。2x1详情展开保留，其余保留高低温与降水。

## 保留
单指双击附近/城市、双指双击紧凑分层设置、Filza入口、同一 `/var/mobile/Documents/CCWeatherModule/Icons` 路径、五尺寸注销后生效、天气条件图回退、小时预报。无用户文件删除、无自动注销，无新增Deb维护脚本。rootless `/var/jb` arm64+arm64e，不是原生RootHide包。

## 已执行与未执行
本地实际编译执行生产C几何与会话状态：11组尺寸边界/不相交/字体层级、2400次会话、24000次会话内稳定事件通过。开发中发现并修正方形温度与图标、说明行重叠。真实Gallery.html脚本在Node DOM harness执行：初始空壳、两项上限、滚离卸载、暂停恢复、失败跳过、文件名文字安全通过。

这些不是Objective-C/UIKit生命周期或WebKit子进程测试。本地设备信息返回iOS16.6，但iSH未配置Apple SDK/可安装运行的UIKit测试入口，不能将宿主iOS版本当成模块测试。iOS16模拟器：NOT RUN；iPhone14ProMax/iOS16.6 SpringBoard模块、MP4自定义scheme实际播放/Range兼容、网页进程恢复、设置返回以及五尺寸真机视觉：NOT RUN。没有用iOS18代测。

工程外 `layout-preview.html` 直接读取生产C矩形生成，可审查布局但明确非真机。CI编译、产物digest/CRC和仓库隐私状态由独立交付证据记录，不以本文件预先声称成功。
