# CCWeatherModule 1.1.0 — 自定义主图标与尺寸

双击模块打开设置；地标显示模式和名称编辑已迁入设置。保留天气与展开后的小时预报。

- 素材目录：`/var/mobile/Documents/CCWeatherModule/Icons`，首次进入设置创建；提供 Filza 入口。
- 支持 PNG/JPG、GIF 和 MP4。HTML 安全图库显示缩略图，点击选择后顶部原生播放并应用；可关闭自定义图标恢复天气图。
- 文件最大 8MB；图片最大 8192 边长/3200万像素，GIF 最多120帧，解码缩至256px；视频最大30秒/1920px。
- MP4 用仅视频轨道的 composition 静音循环，不调用 AVAudioSession；离屏暂停。不中断其他音频的实际设备验证仍待执行。
- 尺寸开关支持2×1、3×1、4×1，关闭恢复4×1。使用 CCSupport `moduleSizeForOrientation:(int)`，返回两个 NSUInteger 字段结构体，启动时快照；更改后需手动注销 SpringBoard。
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
