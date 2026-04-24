# AI职业照 iOS App 发布检查清单

> 项目：AI职业证件照生成器  
> 技术栈：Swift Package Manager，iOS 16+  
> Bundle ID：`com.ai-headshot.app`  
> 当前版本：`1.0.0 (1)`

---

## 一、工程结构检查结果（预检）

| 检查项 | 状态 | 备注 |
|--------|------|------|
| App Icon 配置 | ⚠️ 部分就绪 | `Contents.json` 已配置（1024px Universal / Dark / Tinted），**缺少实际 PNG 图片文件** |
| Launch Screen | ⚠️ 自定义实现 | 使用 `LaunchScreenView.swift` + `App.swift` 动画叠加实现，无 `LaunchScreen.storyboard` |
| Info.plist | ⚠️ 基本完整 | 主要字段齐全，建议补充 `UILaunchScreen`、`UIRequiredDeviceCapabilities` |
| Bundle ID | ⚠️ 需注意 | `com.ai-headshot.app` 含连字符，现代 iOS 兼容，但需确认 Apple Developer 中已注册 |
| 版本号 | ✅ 已配置 | `1.0.0` (Marketing) / `1` (Build) |
| 隐私清单 | ✅ 已配置 | `PrivacyInfo.xcprivacy` 完整，声明了照片、设备ID、购买历史及相机/相册 API |
| IAP 配置 | ⚠️ 代码就绪 | `com.ai-headshot.hd_unlock` 需在 App Store Connect 预先创建 |
| App Group | ⚠️ 需配置 | `group.com.ai-headshot.app` 需在 Developer Portal 开启并签名 |
| API 域名 | ⚠️ 需确认 | `https://api.ai-headshot.app` 需备案且支持 HTTPS（中国区上架需 ICP） |
| 打包方式 | ⚠️ 需准备 | 纯 SPM 项目，无 `.xcodeproj`，需通过 `xcodebuild` 或生成 Xcode 项目后归档 |

---

## 二、TestFlight 上传前检查清单

### 2.1 代码与资源
- [ ] **App Icon 图片就绪**：`ios/Sources/AIHeadshot/Resources/Assets.xcassets/AppIcon.appiconset/` 下放置 `1024x1024` 的 PNG（`AppIcon~ios-marketing.png`），以及 Dark/Tinted 变体（如支持）
- [ ] **Launch Screen 无白屏**：真机或模拟器冷启动测试，确认无系统白屏闪动。当前 SwiftUI 动画方案需确保 `ContentView` 初始渲染足够快
- [ ] **所有 SwiftUI Preview 编译通过**：`swift build` 无警告错误
- [ ] **单元测试通过**：`cd ios && swift test`
- [ ] **无调试代码残留**：检查无 `print`、`debugPrint`、硬编码测试数据、本地 Mock URL
- [ ] **API 基地址指向生产环境**：确认 `Constants.baseURL == https://api.ai-headshot.app`

### 2.2 Info.plist 补充项
- [ ] （建议）添加 `UILaunchScreen` 字典，提供系统级启动占位（即使使用 SwiftUI 自定义启动页，可减少白屏风险）
- [ ] （建议）添加 `UIRequiredDeviceCapabilities` -> `camera` / `armv7`（如仅支持带相机设备）
- [ ] 确认 `ITSAppUsesNonExemptEncryption` 为 `false`（当前已配置 ✅）
- [ ] 如需 HTTP 明文传输，添加 `NSAppTransportSecurity` -> `NSAllowsArbitraryLoads` 例外（强烈建议全站 HTTPS）

### 2.3 签名与证书
- [ ] Apple Developer 账号有效且已付费（$99/年）
- [ ] Bundle Identifier `com.ai-headshot.app` 已在 [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) 注册
- [ ] App ID 开启了必要 Capabilities：**App Groups** (`group.com.ai-headshot.app`)、**In-App Purchase**
- [ ] 生成并下载 **iOS Distribution Certificate**（App Store 发布用）
- [ ] 创建并下载 **App Store Profile**（Distribution -> App Store），关联上述 App ID 与证书
- [ ] 本地 Keychain 已安装 Distribution 证书及私钥

### 2.4 App Store Connect 配置
- [ ] [App Store Connect](https://appstoreconnect.apple.com) 中已创建 App，Bundle ID 匹配
- [ ] App 名称（`AI职业照`）在目标市场未重复/冲突
- [ ] 主要语言、副标题、关键词、描述、宣传文本已准备
- [ ] **IAP 商品已创建**：`com.ai-headshot.hd_unlock`，状态为“准备提交”，定价层级已选
- [ ] 税务与协议（Paid Apps Agreement）已签署（因含 IAP）
- [ ] TestFlight 测试信息（Beta App Review 信息、测试账号）已填写

### 2.5 构建与上传
- [ ] Xcode 版本与 App 目标版本兼容（建议 Xcode 15+ 用于 iOS 16+）
- [ ] 执行归档：`xcodebuild archive -scheme AIHeadshot -destination 'generic/platform=iOS' -archivePath build/AIHeadshot.xcarchive`
- [ ] 导出 IPA（App Store 方式）并验证签名
- [ ] 上传构建版本到 App Store Connect / TestFlight（见 `setup-testflight.sh` 脚本）
- [ ] 上传成功后，在 App Store Connect -> TestFlight 中确认构建已处理（通常 5–30 分钟）

---

## 三、App Store 正式上架前检查清单

### 3.1 元数据与素材
- [ ] **截图**：iPhone 6.7" / 6.5" / 5.5"  required；iPad 12.9"（如支持）
- [ ] **App 预览视频**（可选但推荐）：15–30 秒，展示拍摄->生成->保存流程
- [ ] **App 图标**：1024x1024px，无圆角遮罩，无透明通道（或正确渲染）
- [ ] **描述文案**：突出 AI 生成、证件照模板、高清解锁等核心卖点
- [ ] **关键词**：职业照、证件照、AI头像、形象照、简历照片 等
- [ ] **支持 URL**：有效的联系网站/支持页面（需备案，如中国区）
- [ ] **隐私政策 URL**：必须提供，内容需与 `PrivacyInfo.xcprivacy` 一致
- [ ] **分级**：根据内容选择年龄分级（通常 4+ 或 9+）

### 3.2 合规与审核
- [ ] **用户生成内容（UGC）/ AI 生成内容**：若使用 AI 生成人像，需在审核备注中说明技术原理及合规性（肖像权、深度伪造政策）
- [ ] **IAP 流程测试**：在沙盒环境完整测试购买->恢复购买-> receipt 验证
- [ ] **账号登录**：如使用自建 UserID（当前基于 UUID + UserDefaults），无需 Apple Sign-In；若后续增加第三方登录，必须同时提供 Sign in with Apple
- [ ] **相机权限提示**：`NSCameraUsageDescription` 已说明用途 ✅，确保弹窗文案自然
- [ ] **相册权限提示**：`NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription` ✅
- [ ] **性能**：冷启动 < 5s，无崩溃，内存使用合理（图像处理注意大内存峰值）
- [ ] **网络**：弱网/离线场景有友好提示（当前 `APIService` 有超时配置 ✅）

### 3.3 后端与运营
- [ ] 生产 API `https://api.ai-headshot.app` 健康检查通过
- [ ] 服务器具备处理审核人员测试的能力（模板列表、生成队列、支付验证）
- [ ] 如需 ICP 备案，确认域名备案信息与开发者主体一致
- [ ] 用户协议 / 隐私政策页面已上线，且包含：数据收集范围、存储期限、用户删除权利、第三方 SDK 列表（如有）

### 3.4 最终构建确认
- [ ] Build 号递增（如上次上传为 1，本次至少为 2）
- [ ] 版本号符合语义化（如 `1.0.0`、`1.0.1`）
- [ ] 使用 Release 配置编译，`SWIFT_OPTIMIZATION_LEVEL = -O`
- [ ] 无 Bitcode 问题（Xcode 14+ 默认关闭 Bitcode，确认 `ENABLE_BITCODE = NO`）
- [ ] 导出 IPA 后，用 `codesign -dvvv Payload/AIHeadshot.app` 验证签名及 Provisioning Profile

---

## 四、签名、证书、Provisioning Profile 检查项（详细）

### 4.1 证书（Certificate）
| 检查项 | 说明 |
|--------|------|
| Apple Developer Program 会员状态 | 在 [Account](https://developer.apple.com/account) 确认 **Active** |
| iOS Distribution Certificate | 用于 App Store 发布；由 Team Agent/Admin 创建；私钥保存在构建机 Keychain |
| 证书有效期 | 每年需 renew，过期则所有 Profile 失效 |
| 机器私钥 | 构建机器的 `钥匙串访问 -> 登录 -> 我的证书` 中需存在对应私钥 |

### 4.2 标识符（Identifier）
| 检查项 | 说明 |
|--------|------|
| Bundle ID | `com.ai-headshot.app`（显式/Explicit 推荐） |
| App Groups | 开启并确认 Group ID = `group.com.ai-headshot.app` |
| In-App Purchase | 必须开启，否则无法提交含 IAP 的构建 |
| Push Notifications | 如需推送（当前代码未使用），可暂不开 |
| Associated Domains | 如需 Universal Links（当前未使用），按需开启 |

### 4.3 Provisioning Profile
| 检查项 | 说明 |
|--------|------|
| 类型 | **iOS App Store**（Distribution） |
| 关联 App ID | `com.ai-headshot.app` |
| 关联证书 | 上述 iOS Distribution Certificate |
| 有效期 | 每年 renew，与证书同步 |
| 本地安装 | 下载后双击安装，或放入 `~/Library/MobileDevice/Provisioning Profiles/` |
| 自动签名（Xcode）| 如用 Xcode 自动签名，需登录正确的 Apple ID（Team） |
| 手动签名（CI）| 需指定 `PROVISIONING_PROFILE_SPECIFIER` 和 `CODE_SIGN_IDENTITY` |

### 4.4 本地快速验证命令
```bash
# 查看本地有效证书
security find-identity -v -p codesigning

# 查看已安装的 Provisioning Profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# 查看特定 Profile 内容（XML 解码）
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/xxxx.mobileprovision | grep -A2 -E 'Name|TeamName|BundleIdentifier'
```

---

## 五、常见问题与解决

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| `ERROR ITMS-90713: Info.plist missing` | SPM 项目未正确生成 Bundle | 确认 `Package.swift` 中 `.process("Resources")` 已配置 ✅，归档时资源已嵌入 |
| `Invalid Bundle Structure` | 资源文件被误放入根目录 | 检查 `Resources` 目录层级，确保 `Assets.xcassets` 在 Bundle 内 |
| `Missing App Icon` | 缺少 `1024x1024` marketing 图标 | 补充 PNG 到 AppIcon.appiconset |
| `ITMS-90683: Missing Purpose String` | 隐私权限描述缺失 | 补充 `NSXXXUsageDescription` 到 Info.plist |
| `Invalid Provisioning Profile` | Profile 与证书/App ID/设备不匹配 | 重新下载 Distribution Profile，或开启 Xcode 自动签名 |
| `AI-Generated Content` 审核被拒 | Apple 对 AI 人像生成的深度伪造政策 | 在审核备注中明确说明：用户自主上传照片、生成结果仅用户本人可见、无虚假身份传播风险 |
| 中国区 ICP 备案问题 | 未备案域名或主体不一致 | 确保 `api.ai-headshot.app` 及支持/隐私政策域名已备案 |

---

## 六、参考链接

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines – App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Describing Use of Required Reason API](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)
- [Uploading apps overview – Apple Developer](https://developer.apple.com/documentation/xcode/uploading-an-app-to-app-store-connect)
- [TestFlight Beta Testing](https://help.apple.com/app-store-connect/#/devdc42b26b8)
