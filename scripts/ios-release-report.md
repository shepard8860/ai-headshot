# AI职业照 iOS 发布工程准备报告

> 生成时间：2026-04-24  
> 检查范围：ios/ 目录下的工程、资源、配置文件  
> 检查人：ios_release agent

---

## 1. 工程概况

| 项目 | 内容 |
|------|------|
| 应用名称 | AI职业照 / AI职业证件照生成器 |
| 技术栈 | Swift 5.9+, SwiftUI, Swift Package Manager |
| 支持平台 | iOS 16+ |
| Bundle ID | `com.ai-headshot.app` |
| 当前版本 | `1.0.0` (Marketing) / Build `1` |
| 项目结构 | 纯 SPM，无 `.xcodeproj` / `.xcworkspace` |

---

## 2. 逐项检查结果

### 2.1 App Icon 配置

**状态：⚠️ 部分就绯**

- `Assets.xcassets/AppIcon.appiconset/Contents.json` 已配置✅
- 支持模式：Universal、Dark、Tinted（1024x1024）✅
- **问题：目录下缺少实际 `.png` 图片文件**
  - 当前仅有 `Contents.json`，没有图片资源
  - 需添加 `AppIcon~ios-marketing.png` 等必要尺寸

**建议：**
1. 制作 1024x1024px 营销图标（无透明层、无圆角）
2. 如支持 Dark 和 Tinted，同步制作对应变体
3. 放入 `ios/Sources/AIHeadshot/Resources/Assets.xcassets/AppIcon.appiconset/`
4. 可选：在 `Package.swift` 或 `Info.plist` 中确保图标被正确包装进 Bundle

### 2.2 Launch Screen

**状态：⚠️ 自定义实现**

- 存在 `LaunchScreenView.swift`（SwiftUI 自定义启动视图）✅
- `App.swift` 中通过 `ZStack` 动画叠加实现 2s 启动显示 ✅
- **问题：无传统 `LaunchScreen.storyboard`，且 `Info.plist` 中缺少 `UILaunchScreen` 配置**

**建议：**
- 对于 iOS 16+ 纯 SwiftUI 应用，当前方案可行，但建议在 `Info.plist` 中补充 `UILaunchScreen` 字典提供系统级占位，减少系统白屏风险
- 示例补充：
  ```xml
  <key>UILaunchScreen</key>
  <dict>
      <key>UIImageName</key>
      <string>LaunchScreen</string>
      <key>UIColorName</key>
      <string>LaunchScreenBackground</string>
  </dict>
  ```

### 2.3 Info.plist 完整性

**状态：⚠️ 基本完整，建议补充**

已配置字段（✅）：
- `CFBundleDisplayName`: AI职业照
- `CFBundleIdentifier`: com.ai-headshot.app
- `CFBundleShortVersionString`: 1.0.0
- `CFBundleVersion`: 1
- `LSRequiresIPhoneOS`: true
- `UIApplicationSceneManifest`
- `UISupportedInterfaceOrientations` / `~ipad`
- `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`
- `ITSAppUsesNonExemptEncryption`: false

**建议补充字段：**
| 字段 | 建议值 | 原因 |
|------|--------|------|
| `UILaunchScreen` | 启动图/背景色 | 减少白屏 |
| `UIRequiredDeviceCapabilities` | `camera` / `armv7` | 限制无相机/过老设备下载 |
| `CFBundleName` | AIHeadshot | 部分场景需要短名称 |

### 2.4 版本号与 Bundle ID

**状态：⚠️ 需注意**

- Bundle ID: `com.ai-headshot.app`
  - 含连字符 `-`，现代 iOS/macOS 已兼容，Apple Developer Portal 可注册
  - 需确认在 [developer.apple.com](https://developer.apple.com) 中已注册该 Bundle ID
- 版本: 1.0.0 (1)
  - TestFlight 每次上传必须递增 Build 号
  - 建议上传前将 Build 号至少改为 `2`

### 2.5 隐私清单

**状态：✅ 已配置且完整**

- `PrivacyInfo.xcprivacy` 存在且内容完整
- 已声明的数据类型：照片/视频、设备ID、购买历史
- 已声明的 API 访问：相机、相册
- `NSPrivacyTracking` 设为 false，无跟踪域名

### 2.6 IAP 配置

**状态：⚠️ 代码就绪，需后台配置**

- 产品 ID: `com.ai-headshot.hd_unlock`
- 使用 StoreKit 2 (`Product.products`)
- 需在 App Store Connect -> 功能 -> App 内购买项目中预先创建
- 需签署 Paid Apps Agreement

### 2.7 App Group 配置

**状态：⚠️ 代码已确定，需开发者配置**

- 代码中使用: `group.com.ai-headshot.app`
- 需在 Apple Developer Portal 开启 App Groups capability
- 需在 Provisioning Profile 中包含该 capability
- 需在 Xcode Signing & Capabilities 中正确配置

### 2.8 后端 API 与运营

**状态：⚠️ 需确认**

- 生产域名: `https://api.ai-headshot.app`
- 需确认：
  1. 域名已备案且解析正常
  2. 支持 HTTPS（强烈建议全站 HTTPS）
  3. 中国区上架需确认 ICP 备案完成
  4. 隐私政策和支持页面已部署并可访问

---

## 3. 已创建的发布工具

### 3.1 scripts/release-checklist.md
- TestFlight 上传前检查清单
- App Store 正式上架前检查清单
- 签名、证书、Provisioning Profile 详细检查表
- 常见问题与解决方案
- 本地验证命令参考

### 3.2 scripts/setup-testflight.sh
- 命令：`check` / `build` / `archive` / `export` / `upload` / `full`
- 自动检查环境（Xcode、Swift、证书、Profile、版本号、App Icon、隐私清单）
- 支持 SPM 直接归桢（无 .xcodeproj 时）
- 支持 App Store Connect API Key 自动上传（可选）
- 交互式流程控制（逐步确认）

---

## 4. 上架前必须完成的事项

### 高优先级（阻碍上传）
1. [ ] **添加 App Icon PNG 图片**（至少 1024x1024 营销图标）
2. [ ] **更新 Build 号**（递增，如 `1` -> `2`）
3. [ ] **Apple Developer Portal 注册 Bundle ID**（如未注册）
4. [ ] **配置 Distribution 证书和 App Store Provisioning Profile**
5. [ ] **App Store Connect 创建 App 并配置 IAP 商品**

### 中优先级（审核风险）
6. [ ] **补充 `UILaunchScreen` 到 Info.plist**
7. [ ] **添加 `UIRequiredDeviceCapabilities`**（限制无相机设备）
8. [ ] **确认隐私政策页面已上线**
9. [ ] **确认 API 域名已备案且可用**
10. [ ] **完整测试 IAP 流程**（沙盒和生产环境）

### 低优先级（优化）
11. [ ] **制作应用截图**（iPhone 6.7", 6.5", 5.5" 必备）
12. [ ] **准备 App Store 元数据**（描述、关键词、支持网站）
13. [ ] **签署 Paid Apps Agreement**（含 IAP 时必须）
14. [ ] **使用 `scripts/setup-testflight.sh check` 检查本地环境**
15. [ ] **执行模拟器/真机构建，验证无警告错误**

---

## 5. 执行推荐流程

```bash
# 步骤 1: 完成高优先级事项（添加图标、更新版本、配置证书）
# 步骤 2: 检查环境
cd ~/AIFactory/projects/ai-headshot
./scripts/setup-testflight.sh check

# 步骤 3: 完整流程（检查 -> 归桢 -> 导出 -> 上传）
./scripts/setup-testflight.sh full

# 或分步执行：
./scripts/setup-testflight.sh archive
./scripts/setup-testflight.sh export
./scripts/setup-testflight.sh upload
```

---

## 6. 风险提示

1. **AI 内容审核风险**：Apple 对 AI 生成人像有深度伪造相关的审核政策。建议在审核备注中明确说明：
   - 用户主动上传自己的照片
   - 生成结果仅用于用户个人证件照场景
   - 不涉及虚假身份传播

2. **ICP 备案**：中国区 App Store 上架要求应用内嵌的网页/后端域名已备案。请确认 `api.ai-headshot.app` 已完成 ICP 备案。

3. **SPM 项目归桢**：纯 SPM 项目直接用 `xcodebuild archive -scheme` 可能遇到证书/签名问题。若自动签名失败，建议在 Xcode 中打开 `Package.swift` 生成临时 `.xcodeproj`，配置好 Signing 后再归桢。

---

*报告完。如需进一步调整配置或修改代码，请在 Xcode 环境中测试验证后再执行发布流程。*
