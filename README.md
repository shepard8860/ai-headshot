# AI职业形象照 (AI Headshot)

> 基于多模态AI技术的职业形象照生成服务。用户上传自拍，AI自动融合专业模板，生成适用于LinkedIn、简历、名片等场景的高质量职业形象照。支持 iOS App 和 RESTful API。

---

## ✨ 功能特点

- **28种专业模板** — 覆盖商务正装、科技互联网、创意设计、教育培训、医疗健康、法律政府、销售市场七大行业
- **AI智能融合** — 基于商汤 SenseNova / 阿里云通义万相，精准融合用户自拍与专业摄影模板
- **人脸质量检测** — 实时检测自拍光线、角度、遮挡，确保合成效果
- **多端支持** — iOS App + RESTful API，可扩展微信小程序
- **云端无服务器架构** — 基于 Cloudflare Workers，全球边缘部署，低延迟高可用
- **安全支付** — 集成 Apple App Store IAP，支持应用内购买
- **实时进度推送** — SSE 流式推送生成进度，用户体验流畅

---

## 📁 目录结构

```
ai-headshot/
├── backend/
│   ├── worker/              # Cloudflare Worker 后端服务 (TypeScript + Hono)
│   └── api-test/            # API 接口测试脚本
├── design/
│   ├── templates/           # 28个职业照模板 JSON 配置
│   └── template-images/     # AI生成的模板底图（由脚本批量生成）
├── docs/
│   ├── setup.md             # 本地开发环境搭建指南
│   ├── deployment.md        # 上线部署清单
│   ├── api-reference.md     # API 接口文档
│   └── database-schema.md   # 数据库表结构说明
├── ios/
│   ├── Sources/AIHeadshot/  # iOS App Swift 源码
│   ├── Tests/               # 单元测试
│   └── Package.swift        # Swift Package Manager 配置
├── scripts/
│   ├── setup-mac-dev.sh     # Mac 开发环境一键安装
│   ├── configure.sh         # 交互式环境变量配置
│   ├── run-backend-local.sh # 后端本地运行
│   ├── deploy-backend.sh    # 后端生产部署
│   ├── init-leancloud.js    # LeanCloud 数据库初始化
│   ├── generate-template-images.py  # 模板底图批量生成
│   └── generate-prompts.md  # 28个模板的手写优化 Prompt
├── Makefile                 # 常用命令快捷入口
└── README.md                # 本文件
```

---

## 🚀 快速开始

### 环境准备

**macOS 用户** 可一键安装所有依赖：

```bash
bash scripts/setup-mac-dev.sh
```

该脚本会自动检查并安装：Xcode Command Line Tools、Homebrew、Node.js (>=18)、Wrangler CLI、SwiftLint。

**手动安装要求：**

- macOS 14+ 或 Linux
- Node.js >= 18.0.0
- npm >= 9
- Swift 5.9+ 和 Xcode 15+ (iOS 开发)
- Git

### 配置环境变量

```bash
# 1. 复制环境变量模板
cp scripts/env.template backend/worker/.dev.vars

# 2. 编辑 .dev.vars，填入你的 API Key
#   - LeanCloud App ID / App Key
#   - 商汤 SenseNova API Key
#   - 阿里云 AccessKey ID / Secret
#   - Apple Shared Secret (IAP)
```

完整环境变量清单见下方 [🔐 环境变量清单](#-环境变量清单)。

### 初始化项目

```bash
make setup
```

该命令会：
1. 安装后端依赖 (`npm install`)
2. 验证 TypeScript 类型
3. 安装 iOS 依赖 (`swift package resolve`)
4. 设置脚本可执行权限

### 启动后端本地开发服务

```bash
make backend-dev
```

或直接使用脚本：

```bash
bash scripts/run-backend-local.sh
```

服务默认运行在 `http://localhost:8787`。

常用后端命令：

| 命令 | 说明 |
|------|------|
| `make backend-dev` | 启动本地开发服务 |
| `make lint` | TypeScript 类型检查 + ESLint |
| `make test` | 运行测试套件 |
| `make deploy` | 部署到 Cloudflare 生产环境 |

### 初始化数据库

```bash
make leancloud-init
```

此命令会创建 LeanCloud 所需的 Class：`Order`、`Template`、`UserProfile`、`PaymentRecord`、`Feedback`，并导入模板数据。

### iOS 构建与运行

```bash
# 进入 iOS 目录
cd ios

# 编译项目
swift build

# 运行测试
swift test

# 代码风格检查
swiftlint
```

**在 Xcode 中运行：**

1. 打开 `ios/Package.swift` 或生成 Xcode 工程
2. 选择目标设备（iOS 16+ 模拟器或真机）
3. 按 `Cmd+R` 运行

构建命令速查：

| 命令 | 说明 |
|------|------|
| `cd ios && swift build` | 编译 iOS 项目 |
| `cd ios && swift test` | 运行 iOS 单元测试 |
| `make ios-build` | 通过 Makefile 构建 |

---

## 🔐 环境变量清单

| 变量名 | 说明 | 获取方式 |
|--------|------|----------|
| `LEANCLOUD_APP_ID` | LeanCloud 应用 ID | [leancloud.cn](https://leancloud.cn) → 创建应用 → 设置 → 应用凭证 |
| `LEANCLOUD_APP_KEY` | LeanCloud 应用 Key | 同上 |
| `LEANCLOUD_SERVER_URL` | LeanCloud API 服务地址 | 同上 |
| `SENSENOVA_API_KEY` | 商汤 SenseNova API Key | [platform.sensenova.cn](https://platform.sensenova.cn) |
| `ALIYUN_ACCESS_KEY_ID` | 阿里云 AccessKey ID | [RAM 控制台](https://ram.console.aliyun.com) |
| `ALIYUN_ACCESS_KEY_SECRET` | 阿里云 AccessKey Secret | 同上 |
| `ALIYUN_OSS_ENDPOINT` | OSS 服务端点 | 例如 `oss-cn-beijing.aliyuncs.com` |
| `ALIYUN_OSS_BUCKET` | OSS 存储桶名称 | 阿里云 OSS 控制台 |
| `ALIYUN_WANXI_API_URL` | 通义万相 API 地址 | `https://dashscope.aliyuncs.com/api/v1` |
| `APPLE_SHARED_SECRET` | Apple IAP 共享密钥 | App Store Connect → 功能 → App 内购买项目 → 共享密钥 |
| `ADMIN_USERNAME` | 管理后台用户名 | 自行设置 |
| `ADMIN_PASSWORD` | 管理后台密码 | 自行设置（生产环境建议用 wrangler secret） |
| `HEADSHOT_KV` | Cloudflare KV Namespace ID | Cloudflare Dashboard → Workers & Pages → KV |

---

## 🖼️ 模板底图批量生成

项目提供 `scripts/generate-template-images.py` 脚本，可调用 Replicate / Stability AI / 本地 WebUI 批量生成 28 张模板底图。

```bash
# 使用 Replicate (推荐, 默认使用 flux-schnell)
export REPLICATE_API_TOKEN="r8_xxxx"
python3 scripts/generate-template-images.py --provider replicate

# 使用 Stability AI
export STABILITY_API_KEY="sk-xxxx"
python3 scripts/generate-template-images.py --provider stability

# 使用本地 Stable Diffusion WebUI
python3 scripts/generate-template-images.py --provider webui

# 仅打印 Prompt 不实际调用（Dry Run）
python3 scripts/generate-template-images.py --dry-run

# 指定生成某个模板
python3 scripts/generate-template-images.py --template-id business_linkedin_001

# 重试之前失败的模板
python3 scripts/generate-template-images.py --retry-failed
```

特性：
- **断点续传**：通过 `design/.generate-progress.json` 记录进度，中断后可继续
- **无人脸设计**：Prompt 中强制要求 `face turned away, no facial features visible`，确保底图无人脸，供后续用户自拍融合
- **命名规范**：输出文件为 `{template_id}.jpg`
- **尺寸支持**：默认 1024x1024，可通过 `--width` / `--height` 调整

同时提供了 `scripts/generate-prompts.md`，内含 28 个模板的手写优化英文 Prompt，可直接粘贴到 Midjourney / Stable Diffusion WebUI / ComfyUI 手动生成。

---

## 📦 部署

### 后端部署到 Cloudflare

```bash
make deploy
```

或手动执行：

```bash
cd backend/worker
npm run deploy
```

部署前请确保：
1. `wrangler.toml` 中的配置正确
2. 生产环境密钥已通过 `wrangler secret put` 设置
3. LeanCloud 生产环境数据库已初始化

### iOS 发布

1. 在 Xcode 中配置签名证书和 Bundle ID
2. 更新 `ios/Sources/AIHeadshot/Utils/Constants.swift` 中的 API 基础地址为生产环境
3. 构建 Release 版本并上传至 App Store Connect

详细部署清单请参考 [docs/deployment.md](docs/deployment.md)。

---

## 📚 文档

| 文档 | 说明 |
|------|------|
| [docs/setup.md](docs/setup.md) | 本地开发环境详细搭建指南 |
| [docs/deployment.md](docs/deployment.md) | 上线部署清单与回滚方案 |
| [docs/api-reference.md](docs/api-reference.md) | RESTful API 接口文档 |
| [docs/database-schema.md](docs/database-schema.md) | LeanCloud 数据库表结构 |
| [scripts/generate-prompts.md](scripts/generate-prompts.md) | 28个模板AI生成Prompt手册 |

---

## 🤝 贡献指南

我们欢迎所有形式的贡献，包括但不限于：

- **Bug 修复**：提交 Issue 描述问题，或直接在 PR 中修复
- **新模板**：在 `design/templates/` 中添加新的职业照模板 JSON
- **功能增强**：优化 AI 融合算法、提升 iOS 交互体验
- **文档改进**：补充或修正文档中的错误和缺失

### 提交规范

1. **Fork 本仓库** 并创建你的特性分支：`git checkout -b feature/my-feature`
2. **确保代码通过检查**：`make lint`
3. **提交更改**：使用清晰的 commit message，例如 `feat: add healthcare template`
4. **推送到分支**：`git push origin feature/my-feature`
5. **创建 Pull Request**：描述变更内容和测试方式

### 代码风格

- **后端**：TypeScript，使用项目配置的 ESLint 规则
- **iOS**：Swift，遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)，使用 SwiftLint 检查
- **脚本**：Python 3 / Bash，保持可读性和错误处理

---

## 📄 License

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 💬 联系方式

如有问题或建议，欢迎通过以下方式联系：

- 提交 [Issue](https://github.com/your-org/ai-headshot/issues)
- 发送邮件至：`dev@ai-headshot.example.com`

---

> **提示**：本项目为学习和演示用途，实际部署时请妥善保管 API Key 和密钥，遵守各平台的使用条款。
