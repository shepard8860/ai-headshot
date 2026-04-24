# App Store 审核材料准备清单报告

> 项目：AI职业照 / AI Headshot  
> 报告生成日期：2025-04-24  
> 适用平台：中国区 App Store (App Store China)  
> 应用版本：1.0.0  
> Bundle ID：com.ai-headshot.app

---

## 一、文档产出清单

| 序号 | 文件名 | 路径 | 状态 | 备注 |
|------|--------|------|------|------|
| 1 | PRIVACY_POLICY.md | `ios/PRIVACY_POLICY.md` | ✅ 已创建 | 符合中国区法规要求，简体中英文双语 |
| 2 | APP_STORE_COPY.md | `ios/APP_STORE_COPY.md` | ✅ 已创建 | 包含标题、副标题、关键词、描述、版本说明、审核备注 |
| 3 | PERMISSION_DESCRIPTIONS.md | `ios/PERMISSION_DESCRIPTIONS.md` | ✅ 已创建 | 权限用途说明文案及 Info.plist 对照检查 |
| 4 | PrivacyInfo.xcprivacy | `ios/PrivacyInfo.xcprivacy` | ✅ 已更新 | 补充了 PhotoLibrary 读取权限和 UserDefaults 声明 |
| 5 | APP_REVIEW_CHECKLIST.md | `ios/APP_REVIEW_CHECKLIST.md` | ✅ 已创建 | 本报告 |

---

## 二、PrivacyInfo.xcprivacy 检查结果

### 原始状态
PrivacyInfo.xcprivacy 已存在，包含基础配置，但存在以下缺失：
1. `NSPrivacyAccessedAPICategoryPhotoLibrary` 仅声明了 `AddToAlbum`（仅写入），未声明 `ReadWrite`（读取）用途。应用支持用户从相册选择自拍上传，必须声明读取权限。
2. 未声明 `NSPrivacyAccessedAPICategoryUserDefaults`。代码中使用了 `UserDefaults.standard` 存储匿名用户ID，需在隐私清单中声明。

### 更新内容
| 项目 | 操作 | 说明 |
|------|------|------|
| PhotoLibrary 访问理由 | 新增 | 添加 `NSPrivacyAccessedAPITypeReasonReadWrite`，与现有的 `AddToAlbum` 共存 |
| UserDefaults 访问声明 | 新增 | 添加 `NSPrivacyAccessedAPICategoryUserDefaults`，理由代码 `CA92.1` |

### 当前完整配置概览

**数据收集类型 (NSPrivacyCollectedDataTypes)**
- 照片/视频 (PhotosorVideos) — 用于应用功能，不用于追踪
- 设备标识符 (DeviceID) — 用于应用功能和分析，不用于追踪
- 购买记录 (PurchaseHistory) — 用于应用功能，不用于追踪

**访问 API 类型 (NSPrivacyAccessedAPITypes)**
- 相机 (Camera) — 拍摄媒体
- 相册 (PhotoLibrary) — 读写相册 + 添加到相册
- 用户默认设置 (UserDefaults) — 管理应用状态和偏好设置 (CA92.1)

**追踪 (NSPrivacyTracking)**
- 不进行跨应用追踪 (✓)
- 追踪域名列表为空 (✓)

---

## 三、Info.plist 权限描述检查结果

| Key | 当前文案 | 状态 | 建议 |
|-----|---------|------|------|
| `NSCameraUsageDescription` | "AI职业照需要访问您的相机，以便拍摄证件照并实时检测人脸质量。" | ✅ 通过 | 说明了具体用途（拍摄 + 人脸检测） |
| `NSPhotoLibraryUsageDescription` | "AI职业照需要访问您的相册，以便保存生成的证件照到本地。" | ⚠️ 需优化 | 当前文案仅描述"保存"用途，未覆盖"从相册选择自拍"的读取用途。**建议更新为**："AI职业照需要访问您的相册，以便选择自拍照进行 AI 证件照生成，以及保存生成的证件照到相册。" |
| `NSPhotoLibraryAddUsageDescription` | "AI职业照需要访问您的相册，以便保存生成的证件照到本地。" | ✅ 通过 | 文案合理，说明了保存用途 |
| `ITSAppUsesNonExemptEncryption` | false | ✅ 通过 | 不涉及加密声明免除以外的加密 |

> ⚠️ **重要：建议更新 `NSPhotoLibraryUsageDescription` 文案**，确保同时覆盖读取（选择自拍）和写入（保存证件照）两种用途。当前文案只描述了写入，审核时可能被质疑为什么需要读取相册权限。

---

## 四、中国区 App Store 专项检查

### 4.1 算法备案
- [ ] **已完成算法备案** — 隐私政策中已包含算法备案声明，但实际备案工作需在上线前完成
- [x] 隐私政策中包含 AIGC/深度合成说明
- [x] 隐私政策中包含显著标识说明

### 4.2 数据出境
- [x] 隐私政策明确说明数据不会出境
- [x] 所有云服务商（阿里云、LeanCloud、商汤）均为中国境内服务商

### 4.3 人脸信息保护
- [x] 隐私政策单独章节说明人脸照片处理
- [x] 说明了人脸质量检测为本地处理，不上传原始特征
- [x] 说明了原始照片保留期限（30天自动删除）

### 4.4 未成年人保护
- [x] 隐私政策包含未成年人保护条款
- [ ] **建议：在 App Store 年龄分级中设置为 17+**（因涉及应用内购买）

### 4.5 隐私协议弹窗
- [ ] **建议：首次启动时添加隐私政策同意弹窗**（非强制，但推荐以降低审核风险）

---

## 五、App Store Connect 上传检查清单

### 5.1 应用信息
- [x] 应用标题：AI职业照（6字符，✓ 30字符以内）
- [x] 副标题：AI一键生成精美证件照（11字符，✓ 30字符以内）
- [x] 关键词：70字符（✓ 100字符以内）
- [x] 应用描述：已准备中英文版本
- [x] 支持 URL：待配置有效网址
- [x] 隐私政策 URL：待配置有效网址
- [ ] **需要配置：隐私政策网页**—需将 PRIVACY_POLICY.md 内容部署到可公开访问的 URL

### 5.2 应用审核信息
- [x] 审核备注已准备（含 IAP 产品ID、数据出境说明、算法备案说明）
- [ ] **需要准备：测试账号** — 当前无需登录即可使用，可在审核备注中说明"No login required"
- [ ] **需要准备：测试视频**—建议录制应用使用流程视频（特别是 IAP 流程）
- [ ] **需要准备：测试设备截图**—准备 5-10 张 6.5英寸和 5.5 英寸的应用截图

### 5.3 应用内购买 (IAP)
- [x] 产品ID：com.ai-headshot.hd_unlock
- [x] 类型：一次性消耗型购买
- [x] 审核备注中已说明非订阅
- [ ] **需要配置：在 App Store Connect 中创建对应的 IAP 产品**

### 5.4 隐私标签 (App Privacy)
- [x] 数据类型已在 PrivacyInfo.xcprivacy 中声明
- [x] 不进行跨应用追踪
- [ ] **需要配置：在 App Store Connect 中手动检查隐私标签是否与 PrivacyInfo.xcprivacy 一致**

---

## 六、代码层面审核风险检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 人脸图片上传至云端 | ⚠️ 注意 | 上传的是用户主动选择的自拍照，且用于核心功能，符合规范。但需确保上传过程加密。 |
| IAP 交易验证 | ✅ 正常 | 使用 StoreKit 2 标准流程，验证交易后向后端发送验证请求。 |
| 后端 API 调用 | ✅ 正常 | 使用 HTTPS，服务器位于国内。 |
| 本地人脸检测 | ✅ 正常 | 使用 Apple Vision 本地框架，不上传原始特征。 |
| 用户匿名 ID | ✅ 正常 | 本地生成的 UUID，不涉及真实身份。 |
| 加密声明 | ✅ 正常 | `ITSAppUsesNonExemptEncryption` 设为 false，不需额外申报。 |

---

## 七、未完成事项与行动项

### 高优先级（上线前必须完成）
1. [ ] **部署隐私政策网页**：将 PRIVACY_POLICY.md 内容部署到 `https://ai-headshot.app/privacy`或其他可公开访问的 URL，并填入 App Store Connect
2. [ ] **部署支持网页**：准备 `https://ai-headshot.app/support` 页面
3. [ ] **创建 IAP 产品**：在 App Store Connect 中创建 `com.ai-headshot.hd_unlock` 产品，并配置价格和描述
4. [ ] **更新 Info.plist**：修改 `NSPhotoLibraryUsageDescription` 以覆盖读取和写入双重用途
5. [ ] **算法备案**：确保已按照《互联网信息服务深度合成管理规定》完成备案

### 中优先级（推荐上线前完成）
6. [ ] **准备应用截图**：制作 5-10 张精美应用截图（6.5英寸 iPhone 和 5.5 英寸 iPhone）
7. [ ] **准备应用预览视频**：录制应用使用流程视频（建议 15-30 秒）
8. [ ] **准备审核备注**：填写 App Store Connect 的审核信息字段（参考 APP_STORE_COPY.md）
9. [ ] **设置年龄分级**：建议设置为 17+ 或 12+ (因涉及应用内购买，需根据实际内容评估)
10. [ ] **隐私标签校验**：在 App Store Connect 中验证隐私标签与 PrivacyInfo.xcprivacy 一致

### 低优先级（持续优化）
11. [ ] **添加隐私协议弹窗**：在应用首次启动时展示隐私政策同意弹窗
12. [ ] **填写市场营销 URL**：在 App Store Connect 中填写应用官网链接

---

## 八、风险评估与应对

| 风险点 | 风险等级 | 应对措施 |
|--------|----------|----------|
| 人脸信息传输被质疑 | 中 | 隐私政策已明确说明数据不出境、加密传输、30天删除。审核备注中重点说明。 |
| IAP 审核被拒 | 中 | 应用内购买产品已在代码中明确定义，审核时需在 App Store Connect 中创建对应产品，并提供测试账号或视频。 |
| 隐私政策链接无效 | 中 | 必须上线前部署隐私政策网页并确保可访问。 |
| 算法备案未完成 | 高 | 如未完成备案，可能导致被中国区 App Store 拒绝。需优先完成。 |
| 照片库权限描述不清晰 | 低 | 已在检查清单中标注，修改 Info.plist 即可。 |

---

## 九、结论

本次审核材料准备工作已完成以下内容：

1. **隐私政策文档**：已创建符合中国区法规的简体中英文双语隐私政策，涵盖了人脸信息保护、算法备案、数据出境、未成年人保护等关键要素。
2. **App Store 文案**：已准备完整的上架文案，包括标题、副标题、关键词、中英文描述、版本说明模板和审核备注。
3. **权限说明**：已整理所有权限的用途说明文案，并对 Info.plist 现有配置进行了审查和优化建议。
4. **PrivacyInfo.xcprivacy**：已补充 PhotoLibrary 读取权限声明和 UserDefaults 使用声明，确保与代码实际行为一致。

**剩余必须完成的上线前工作：**
- 部署隐私政策和支持网页
- 修改 Info.plist 中 NSPhotoLibraryUsageDescription 的文案
- 在 App Store Connect 中创建 IAP 产品
- 确保算法备案已完成
- 准备应用截图和预览视频

---

## 附件

- [PRIVACY_POLICY.md](PRIVACY_POLICY.md)
- [APP_STORE_COPY.md](APP_STORE_COPY.md)
- [PERMISSION_DESCRIPTIONS.md](PERMISSION_DESCRIPTIONS.md)
- [PrivacyInfo.xcprivacy](PrivacyInfo.xcprivacy)
