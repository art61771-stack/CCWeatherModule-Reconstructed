# 独立彩云 v2.6 Provider（工程外组件）

## 文件与构建

`CYCaiyunProvider.h/.m`：ARC Objective-C，Foundation + Security，无 UIKit/Weather 私有框架依赖。最低集成目标 iOS 16.6；仅声明目标，未在 iOS 16.6 编译或运行验证。`Tests.m`、`fixtures/synthetic.json`、`test-macos.sh` 为完全离线测试。没有改动 CCWeatherModule-Reconstructed，没有上传、CI、真实 Token 或天气请求。

官方依据：先读同级 `../weather120-caiyun-api-notes.md`；主要文档 https://docs.caiyunapp.com/weather-api/v2/v2.6/6-weather.html 、`3-hourly.html`、`4-daily.html`、`tables/skycon.html`、`tables/errors.html`。代码按该报告的 v2.6 schema，不是 v3 bearer API。

在 macOS 上执行：

```sh
cd weather120-caiyun-component
sh test-macos.sh
```

脚本先独立编译无测试宏的生产 .m，再用 `-DCY_TESTING=1` 编译相同实现与真实 Foundation 测试入口；临时二进制退出即删。测试仅注入 mock transport/clock/keychain，不调用真实服务或 Security 存储。Linux 返回 77 + NOT RUN，不冒充通过。生产 target 不定义 CY_TESTING，只链接两份组件源码及 Foundation/Security。

## 集成 API（主线程调用）

持有一个 `CYCaiyunProvider` 实例，与模块生命周期一致。所有回调异步回主线程，JSON 解析在串行队列；UI 不保留可变网络对象。后台、收起、切换 provider 时调用 cancel，不创建轮询 timer。

```objc
self.caiyun = [CYCaiyunProvider new];
NSError *error = nil;
// longitude/latitude 从非 secret prefs 读取 NSNumber 或 nil，不使用 doubleValue 将缺失转 0。
[self.caiyun setLongitude:longitude latitude:latitude error:&error];
[self.caiyun refreshManual:NO completion:^(CYResult *result) {
    // result.snapshot == nil: 尚无有效彩云数据，显示 -- / 未就绪。
    // result.error.localizedDescription 是组件本地脱敏文案。
    // result.stale 时显示「数据已过期」；snapshot.timestamp 是上次本地成功时间。
    // 一整个 UI 更新只能来自此 snapshot，严禁拿系统 city 另一地点补字段。
}];
```

设置 UI 由集成者实现：secureTextEntry，保存后立即清空输入控件；`saveToken:error:` 保存或更新 Keychain，`hasToken:error:` 只返回是否存在，不提供明文 Token getter。`deleteToken:error:` 删除。任何失败必须展示脱敏错误，不能写明文 prefs 兜底；删除失败 Keychain 旧项可能仍在，组件当前实例禁止再用，不能声称已删除成功。集成者必须保持编辑界面可纠错。

经纬度需先对输入文本完整严格解析（拒绝多余字符、空串、bool、NaN/Infinity），再传 NSNumber。`validateLongitude:latitude:` 再次验证 finite 和范围 [-180,180]/[-90,90]。nil,nil 表示未配置；0,0 有效。不要通过 NSNumberFormatter 的宽松部分匹配或 NSString.doubleValue 将非法字符转 0。无自动坐标基准转换。alias、provider、经纬度由集成者存非 secret prefs；偏好 plist/导出/备份对象中绝不包含 Token。

切换设置使用 `setLongitude:latitude:`；切换回相同地点可复用当前同配置缓存。保存/删除 Token、改地点递增 configGeneration，清掉旧缓存并取消旧请求；无论新 Token 写入成功与否，旧 snapshot 均不再可用。取消和清缓存保留节流边界，避免设置编辑绕限流。因错误配置被 400/401/403/422 阻断时需保存/修改配置以解除；clearCache 本身不解除权限限制。无 token/坐标不请求。

`currentResult` 为同步读取内存状态，snapshot 为 nil 就是未就绪，哪怕 error 为 nil；不是隐藏发请求。`refreshManual:NO` on-demand 检查 15 分钟 TTL（工程默认，不是官方保证），过期才请求；`YES` 越过 TTL 但仍受 60 秒最小请求间隔和退避限制。singleflight 将同时调用者合并，结果逐个主线程交付。error 下保留同代际旧数据，stale=YES。429 Retry-After 支持秒/HTTP date，约束 60–3600 秒；失败指数退避加抖动，上限 1 小时，无自动 timer。nextAllowedRefresh 供 UI 提示，不安排后台请求。

## 模型与资源适配

CYSnapshot：source=caiyun、configGeneration、timestamp（本地成功收到）、可空 serverTimestamp/timezone/currentTemperature/maximum/minimum、condition、hours。
CYHour：date、可空 temperature/probability、condition。小时 probability 已为百分数，1=1%，不乘 100。缺/null/bool/非有限数字为 nil，不填 0℃、0% 或晴。每日概率量程未获官方确认，因此不解析展示。
CYCondition：原 skycon、真实中文 text、可空 basename、symbol。basename 仅来自已核对 WCCAssetKeys.h 的白名单，不由服务端拼路径。20 个官方枚举完整映射。大雨、暴雨、重霾、暴雪、沙尘等没有精确绑定 basename，只返回 SF fallback。UI 必须先安全读取现有绑定资源，缺失则 symbol，再不可用退 cloud.fill；不得因为 Resources 存在同名 PNG 就新增 binding key。

显式 DAY/NIGHT 优先；小雨小雪只用预测 datetime + 同日 astro 判昼夜，未知用中性 SF；不使用 _currentCity.isDay。小时数组按绝对 datetime join + 排序，不按数组下标。ISO 时间接受无秒/有秒/offset；timezone 名优先，否则有限整数合法 tzshift，均无效不猜时区，不展示今日最高最低。每日极值按目标地点当天匹配。forecast_keypoint 不作为当前天气，完全不混系统字段。

主工程 WCCHourlyItem 属现有 UI 模型，不应把彩云码伪造为旧 0–47 conditionCode；集成者应加独立 snapshot 分支，使用 CYHour 的温度/概率/时间/condition 并沿用布局与媒体生命周期，不调用依赖当前 city.isDay 的 imageNameForConditionCode:。本组件不修改 Controller 或 bindings。

## 安全边界

- 用户 Token 唯一持久存储是 generic password，service=CCWeatherModule.Caiyun.v1，account=user-token，WhenUnlockedThisDeviceOnly，禁 iCloud 同步，无 access group。假设设置和模块在同一 SpringBoard 进程；若将设置迁到别的进程必须重新验证签名/Keychain 权限，不能假跨进程可读。
- Token 用保守 ASCII 字母/数字/下划线/连字符单段白名单，1–512 字符，拒绝控制字符、空白、slash/backslash/dot/percent/query 注入；NSURLComponents 另做安全 percent encoding。官方未承诺全部 Token 字符集，若用户实际凭据不满足白名单，明确格式错误，不放宽至原始 path。
- 固定 HTTPS api.caiyunapp.com/v2.6/.../weather；lang zh_CN、unit metric:v2、24 小时、5 天、dailystart 0、alert false。正常系统 TLS 验证，拒绝一切 HTTP 重定向，ephemeral NSURLSession，禁 URLCache、cookie 和 URLCredentialStorage，no-store，不持久化解析结果。
- URL 必然短暂包含 Token/经纬度（官方协议要求），仅进入内存请求对象；不输出 URL/request/原始 NSError.userInfo/服务端错误。上层只能使用组件本地错误描述，绝不开启 NSURLSession/CFNetwork verbose、代理抓包、遥测请求日志。不能保证越狱注入、系统诊断、恶意代理或内存转储永远拿不到秘密；NSString/NSURL 的系统分配不可承诺可靠归零。
- 响应上限 2MiB；HTML/非 JSON/失败业务状态均映射本地错误。无服务端错误正文传播，无自动系统地点回填。没有实时额度字段，也不宣称套餐一定有 24 小时/5 天数据。
- 组件 ARC；provider dealloc 取消 wire；每个 session 在完成/取消后 invalidation 释放 delegate；网络/解析闭包弱捕获 provider；generation+serial 拒绝晚到结果。集成者回调捕获 Controller 应使用 weak 避免 UI 自身长期持有。

## 验证状态

已准备离线断言：0℃、null/bool/程序生成 NaN、概率 1%=1、数组错序/绝对时间 join、无秒/有秒/UTC offset、目标时区跨日、tzshift 降级/非法 bool、显式 night、未知 astro、unknown skycon、HTTP HTML 200/429/500、Retry-After 上限、网络错误脱敏、TTL/singleflight/60 秒、cancel/settings generation、不同坐标无旧缓存、Keychain 失败无 plaintext fallback。

- macOS Foundation 编译/执行：NOT RUN（当前 Linux 无 Apple SDK）。
- 真 Keychain/重定向/TLS iOS 集成测试：NOT RUN；这里只实现并代码审查，测试只模拟存储与 transport。
- live API：NOT RUN。
- iOS 16.6 / SpringBoard 真机：NOT RUN。

首次 macOS 编译后仍须在目标 iOS 16.6 环境验证 Security entitlement、锁屏存取错误、网络取消、SF 可用性、UI 状态及权限拒绝路径。不得以 synthetic/mock 通过替代真实 API 或真机验收。
