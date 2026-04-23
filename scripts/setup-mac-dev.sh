#!/usr/bin/env bash
# ============================================================
# AI职业形象照 - Mac 开发环境一键安装脚本
# 用法: bash scripts/setup-mac-dev.sh
# 说明: 检查并安装必要开发工具，已安装则自动跳过
# ============================================================

set -uo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

info() { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }
step() { echo -e "\n${BLUE}${BOLD}▶ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════╗"
echo -e "${BOLD}║       AI职业形象照 - Mac 开发环境一键安装       ║"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════╝"
echo ""

# --------------------------------------------------
# 1. 检查操作系统
# --------------------------------------------------
if [[ "$OSTYPE" != "darwin"* ]]; then
    err "本脚本仅支持 macOS 系统"
    exit 1
fi

ok "检测到 macOS 系统 ($(sw_vers -productVersion))"

# --------------------------------------------------
# 2. Xcode Command Line Tools
# --------------------------------------------------
step "检查 Xcode Command Line Tools"

if xcode-select -p &>/dev/null && [[ -d "$(xcode-select -p)" ]]; then
    ok "Xcode Command Line Tools 已安装 ($(/usr/bin/xcodebuild -version 2>/dev/null | head -1 || true))"
else
    info "未检测到 Xcode Command Line Tools，即将安装..."
    info "请按提示点击弹窗中的 ‘安装’ 按钮..."
    xcode-select --install 2>/dev/null || true
    warn "请等待 Xcode Command Line Tools 安装完成后，重新运行本脚本"
    exit 0
fi

# --------------------------------------------------
# 3. Homebrew
# --------------------------------------------------
step "检查 Homebrew"

if command -v brew &>/dev/null; then
    ok "Homebrew 已安装 ($(brew --version | head -1))"
    info "更新 Homebrew..."
    brew update >/dev/null 2>&1 || warn "brew update 失败"
else
    info "未检测到 Homebrew，即将安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 配置 Homebrew 环境变量
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if command -v brew &>/dev/null; then
        ok "Homebrew 安装成功"
    else
        err "Homebrew 安装失败，请手动安装: https://brew.sh"
        exit 1
    fi
fi

# --------------------------------------------------
# 4. Node.js
# --------------------------------------------------
step "检查 Node.js"

if command -v node &>/dev/null; then
    NODE_VERSION=$(node -v | sed 's/v//')
    MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
    if [[ "$MAJOR" -ge 18 ]]; then
        ok "Node.js 已安装 (v${NODE_VERSION})"
    else
        warn "Node.js 版本 v${NODE_VERSION} 过低，需要 >= 18"
        info "即将通过 Homebrew 升级 Node.js..."
        brew upgrade node || brew install node
        ok "Node.js 已升级至 $(node -v)"
    fi
else
    info "未检测到 Node.js，即将通过 Homebrew 安装..."
    brew install node
    if command -v node &>/dev/null; then
        ok "Node.js 安装成功 ($(node -v))"
    else
        err "Node.js 安装失败"
        exit 1
    fi
fi

# 确保 npm 也已安装
if command -v npm &>/dev/null; then
    ok "npm 已安装 (v$(npm -v))"
else
    err "npm 未安装，请检查 Node.js 安装"
    exit 1
fi

# --------------------------------------------------
# 5. Wrangler CLI
# --------------------------------------------------
step "检查 Wrangler CLI"

if command -v wrangler &>/dev/null; then
    ok "Wrangler CLI 已安装 ($(wrangler --version 2>/dev/null | head -1 || true))"
else
    info "未检测到 Wrangler CLI，即将通过 npm 全局安装..."
    npm install -g wrangler
    if command -v wrangler &>/dev/null; then
        ok "Wrangler CLI 安装成功"
    else
        err "Wrangler CLI 安装失败"
        exit 1
    fi
fi

# --------------------------------------------------
# 6. SwiftLint
# --------------------------------------------------
step "检查 SwiftLint"

if command -v swiftlint &>/dev/null; then
    ok "SwiftLint 已安装 ($(swiftlint --version 2>/dev/null || true))"
else
    info "未检测到 SwiftLint，即将通过 Homebrew 安装..."
    brew install swiftlint
    if command -v swiftlint &>/dev/null; then
        ok "SwiftLint 安装成功"
    else
        warn "SwiftLint 安装失败，iOS 代码风格检查将不可用"
    fi
fi

# --------------------------------------------------
# 7. Swift 工具链（Xcode 开发工具）
# --------------------------------------------------
step "检查 Swift 工具链"

if command -v swift &>/dev/null; then
    SWIFT_VERSION=$(swift --version 2>/dev/null | head -1 || true)
    ok "Swift 已安装 (${SWIFT_VERSION})"
else
    warn "Swift 工具链未找到"
    warn "如需构建 iOS 项目，请安装 Xcode 并运行: xcode-select --install"
fi

# --------------------------------------------------
# 8. 可选工具检查
# --------------------------------------------------
step "检查可选工具"

if command -v git &>/dev/null; then
    ok "Git 已安装 ($(git --version))"
else
    info "未检测到 Git，即将安装..."
    brew install git
    ok "Git 安装成功"
fi

if command -v curl &>/dev/null; then
    ok "curl 已安装"
fi

# --------------------------------------------------
# 9. 项目初始化提示
# --------------------------------------------------
step "环境检查完成"

echo ""
echo -e "${GREEN}${BOLD}✅ Mac 开发环境准备就绪！${NC}"
echo ""
echo -e "${BOLD}接下来可以执行以下操作：${NC}"
echo ""
echo "  1. 配置环境变量:"
echo "     cp scripts/env.template backend/worker/.dev.vars"
echo "     编辑 backend/worker/.dev.vars 填入你的 API Key"
echo ""
echo "  2. 初始化项目:"
echo "     make setup"
echo ""
echo "  3. 启动后端开发服务:"
echo "     make backend-dev"
echo ""
echo "  4. 构建 iOS 项目:"
echo "     cd ios && swift build"
echo ""
