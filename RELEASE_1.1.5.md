# CCWeatherModule 1.1.5

- 仅3×1折叠布局重新紧凑化；其他规格保留114分支。
- 展开恢复1.0.4重建版原约束、85pt头部、180pt总高和小时预报，不添加问候行。
- 真实CC overlay宿主session观察，签名严格验证后安装，主线程单次安装、弱模块表、原IMP链保存、继承方法隔离。关闭后再打开换问候后半句并排除上一句，保留模块展开/收回换句；重复layout/天气更新不抽句。
- 保留114天气basename映射与原生静态/GIF/MP4图库、单指/双指手势、Filza及五尺寸设置。无注销按钮新改动、无维护脚本。

## 当前CI

Theos构建arm64+arm64e；runtime115.c生产状态/ABI/几何、test115.py自包含原104展开对照；host115.m直接import生产WCCHostObserver.m，在macOS Foundation真实runtime运行modern、legacy、inherited、getter-char、reject-bool、reject-return、reject-argc、reject-missing八个独立进程；mapping114.c、mapping114.m和test114_mapping.py保留映射回归。旧runtime114及test114_wiring的旧事件/布局断言不作为当前测试，历史文件保留。

## 限制

宿主runtime测试使用最小UIViewController mock，并非UIKit/iOS测试。iOS16模拟器及iPhone14 Pro Max iOS16.6真机均NOT RUN。私有ABI和宿主事件实际送达、其他插件共存、动画和媒体需目标设备验证。不支持签名时不安装hook，不伪称全CC换句可保证。begin交互取消可能已抽句，重试会再换。

安装包为rootless /var/jb，不是原生RootHide；不自动注销。运行结果、commit/run、下载digest/CRC、双架构包控制信息与私密恢复证据由独立交付目录记录，不以本文代替实际成功证据。
