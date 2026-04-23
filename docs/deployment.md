# 上线部署清单

## 检查项清单

### □ 环境准备

- [ ] 注册微信小程序并获取 `appid` 和 `appsecret`
- [ ] 注册 LeanCloud 并创建生产环境应用
- [ ] 注册域名并配置 DNS 解析到 Cloudflare
- [ ] 准备支付商户号（微信支付企业版）
- [ ] 准备 AI 图像生成服务 API Key

### □ 后端部署

- [ ] 配置 `wrangler.toml` 生产环境变量
- [ ] 配置 LeanCloud 生产环境 App ID / App Key
- [ ] 配置微信支付商户号和 API 密钥
- [ ] 部署 Cloudflare Worker: `npm run deploy`
- [ ] 配置微信支付回调 URL 到生产环境
- [ ] 验证 API 健康检查端点
- [ ] 配置 Cloudflare Analytics 和 Logs

### □ 数据库初始化

- [ ] 在 LeanCloud 控制台创建所有 Class（Order、Template、UserProfile、PaymentRecord、Feedback）
- [ ] 配置各 Class 的 ACL 权限
- [ ] 创建必要的单列索引（orderNo、userId、status等）
- [ ] 导入模板数据到 Template Class
- [ ] 验证模板数据完整性

### □ 小程序发布

- [ ] 更新小程序 `project.config.json` 中的 `appid`
- [ ] 更新 API 基础地址为生产环境
- [ ] 上传小程序代码并提交审核
- [ ] 配置小程序后台服务器域名白名单
- [ ] 配置小程序上传接口地址
- [ ] 完成小程序审核并发布

### □ iOS 应用（如适用）

- [ ] 配置 Xcode 签名和证书
- [ ] 更新 API 基础地址为生产环境
- [ ] 构建 Release 版本
- [ ] 上传 App Store Connect
- [ ] 填写 App Store 元数据并提交审核

### □ CDN 与资源

- [ ] 上传模板预览图片到 CDN
- [ ] 确认图片 URL 可正常访问
- [ ] 配置图片上传存储桶 / R2 存储
- [ ] 配置图片访问限速和过期策略

### □ 监控与运维

- [ ] 配置 Cloudflare Worker 日志转储
- [ ] 配置 LeanCloud 异常告警
- [ ] 配置支付流水监控
- [ ] 配置 AI 生成容量和成本预算
- [ ] 制定容量扩展方案

---

## 关键配置文件一览

| 文件 | 位置 | 说明 |
|------|------|------|
| `wrangler.toml` | `backend/worker/` | Worker 部署配置 |
| `.dev.vars` | `backend/worker/` | 本地环境变量 |
| `wrangler secret` | Cloudflare 控制台 | 生产环境密钥 |
| LeanCloud 控制台 | 线上 | Class 管理、ACL、索引 |
| 微信小程序后台 | mp.weixin.qq.com | 小程序配置、域名白名单、支付回调 |
| App Store Connect | appstoreconnect.apple.com | iOS 应用发布管理 |

---

## 回滚方案

1. **Worker 回滚**: 使用 `wrangler rollback` 或在 Cloudflare 控制台上线之前版本。
2. **数据库回滚**: 利用 LeanCloud 定时备份功能进行数据恢复。
3. **小程序回滚**: 提交旧版本代码并重新发布。
4. **紧急关停**: 在 LeanCloud 控制台临时禁用敏感 API。

---

## 测试验证

部署完成后执行以下验证：

```bash
# 1. 健康检查
curl https://api.your-domain.com/health

# 2. 获取模板列表
curl https://api.your-domain.com/api/templates

# 3. 测试订单创建（需登录 Token）
curl -X POST https://api.your-domain.com/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"templateId":"business_linkedin_001","photoUrl":"..."}'

# 4. 支付回调测试（确保签名验证通过）
```

---

## 联系人

- **技术联系人**: 后端开发团队
- **运营联系人**: 产品/运营团队
- **紧急响应**: 24h 内响应生产故障
