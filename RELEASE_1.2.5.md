# 1.2.5

Based on c5685b444a5cef18f87327fd0dd9229cd81e5e91 (1.2.4).

Caiyun realtime.wind.speed is parsed as km/h, realtime.wind.direction as meteorological FROM degrees, and realtime.humidity as a fraction. Strict finite numeric parsing rejects booleans, strings, null, negative speed, direction outside 0…360 and humidity outside 0…1. Render includes compass direction, calculated Beaufort force, explicit km/h and relative humidity. Absent fields are omitted. Native City declarations do not establish these units; no native wind/humidity is guessed.

The existing weather information line receives these details, and the existing precipitation line receives a forecast summary. The summary uses only known contiguous hourly skycon samples from successful receipt time to at most 24 hours ahead, labels actual local start/end dates and times, and omits when timezone or usable forecast is missing. It never labels incomplete data as “未来24小时”. Existing city, temperature/high-low, greeting and layout are retained; compact widths can truncate long details according to existing label behavior.

Two independent default-off main-content effects have separate enable controls and speed sliders (left 6s, midpoint 3s, right 1.5s full cycles). Opacity animates 45…100% of model opacity; scale animates .94…1.06 via additive CATransform3D. Neither writes base transform, size, position or model opacity. ShadowOpacity breathing remains independent. Owner visibility, settings suspension, CC exit, background and lock handling remove only the two owned keys; resume recreates them. The animation functions never reload media or touch hourly/audio code.

Presentation v5 persists both [enabled,speed] arrays, with backup-before-load and rollback. v1–v4 documents remain readable and preserve these newly introduced preferences. Missing v5 fields use disabled/standard defaults. No token, device location, user media or mappings enter schemes or package resources.

GitHub Actions macOS performs production Foundation parser/render and configuration transaction tests, real QuartzCore CALayer coexistence/endpoints/base preservation/pause/resume checks (UIKit test shim), prior C/Foundation/static regressions, then Theos arm64/arm64e build and payload inspection. Live Caiyun API, actual Keychain, UIKit pixel rendering, device lifecycle and iPhone 14 Pro Max iOS 16.6 RootHide remain unverified without device testing.
