# CCWeatherModule 1.1.4

## 布局与问候
- 2×1、3×1、4×1 折叠横条统一左右平衡布局，按实际 bounds 缩放字号和尺寸。左主温度及高低温、右独立图标及城市/天气；城市、天气、降水与问候共享右边界，左右外侧留白相等。2×1 紧凑折叠可省高低温/降水，展开保留；4×1 文本轨道随可用宽度延伸。2×2/3×3 及展开保留原几何。
- 设备本地六时段固定前缀、每段8句随机后句。controlCenterWillPresent 强制抽取并排除上句，即使没有 dismiss；同次 layout/天气刷新不换句。

## 按原天气资源绑定
设置 → 自定义图标 → 选择原天气图标 → 原生素材列表。分类名称来自恢复出的 imageNameForConditionCode 原资源 basename，不使用本地化天气描述猜测。48 condition code 模板及昼夜规则完全保留；如晴天-白天/晴天-夜间、小雨-白天/小雨-夜间。

每类绑定任意合法素材文件名，左滑仅清除该类绑定，总开关独立。无映射、文件失效、媒体不可显示、总开关关闭均回原天气图。旧版全局 icon 偏好不作为任何类的后备，不删除旧文件，须逐类重新绑定。天气类别/昼夜变更清理旧媒体；同类同文件 stat 身份不变则复用，不重复创建播放。异步 asset 与 KVO 使用 generation / object 守卫。

完全移除 HTML、WebKit、bridge、网页/原生 segment。仅原生列表及静态图/GIF/MP4 预览，可显示成功才保存绑定。文件路径重新验证。素材固定目录 `/var/mobile/Documents/CCWeatherModule/Icons`；保留 Filza/复制路径入口，不删用户素材。限8MB，图片8192px/3200万像素，GIF120帧；MP4 30秒/1920px，仅视频轨道静音循环。

## 操作与安装范围
单指双击附近/城市；双指同时双击紧凑设置。五尺寸2×1/3×1/4×1/2×2/3×3，更改后手动注销 SpringBoard 生效，不自动注销。默认4×1。无 preinst/postinst/prerm/postrm/config 等 maintainer 脚本。

本包为 **rootless /var/jb，arm64 + arm64e**，不是原生 RootHide。
**iOS16.6 真机、UIKit 的 CC 回调交付、GIF/MP4 真机播放及 RootHide 安装兼容性全部 NOT RUN。** CI macOS 构建/生产可移植测试不构成 iOS16.6 实测，不用 iOS18 结果替代。

## 回归证据
- runtime114.c：610种几何（全部三横条；方形/展开 byte-identical），20160次无dismiss重新present，100800次稳定事件。
- mapping114.c：104个真实 basename ケース，20000 generation/object 守卫组合。
- mapping114.m：CI macOS Foundation 链接真实 WCCPreferences，雨昼夜/雨转晴/缺失及旧配置/类型错误/逐类清除测试。
- test114_mapping.py：48模板与恢复原表一致，设置→Gallery target→偏好→Controller→媒体生产接线断言。
- test114_wiring.py：原生-only、问候生命周期、手势及rootless双架构静态检查。

发布目标仅 `fix/1.1.4-native-gallery-greeting-right-layout`，基于1.1.3 `3d8ba16bf359fefbfde63932b29d63847275b146`。main与历史refs不变。Git tree 显式删除网页与桥文件。最终 CI/run/jobs、摘要CRC及仓库隐私记录见独立交付目录证据；本说明本身不代表已经发布成功。
