# API 接口文档

> 基础地址：`https://api.your-domain.com` 或本地调试 `http://localhost:8787`
>
> 所有接口返回 JSON，统一格式如下：

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

错误时 `code ≠ 0`，`message` 携带错误说明。

---

## 认证

微信小程序通过 `x-wx-code` 头部传递 `wx.login()` 获取的 `code`。

```http
x-wx-code: xxxxxx
```

---

## 1. 模板接口

### GET /api/templates

获取模板列表。

**请求参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `categoryId` | string | 否 | 按分类筛选，如 `business_formal` |
| `gender` | string | 否 | 按性别筛选：male / female / unisex |

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [
      {
        "templateId": "business_linkedin_001",
        "name": "标准LinkedIn形象照",
        "category": "商务正装",
        "categoryId": "business_formal",
        "previewImageUrl": "https://cdn.example.com/...",
        "description": "...",
        "colorTone": "...",
        "isActive": true,
        "sortOrder": 1,
        "createdForGender": "unisex"
      }
    ]
  }
}
```

### GET /api/templates/:id

获取单个模板详情。

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "templateId": "business_linkedin_001",
    "name": "标准LinkedIn形象照",
    "category": "商务正装",
    "description": "...",
    "stylePrompt": "...",
    "backgroundPrompt": "...",
    "clothingPrompt": "...",
    "lightingPrompt": "...",
    "colorTone": "...",
    "previewImageUrl": "...",
    "isActive": true,
    "sortOrder": 1,
    "createdForGender": "unisex"
  }
}
```

---

## 2. 订单接口

### POST /api/orders

创建订单。

**请求体**

```json
{
  "templateId": "business_linkedin_001",
  "photoUrl": "https://cdn.example.com/upload/xxx.jpg"
}
```

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "orderNo": "AH-20260423-000001",
    "status": "pending",
    "amount": 990,
    "createdAt": "2026-04-23T05:47:00Z"
  }
}
```

### GET /api/orders

查询用户订单列表。

**请求参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string | 否 | 筛选状态 |
| `page` | number | 否 | 页码，默认1 |
| `pageSize` | number | 否 | 每页数量，默认10 |

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [
      {
        "orderNo": "AH-20260423-000001",
        "templateId": "business_linkedin_001",
        "status": "completed",
        "amount": 990,
        "originalPhotoUrl": "...",
        "resultPhotoUrl": "...",
        "createdAt": "2026-04-23T05:47:00Z",
        "completedAt": "2026-04-23T05:52:00Z"
      }
    ],
    "total": 5,
    "page": 1,
    "pageSize": 10
  }
}
```

### GET /api/orders/:orderNo

查询单个订单详情。

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "orderNo": "AH-20260423-000001",
    "templateId": "business_linkedin_001",
    "status": "completed",
    "amount": 990,
    "originalPhotoUrl": "...",
    "resultPhotoUrl": "...",
    "failReason": null,
    "createdAt": "2026-04-23T05:47:00Z",
    "paidAt": "2026-04-23T05:48:00Z",
    "completedAt": "2026-04-23T05:52:00Z"
  }
}
```

---

## 3. 支付接口

### POST /api/payments/prepay

创建微信支付预支付单。

**请求体**

```json
{
  "orderNo": "AH-20260423-000001"
}
```

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "appId": "wx1234567890",
    "timeStamp": "1713848820",
    "nonceStr": "random_string",
    "package": "prepay_id=wx202404231234567890",
    "signType": "RSA",
    "paySign": "..."
  }
}
```

### POST /api/payments/notify

微信支付异步回调（微信服务器调用）。

**请求体**

微信支付统一的 XML/JSON 回调数据。

**响应**

返回微信标准回复：

```xml
<xml>
  <return_code><![CDATA[SUCCESS]]></return_code>
  <return_msg><![CDATA[OK]]></return_msg>
</xml>
```

---

## 4. 用户接口

### POST /api/users/login

微信登录。

**请求体**

```json
{
  "code": "wx_login_code_from_miniapp"
}
```

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "userId": "u_xxxxxxxx",
    "token": "jwt_token_string",
    "nickName": "微信用户",
    "avatarUrl": "...",
    "isNewUser": true
  }
}
```

### GET /api/users/profile

获取当前用户信息。

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "userId": "u_xxxxxxxx",
    "nickName": "微信用户",
    "avatarUrl": "...",
    "phone": "138****8888",
    "gender": 1,
    "totalOrders": 5,
    "totalSpent": 4950,
    "vipLevel": 0
  }
}
```

---

## 5. 反馈接口

### POST /api/feedback

提交反馈。

**请求体**

```json
{
  "orderNo": "AH-20260423-000001",
  "templateId": "business_linkedin_001",
  "rating": 4,
  "comment": "整体不错，背景颜色可以更自然一点",
  "issueType": "background_issue",
  "contactEmail": "user@example.com"
}
```

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "feedbackId": "fb_xxxxxxxx",
    "createdAt": "2026-04-23T06:00:00Z"
  }
}
```

---

## 6. 上传接口

### POST /api/upload/presign

获取上传预签名地址。

**请求体**

```json
{
  "fileName": "photo.jpg",
  "fileType": "image/jpeg",
  "fileSize": 2048000
}
```

**响应示例**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "uploadUrl": "https://upload.example.com/...",
    "fileUrl": "https://cdn.example.com/...",
    "headers": {
      "Content-Type": "image/jpeg"
    }
  }
}
```

---

## 错误码定义

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 40001 | 参数错误 |
| 40002 | 订单不存在 |
| 40003 | 模板不存在或已下架 |
| 40004 | 支付已完成或订单状态异常 |
| 40101 | 未登录或 Token 无效 |
| 40102 | 微信登录失败 |
| 40301 | 无权访问 |
| 50001 | 服务器内部错误 |
| 50002 | AI 生成服务异常 |
| 50003 | 支付平台调用失败 |
