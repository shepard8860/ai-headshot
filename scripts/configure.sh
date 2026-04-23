#!/usr/bin/env bash
# ============================================================
# AI职业形象照 - 交互式配置脚本
# 用法: ./scripts/configure.sh
# 说明: 引导用户输入各种 API Key 并生成配置文件
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${PROJECT_ROOT}/backend/worker"

echo "╔════════════════════════════════════════════════════════╗"
echo "║     AI职业形象照 - 一键配置工具                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 颜色输出
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 输入提示函数
prompt() {
    local desc="$1"
    local var_name="$2"
    local default_value="${3:-}"
    local is_secret="${4:-false}"

    echo -e "${CYAN}┌── $desc${NC}"
    if [ -n "$default_value" ]; then
        echo -e "${CYAN}│  默认: $default_value${NC}"
    fi
    echo -en "${CYAN}└─> ${NC}"

    if [ "$is_secret" = "true" ]; then
        read -rs value
        echo ""
    else
        read -r value
    fi

    if [ -z "$value" ] && [ -n "$default_value" ]; then
        value="$default_value"
    fi

    eval "$var_name='${value}'"
}

echo -e "${YELLOW}【第 1/6 步】LeanCloud 数据库配置${NC}"
echo "提示: 访问 https://leancloud.cn → 创建应用 → 设置 → 应用凭证"
echo ""
prompt "LeanCloud App ID" LEANCLOUD_APP_ID
prompt "LeanCloud App Key" LEANCLOUD_APP_KEY ""
prompt "LeanCloud Server URL (如 https://your-api.lc-cn-n1-shared.com)" LEANCLOUD_SERVER_URL "https://your-api.lc-cn-n1-shared.com"

echo ""
echo -e "${YELLOW}【第 2/6 步】商汤 SenseNova AI 配置${NC}"
echo "提示: 访问 https://platform.sensenova.cn → 创建 API Key"
echo ""
prompt "SenseNova API Key" SENSENOVA_API_KEY ""
prompt "SenseNova API URL" SENSENOVA_API_URL "https://api.sensenova.cn/v1"

echo ""
echo -e "${YELLOW}【第 3/6 步】阿里云 OSS + 通义万相 配置${NC}"
echo "提示: 访问 https://ram.console.aliyun.com → 创建 AccessKey"
echo ""
prompt "Aliyun AccessKey ID" ALIYUN_ACCESS_KEY_ID ""
prompt "Aliyun AccessKey Secret" ALIYUN_ACCESS_KEY_SECRET "" true
prompt "Aliyun OSS Endpoint" ALIYUN_OSS_ENDPOINT "oss-cn-beijing.aliyuncs.com"
prompt "Aliyun OSS Bucket 名称" ALIYUN_OSS_BUCKET "ai-headshot-bucket"
prompt "Aliyun Wanxiang API URL" ALIYUN_WANXI_API_URL "https://dashscope.aliyuncs.com/api/v1"

echo ""
echo -e "${YELLOW}【第 4/6 步】Apple App Store IAP 配置${NC}"
echo "提示: App Store Connect → 应用 → 功能 → App 内购买项目 → 共享密钥"
echo ""
prompt "Apple Shared Secret" APPLE_SHARED_SECRET "" true

echo ""
echo -e "${YELLOW}【第 5/6 步】管理后台 Basic Auth${NC}"
echo "提示: 生产环境请修改默认密码"
echo ""
prompt "管理员用户名" ADMIN_USERNAME "admin"
prompt "管理员密码" ADMIN_PASSWORD "" true

echo ""
echo -e "${YELLOW}【第 6/6 步】微信小程序配置（可选，直接回车跳过）${NC}"
echo ""
prompt "WeChat App ID (可选)" WECHAT_APP_ID ""
prompt "WeChat Secret (可选)" WECHAT_SECRET "" true

# 生成 .dev.vars
echo ""
echo -e "${GREEN}正在生成配置文件...${NC}"

DEV_VARS_FILE="${BACKEND_DIR}/.dev.vars"

cat > "$DEV_VARS_FILE" <<EOF
# AI职业形象照 - 本地开发环境变量
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 请勿将本文件提交到 Git 仓库！

LEANCLOUD_APP_ID=${LEANCLOUD_APP_ID}
LEANCLOUD_APP_KEY=${LEANCLOUD_APP_KEY}
LEANCLOUD_SERVER_URL=${LEANCLOUD_SERVER_URL}

SENSENOVA_API_KEY=${SENSENOVA_API_KEY}
SENSENOVA_API_URL=${SENSENOVA_API_URL}

ALIYUN_ACCESS_KEY_ID=${ALIYUN_ACCESS_KEY_ID}
ALIYUN_ACCESS_KEY_SECRET=${ALIYUN_ACCESS_KEY_SECRET}
ALIYUN_OSS_ENDPOINT=${ALIYUN_OSS_ENDPOINT}
ALIYUN_OSS_BUCKET=${ALIYUN_OSS_BUCKET}
ALIYUN_WANXI_API_URL=${ALIYUN_WANXI_API_URL}

APPLE_SHARED_SECRET=${APPLE_SHARED_SECRET}
APPLE_SANDBOX_URL=https://sandbox.itunes.apple.com/verifyReceipt
APPLE_PRODUCTION_URL=https://buy.itunes.apple.com/verifyReceipt

ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
EOF

if [ -n "$WECHAT_APP_ID" ]; then
    cat >> "$DEV_VARS_FILE" <<EOF

WECHAT_APP_ID=${WECHAT_APP_ID}
WECHAT_SECRET=${WECHAT_SECRET}
EOF
fi

echo -e "${GREEN}✓ 已生成: ${DEV_VARS_FILE}${NC}"

# 生成生产环境配置提示
echo ""
echo -e "${YELLOW}生成生产环境部署提示...${NC}"

cat <<EOF

╔════════════════════════════════════════════════════════╗
║            生产环境部署命令（请粘贴执行）               ║
╚════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${CYAN}# 1. 进入后端目录${NC}"
echo "cd ${BACKEND_DIR}"
echo ""
echo -e "${CYAN}# 2. 登录 Cloudflare（如果尚未登录）${NC}"
echo "npx wrangler login"
echo ""
echo -e "${CYAN}# 3. 设置生产环境密钥（每个需要单独执行）${NC}"
echo "npx wrangler secret put LEANCLOUD_APP_KEY"
echo "npx wrangler secret put SENSENOVA_API_KEY"
echo "npx wrangler secret put ALIYUN_ACCESS_KEY_SECRET"
echo "npx wrangler secret put APPLE_SHARED_SECRET"
echo "npx wrangler secret put ADMIN_PASSWORD"
echo ""

echo -e "${GREEN}✓ 配置完成！接下来可以运行 'make setup' 进行初始化。${NC}"
