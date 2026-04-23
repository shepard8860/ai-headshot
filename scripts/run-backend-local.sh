#!/usr/bin/env bash
# ============================================================
# AI职业形象照 - 后端本地运行脚本
# 用法: ./scripts/run-backend-local.sh
# 说明: 检查环境、安装依赖、启动 wrangler dev
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
info "检查运行环境..."

# 1. 检查 Node.js
if ! command -v node &> /dev/null; then
    err "Node.js 未安装，请先安装 Node.js >= 18"
    exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//')
MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$MAJOR" -lt 18 ]; then
    err "Node.js 版本 $NODE_VERSION 不满足要求，需要 >= 18"
    exit 1
fi
ok "Node.js 版本: v${NODE_VERSION}"

# 2. 检查 npm
if ! command -v npm &> /dev/null; then
    err "npm 未安装"
    exit 1
fi
ok "npm 版本: $(npm -v)"

# 3. 检查 wrangler
cd "$BACKEND_DIR"

if [ ! -f "node_modules/.bin/wrangler" ]; then
    info "wrangler 未安装，即将自动安装依赖..."
    npm install
    ok "依赖安装完成"
else
    ok "wrangler 已安装: $(npx wrangler --version 2>/dev/null | head -1 || true)"
fi

# 4. 检查 .dev.vars
if [ ! -f ".dev.vars" ]; then
    warn ".dev.vars 配置文件不存在"
    if [ -f "../../scripts/env.template" ]; then
        info "已找到环境变量模板，请先运行: ../../scripts/configure.sh"
    fi
    exit 1
fi
ok ".dev.vars 配置文件已存在"

# 5. 检查 wrangler.toml
if [ ! -f "wrangler.toml" ]; then
    err "wrangler.toml 不存在，请确认后端目录结构正确"
    exit 1
fi
ok "wrangler.toml 已存在"

# 6. 运行 TypeScript 类型检查
info "运行 TypeScript 类型检查..."
if npm run typecheck 2>/dev/null; then
    ok "TypeScript 类型检查通过"
else
    warn "TypeScript 类型检查未通过，仍然启动服务..."
fi

# 7. 启动 wrangler dev
echo ""
info "启动 Cloudflare Worker 本地开发服务..."
ok "将运行于 http://localhost:8787"
echo ""

exec npx wrangler dev --local --port 8787
