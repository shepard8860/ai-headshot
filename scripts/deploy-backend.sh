#!/usr/bin/env bash
# ============================================================
# AI职业形象照 - 后端生产环境部署脚本
# 用法: ./scripts/deploy-backend.sh
# 说明: 部署到 Cloudflare 生产环境
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${PROJECT_ROOT}/backend/worker"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║         AI职业形象照 - 生产环境部署              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

cd "$BACKEND_DIR"

# 1. 检查 Node.js
if ! command -v node &> /dev/null; then
    err "Node.js 未安装"
    exit 1
fi
ok "Node.js 版本: $(node -v)"

# 2. 检查 npm 依赖
if [ ! -d "node_modules" ]; then
    info "安装依赖..."
    npm ci
fi
ok "依赖已安装"

# 3. 运行类型检查
info "运行 TypeScript 类型检查..."
npm run typecheck
ok "TypeScript 类型检查通过"

# 4. 运行 lint
info "运行 ESLint 代码检查..."
npm run lint
ok "ESLint 检查通过"

# 5. 检查 wrangler 登录状态
info "检查 Cloudflare 登录状态..."
if ! npx wrangler whoami &>/dev/null; then
    warn "未登录 Cloudflare，即将引导登录..."
    npx wrangler login
fi
ok "Cloudflare 已登录"

# 6. 检查生产环境密钥（简单提示）
info "检查生产环境密钥配置..."
warn "请确保以下密钥已通过 'wrangler secret put' 设置:"
echo "  - LEANCLOUD_APP_KEY"
echo "  - SENSENOVA_API_KEY"
echo "  - ALIYUN_ACCESS_KEY_SECRET"
echo "  - APPLE_SHARED_SECRET"
echo "  - ADMIN_PASSWORD"

echo ""
read -rp "确认已配置生产环境密钥并继续部署? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    info "已取消部署"
    exit 0
fi

# 7. 部署
info "开始部署到 Cloudflare 生产环境..."
npx wrangler deploy

ok "部署成功！"
echo ""

# 8. 验证健康检查（尝试获取 Worker URL）
WORKER_URL=$(grep -E '^name\s*=' wrangler.toml | head -1 | sed 's/.*=\s*"\(.*\)".*/\1/')
if [ -n "$WORKER_URL" ]; then
    info "尝试验证健康检查端点..."
    DEPLOYED_URL="https://${WORKER_URL}.workers.dev"
    sleep 3
    if curl -sf "$DEPLOYED_URL/health" &>/dev/null; then
        ok "健康检查通过: $DEPLOYED_URL/health"
    else
        warn "健康检查暂时失败，请手动访问 $DEPLOYED_URL/health 验证"
    fi
fi

echo ""
ok "部署流程完成！"
