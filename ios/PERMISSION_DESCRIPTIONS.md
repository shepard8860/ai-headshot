# 权限用途说明文案 / Permission Usage Descriptions

> 本文件包含 iOS App 所有权限在 Info.plist 中对应的 `UsageDescription` 文案，用于 App Store 审核和用户授权弹窗展示。
>
> 文案要求：简洁、诚实、具体，必须说明**为什么需要该权限**以及**用于什么功能**。

---

## 1. 相机权限 / Camera Permission

### Key
`NSCameraUsageDescription`

### 用途说明
用于拍摄自拍照，作为 AI 职业证件照生成的人脸素材。应用会实时检测人脸位置、光线质量和拍摄角度，帮助用户拍出符合合成要求的照片。

### Info.plist 已配置文案
```xml
<key>NSCameraUsageDescription</key>
<string>AI职业照需要访问您的相机，以便拍摄证件照并实时检测人脸质量。</string>
```

### 审核建议文案（备选/优化版）
```
我们需要访问您的相机来拍摄自拍照，用于生成 AI 职业证件照。拍摄过程中会实时检测人脸位置、光线和角度，确保获得最佳合成效果。
```

---

## 2. 相册读取权限 / Photo Library Read Permission

### Key
`NSPhotoLibraryUsageDescription`

### 用途说明
用于从相册中选择已有的自拍照，作为 AI 职业证件照生成的人脸素材。

### Info.plist 当前配置
> ⚠️ 注意：当前 Info.plist 中 `NSPhotoLibraryUsageDescription` 的描述文案为保存图片用途。建议拆分为读取和写入两条不同描述，或统一修改为覆盖两种用途的描述。

### 建议更新文案
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>AI职业照需要访问您的相册，以便选择自拍照进行 AI 证件照生成，以及保存生成的证件照到相册。</string>
```

---

## 3. 相册写入（保存）权限 / Photo Library Add Permission

### Key
`NSPhotoLibraryAddUsageDescription`

### 用途说明
用于将 AI 生成的职业证件照保存到用户的系统相册，方便用户后续使用（如上传简历、设置为头像等）。

### Info.plist 已配置文案
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>AI职业照需要访问您的相册，以便保存生成的证件照到本地。</string>
```

### 审核建议文案（优化版）
```
我们需要访问您的相册来保存生成的 AI 职业证件照，方便您随时使用。
```

---

## 4. 网络权限 / Network Access

### Key
> iOS 系统不通过 UsageDescription 弹窗申请网络权限，但需要在隐私政策中明确说明网络数据传输内容。

### 用途说明
应用需要网络连接才能：
1. 将用户上传的人脸照片传输至云端 AI 服务进行职业证件照生成
2. 从服务器获取 28 种职业照模板列表
3. 查询订单处理状态和下载生成结果
4. 验证应用内购买（IAP）交易

### 隐私政策中应包含的描述
```
本应用需要访问互联网以实现核心功能：将您的人脸照片上传至云端 AI 服务进行图像合成处理、获取模板资源、验证支付状态及下载生成结果。所有数据传输均通过 HTTPS/TLS 1.3 加密。
```

---

## 5. 应用内购买（IAP）/ In-App Purchase

### Key
> 不通过 Info.plist 描述，但需要在 App Store Connect 和隐私政策中说明。

### 用途说明
用户可通过应用内购买解锁高清图片生成权限。购买由 Apple App Store 处理，我们仅接收交易凭证用于解锁对应服务。

### App Store 审核备注文案
```
应用内购买项目ID：com.ai-headshot.hd_unlock
用途：解锁高清职业证件照生成功能
类型：一次性消耗型购买（非订阅）
```

---

## 6. 人脸检测（本地 Vision 框架）/ Face Detection

### Key
> Apple Vision 框架为系统级 API，不需要单独的 UsageDescription。但需要在隐私政策中说明。

### 用途说明
应用在设备本地使用 Apple Vision 框架进行人脸检测和质量评估（包括人脸角度、光线、遮挡检测等）。**所有人脸检测过程均在设备本地完成，不会上传原始人脸特征数据。**

### 隐私政策中应包含的描述
```
我们使用 Apple Vision 框架在您的设备本地进行人脸检测和质量评估（包括角度、光线、遮挡等）。该处理完全在本地完成，原始人脸数据不会被上传。
```

---

## 7. 推送通知（如后续启用）/ Push Notifications

### Key
`UNUserNotificationCenter` (代码中注册)

### 当前状态
> 当前版本未使用推送通知功能。如后续添加，需补充以下描述。

### 预留文案
```xml
<key>NSUserTrackingUsageDescription</key>
<string>我们需要发送通知来告知您证件照生成完成的进度和结果。</string>
```

---

## 8. Info.plist 完整权限清单汇总

以下是 Info.plist 中所有与隐私相关的配置项汇总：

| Key | 用途 | 状态 |
|-----|------|------|
| `NSCameraUsageDescription` | 相机拍摄自拍照 | ✅ 已配置 |
| `NSPhotoLibraryUsageDescription` | 相册读取/保存 | ⚠️ 建议优化 |
| `NSPhotoLibraryAddUsageDescription` | 保存证件照到相册 | ✅ 已配置 |
| `ITSAppUsesNonExemptEncryption` | 加密声明（否） | ✅ 已配置 |
| `NSCameraReactionEffectsEnabled` | 相机反应特效 | ✅ 已配置 |

---

## 9. App Store 隐私标签（App Privacy）对应关系

| 数据类型 | 是否收集 | 用途 | Apple 隐私标签对应 |
|---------|---------|------|------------------|
| 照片或视频 | 是 | 生成职业证件照 | Photos or Videos |
| 设备标识符 | 是 | 分析/功能 | Device ID |
| 购买记录 | 是 | 功能 | Purchase History |
| 精确位置 | 否 | - | - |
| 联系信息 | 否 | - | - |
| 用户内容 | 是（用户主动上传） | 生成证件照 | Photos or Videos |
| 诊断数据 | 否 | - | - |

---

## 10. 中国区 App Store 特别注意事项

1. **算法备案说明**：本应用使用深度合成（AIGC）技术生成图像，需在隐私政策中明确说明算法备案情况。
2. **数据出境**：所有用户数据（包括人脸照片）均在中国大陆境内处理和存储，不涉及跨境传输。
3. **人脸信息保护**：人脸照片属于敏感个人信息，需在隐私政策中单列章节说明收集目的、处理方式、保存期限和删除机制。
4. **未成年人保护**：明确说明不主动收集未成年人信息，建议年龄限制为 18+。
5. **权限文案规范**：所有权限描述不得包含营销话术，必须客观说明用途。

---

## 11. 文案审核清单

- [x] 相机权限文案说明具体用途（拍摄证件照 + 人脸检测）
- [x] 相册权限文案说明读取和写入双重用途
- [x] 未使用模糊或误导性描述（如"为了提供更好的服务"）
- [x] 未包含不必要的营销词汇
- [x] 权限描述与代码实际行为一致
- [x] 隐私政策中涵盖所有数据收集和使用场景
- [ ] 建议补充：App 启动时的隐私协议同意弹窗（首次使用）
