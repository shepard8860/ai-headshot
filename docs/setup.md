# 本地开发环境搭建指南

## 前提条件

- macOS 14+ 或 Linux
- Node.js >= 18.0.0
- npm >= 9
- Swift 5.9+ 和 Xcode 15+ (iOS 开发)
- Git

---

## 1. 克隆项目

```bash
git clone <repository-url> ~/AIFactory/projects/ai-headshot
cd ~/AIFactory/projects/ai-headshot
```

---

## 2. 后端 Worker 环境

### 2.1 安装依赖

```bash
cd backend/worker
npm install
```

### 2.2 配置环境变量

复制配置文件：

```bash
cp .dev.vars.example .dev.vars
```

编辑 `.dev.vars`，填充以下字段：

```
LEANCLOUD_APP_ID=your_leancloud_app_id
LEANCLOUD_APP_KEY=your_leancloud_app_key
LEANCLOUD_SERVER_URL=https://your-leancloud-api-server
WECHAT_APP_ID=your_wechat_miniapp_appid
WECHAT_SECRET=your_wechat_miniapp_secret
AI_API_KEY=your_ai_service_api_key
```

### 2.3 本地调试

```bash
npm run dev
# 或
wrangler dev
```

默认服务运行在 `http://localhost:8787`。

### 2.4 代码检查

```bash
npm run typecheck   # TypeScript 类型检查
npm run lint        # ESLint 代码规范检查
```

---

## 3. iOS 环境

### 3.1 构建项目

```bash
cd ios
swift build
```

### 3.2 运行测试

```bash
swift test
```

### 3.3 生成 Xcode 工程（可选）

```bash
swift package generate-xcodeproj
# 或直接在 Xcode 中打开 Package.swift
```

---

## 4. 微信小程序前端

📌 前端代码位于单独的小程序仓库。使用微信开发者工具导入并配置：

1. 微信开发者工具 -> 导入项目
2. 在 `project.config.json` 中填写 `appid`
3. 在工具设置中开启“不校验合法域名”（本地开发时）
4. 修改 `config.js` 中的 API 基础地址为本地 Worker 地址

---

## 5. 数据库初始化

1. 登录 LeanCloud 控制台
2. 创建应用并获取 App ID / App Key
3. 在控制台创建以下 Class：`Order`、`Template`、`UserProfile`、`PaymentRecord`、`Feedback`
4. 导入模板数据：使用 `scripts/import-templates.js` 将 `design/templates/` 下的 JSON 导入 LeanCloud

```bash
cd scripts
node import-templates.js
```

---

## 6. 常见问颜排查

| 问颜 | 解决方案 |
|------|----------|
| `wrangler` 命令不存在 | `npm install -g wrangler` 或使用 `npx wrangler` |
| `swift build` 失败 | 确认已安装 Xcode Command Line Tools: `xcode-select --install` |
| TypeScript 类型错误 | 运行 `npm run typecheck` 排查完整错误信息 |
| LeanCloud 连接失败 | 检查 `.dev.vars` 中的 `LEANCLOUD_SERVER_URL` 是否正确 |
| 小程序无法调用本地 API | 确认开发者工具已开启“不校验合法域名”，并检查端口号 |

---

## 7. 项目目录结构

```
ai-headshot/
├── backend/
│   └── worker/          # Cloudflare Worker 后端服务
├── design/
│   └── templates/       # AI 模板 JSON 配置
├── docs/                # 项目文档
├── ios/                 # iOS SDK / 应用
├── scripts/             # 辅助脚本
└── ...
```
