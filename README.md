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
