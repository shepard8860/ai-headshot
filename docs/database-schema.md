# 数据库 Schema 设计

> 本项目使用 **LeanCloud** 作为后端数据库。以下为各 Class 的字段定义、索引与关系说明。

---

## 1. Order 订单表

存储用户生成订单的全生命周期信息。

| 字段名 | 类型 | 是否必填 | 默认值 | 索引 | 说明 |
|--------|------|----------|--------|------|------|
| `objectId` | String | 是 | 自增 | Primary | LeanCloud 默认主键 |
| `orderNo` | String | 是 | - | Unique | 业务订单号，格式 `AH-YYYYMMDD-XXXXXX` |
| `userId` | String | 是 | - | Index | 用户唯一标识（微信 openId 或 UUID） |
| `templateId` | String | 是 | - | Index | 所选模板 ID |
| `status` | String | 是 | `pending` | Index | 订单状态：pending / paid / processing / completed / failed / refunded |
| `amount` | Number | 是 | 0 | - | 订单金额（分） |
| `originalPhotoUrl` | String | 是 | - | - | 用户上传的原始照片 URL |
| `resultPhotoUrl` | String | 否 | - | - | AI 生成结果图片 URL |
| `paymentMethod` | String | 否 | - | - | 支付方式：weixin / alipay |
| `transactionId` | String | 否 | - | Index | 第三方支付平台流水号 |
| `failReason` | String | 否 | - | - | 失败原因记录 |
| `createdAt` | Date | 是 | 当前时间 | Index | 创建时间 |
| `updatedAt` | Date | 是 | 当前时间 | Index | 更新时间 |
| `paidAt` | Date | 否 | - | - | 支付完成时间 |
| `completedAt` | Date | 否 | - | - | 生成完成时间 |

### ACL 权限
- 用户只可读取 / 写入自己的订单
- 管理员可读取全部订单

---

## 2. Template 模板表

存储 AI 形象照模板配置，与 `design/templates/` 下的 JSON 文件对应。

| 字段名 | 类型 | 是否必填 | 默认值 | 索引 | 说明 |
|--------|------|----------|--------|------|------|
| `objectId` | String | 是 | 自增 | Primary | 主键 |
| `templateId` | String | 是 | - | Unique | 模板唯一标识，如 `business_linkedin_001` |
| `name` | String | 是 | - | - | 模板名称 |
| `category` | String | 是 | - | Index | 分类名称，如 `商务正装` |
| `categoryId` | String | 是 | - | Index | 分类 ID，如 `business_formal` |
| `description` | String | 否 | - | - | 模板描述 |
| `stylePrompt` | String | 是 | - | - | 风格 Prompt |
| `backgroundPrompt` | String | 是 | - | - | 背景 Prompt |
| `clothingPrompt` | String | 是 | - | - | 服装 Prompt |
| `lightingPrompt` | String | 是 | - | - | 光线 Prompt |
| `colorTone` | String | 否 | - | - | 色调描述 |
| `previewImageUrl` | String | 是 | - | - | 预览图地址 |
| `isActive` | Boolean | 是 | true | Index | 是否上架 |
| `sortOrder` | Number | 是 | 0 | - | 排序值 |
| `createdForGender` | String | 否 | `unisex` | Index | 适用性别：male / female / unisex |
| `createdAt` | Date | 是 | 当前时间 | - | 创建时间 |
| `updatedAt` | Date | 是 | 当前时间 | - | 更新时间 |

### ACL 权限
- 全部用户可读
- 仅管理员可写入

---

## 3. UserProfile 用户信息表

轻量级用户信息，与微信登录对应。

| 字段名 | 类型 | 是否必填 | 默认值 | 索引 | 说明 |
|--------|------|----------|--------|------|------|
| `objectId` | String | 是 | 自增 | Primary | 主键 |
| `userId` | String | 是 | - | Unique | 用户唯一标识 |
| `unionId` | String | 否 | - | Index | 微信 unionId |
| `nickName` | String | 否 | - | - | 微信昵称 |
| `avatarUrl` | String | 否 | - | - | 头像地址 |
| `phone` | String | 否 | - | - | 手机号（解密存储） |
| `gender` | Number | 否 | 0 | - | 性别：0未知 / 1男 / 2女 |
| `province` | String | 否 | - | - | 省份 |
| `city` | String | 否 | - | - | 城市 |
| `totalOrders` | Number | 是 | 0 | - | 累计订单数 |
| `totalSpent` | Number | 是 | 0 | - | 累计消费金额（分） |
| `vipLevel` | Number | 是 | 0 | Index | VIP 等级 |
| `createdAt` | Date | 是 | 当前时间 | - | 注册时间 |
| `updatedAt` | Date | 是 | 当前时间 | - | 更新时间 |
| `lastLoginAt` | Date | 否 | - | - | 最后登录时间 |

### ACL 权限
- 用户只可读取 / 写入自己的资料
- 管理员可读取全部

---

## 4. PaymentRecord 支付记录表

独立存储支付流水，便于财务对账。

| 字段名 | 类型 | 是否必填 | 默认值 | 索引 | 说明 |
|--------|------|----------|--------|------|------|
| `objectId` | String | 是 | 自增 | Primary | 主键 |
| `orderNo` | String | 是 | - | Index | 关联订单号 |
| `userId` | String | 是 | - | Index | 用户 ID |
| `amount` | Number | 是 | 0 | - | 支付金额（分） |
| `channel` | String | 是 | - | Index | 支付渠道：weixin / alipay |
| `transactionId` | String | 是 | - | Unique | 第三方流水号 |
| `status` | String | 是 | `pending` | Index | 支付状态：pending / success / failed / closed |
| `prepayId` | String | 否 | - | - | 微信预支付 ID |
| `paidAt` | Date | 否 | - | - | 实际支付时间 |
| `notifyRaw` | Object | 否 | - | - | 第三方支付回调原始数据 |
| `createdAt` | Date | 是 | 当前时间 | - | 创建时间 |
| `updatedAt` | Date | 是 | 当前时间 | - | 更新时间 |

### ACL 权限
- 仅服务端可写入
- 管理员可查看

---

## 5. Feedback 用户反馈表

收集用户对生成结果的反馈。

| 字段名 | 类型 | 是否必填 | 默认值 | 索引 | 说明 |
|--------|------|----------|--------|------|------|
| `objectId` | String | 是 | 自增 | Primary | 主键 |
| `userId` | String | 是 | - | Index | 用户 ID |
| `orderNo` | String | 否 | - | Index | 关联订单号 |
| `templateId` | String | 否 | - | - | 模板 ID |
| `rating` | Number | 否 | - | - | 评分 1-5 |
| `comment` | String | 否 | - | - | 文字反馈 |
| `issueType` | String | 否 | - | Index | 问颜类型：face_distortion / clothing_error / background_issue / color_problem / other |
| `contactEmail` | String | 否 | - | - | 联系邮箱 |
| `isResolved` | Boolean | 是 | false | Index | 是否已处理 |
| `createdAt` | Date | 是 | 当前时间 | - | 提交时间 |
| `updatedAt` | Date | 是 | 当前时间 | - | 更新时间 |

### ACL 权限
- 用户可提交自己的反馈
- 管理员可查看所有反馈

---

## 关系图

```
UserProfile (1) ----< (N) Order
Order (1) ----< (N) PaymentRecord
Order (1) ----< (1) Feedback
Template (1) ----< (N) Order  (通过 templateId 关联)
```

## 索引建议

| Class | 复合索引 | 场景 |
|-------|----------|------|
| Order | `userId` + `status` | 查询用户指定状态订单 |
| Order | `createdAt` DESC | 后台订单列表排序 |
| Template | `categoryId` + `isActive` | 按分类查询上架模板 |
| PaymentRecord | `orderNo` + `status` | 订单支付状态查询 |
| Feedback | `issueType` + `isResolved` | 后台问题跟踪 |

## 安全提示

1. 所有涉及金额的字段单位为 **分**，避免浮点误差。
2. `phone` 字段建议使用 LeanCloud 自带加解密功能或应用层加密。
3. `notifyRaw` 仅用于异常排查，不建议在业务逻辑中直接依赖。
