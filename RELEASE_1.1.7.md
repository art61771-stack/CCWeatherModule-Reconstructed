# CCWeatherModule 1.1.7 — 实测宽平衡布局与小时原图同名绑定

仅3×1折叠内容按最终UIFont真实测宽调整整体对称留白；图标按城市至降水信息区垂直居中，问候独立。其他尺寸、展开原约束、主图、原生图库及手势保持。

每hour保留自身conditionCode和原resolver；在原imageNamed位置回传basename并直接绑定该资源名自定义素材。移除116额外forecast.isDaylight准入阻断。原resolver歧义昼夜依旧采用city.isDay：仅保证与内置小时图标同名，不宣称未来小时昼夜精度提升。

全部可见小时素材准入、离屏暂停/滚回恢复、缓存身份、异步代际、问候事件保持。用户本轮未反馈下拉换句结果，不判定已修好或继续失败。默认关闭本地诊断导出更新为 `/var/mobile/Documents/CCWeatherModule/host-diagnostics-117.json`，含小时映射聚合计数，不导出素材路径/位置。

CI从真实ObjC resolver/createHourlyItem/refreshHourlyMedia及ConditionTables抽取编译macOS Foundation测试；布局调用生产C几何，SVG使用显式测宽fixture，不是UIKit真机截图。保留runtime115、host115八种observer模式、114映射回归及116有效媒体/事件/展开断言；旧116证据归档，不执行已撤掉的严格isDaylight断言。hourly116仅作为旧纯函数映射回归，不代表117接线。

rootless /var/jb，arm64+arm64e，control-only；非原生RootHide。iOS16模拟器和iPhone14 Pro Max iOS16.6 RootHide均NOT RUN，不以iOS18替代。不改Sileo检索/注销，无维护脚本。实际构建结果及SHA以独立交付证据为准。
