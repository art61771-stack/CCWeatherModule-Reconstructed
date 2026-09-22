# CCWeatherModule 1.1.8 — 首屏小时素材、主图缩放与原图分类

3×1温度/高低温/问候同左基线，两组适度向外、对称小边距；图标按地区信息组垂直居中。其他尺寸与展开原约束保持。

小时滚动视图 layoutSubviews/didMoveToWindow 主动刷新；一次主队列代际校验和转场完成校验处理首次展开，零bounds/无window不准入，最终布局所有可见项（含7项以上）无需滚动准入。身份复用、离屏释放、异步媒体代际保护保留，无三路限额，不改解码策略。

原生 UIViewController 主图大小滑块50–150%，默认/中点100%，步长5；保存通过专用通知只调整主自定义媒体，不重载小时媒体，小时frame保持30pt。安全限幅避免侵占文字/边缘，实际最大尺寸可能达不到150%。

分类列表使用23类别原bundle PNG与名称、绑定详情；不以用户自定义图片误导。彻底移除诊断UI、计数与导出，保留问候宿主事件/ABI/原IMP/weak/session；不删除旧Documents诊断文件。

CI执行118生产方法提取ObjC测试、八模式host118（非UIKit）、layout118、test118_ui、114映射及有效116/117媒体回归。117证据归档不覆盖。所有预览仅示例，不上传附件或个人截图。

rootless /var/jb、arm64+arm64e、control-only，无maintenance脚本；不处理Sileo检索/注销。iOS16模拟器及iOS16.6真机均 NOT RUN，不以iOS18冒充；macOS Foundation/stubs不等于UIKit运行。

