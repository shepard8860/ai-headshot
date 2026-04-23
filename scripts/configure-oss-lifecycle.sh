#!/usr/bin/env bash
# ============================================================
# AI职业形象照 - OSS 生命周期配置脚本
# 用法: ./scripts/configure-oss-lifecycle.sh
# 说明: 配置阿里云 OSS 自动删除规则
#   - 原图（uploads/original/*）: 24小时后自动删除
#   - 结果图（results/* 和 hd/*）: 30天后自动删除
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
echo "║         OSS 生命周期配置工具                      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 从 .dev.vars 或环境变量读取配置
read_var() {
    local key="$1"
    local file="${BACKEND_DIR}/.dev.vars"
    if [ -f "$file" ]; then
        grep "^${key}=" "$file" 2>/dev/null | head -1 | cut -d'=' -f2-
    else
        printenv "$key" || true
    fi
}

ALIYUN_ACCESS_KEY_ID="${ALIYUN_ACCESS_KEY_ID:-$(read_var ALIYUN_ACCESS_KEY_ID)}"
ALIYUN_ACCESS_KEY_SECRET="${ALIYUN_ACCESS_KEY_SECRET:-$(read_var ALIYUN_ACCESS_KEY_SECRET)}"
ALIYUN_OSS_ENDPOINT="${ALIYUN_OSS_ENDPOINT:-$(read_var ALIYUN_OSS_ENDPOINT)}"
ALIYUN_OSS_BUCKET="${ALIYUN_OSS_BUCKET:-$(read_var ALIYUN_OSS_BUCKET)}"

# 检查 aliyun CLI
if ! command -v aliyun &> /dev/null; then
    warn "阿里云 CLI (aliyun) 未安装"
    echo ""
    info "安装方式:"
    echo "  macOS: brew install aliyun-cli"
    echo "  Linux: curl -fsSL https://aliyuncli.alicdn.com/install.sh | bash"
    echo "  或访问: https://github.com/aliyun/aliyun-cli"
    echo ""
    info "将使用 ossutil 或 API 调用方式作为备选..."
fi

# 检查 ossutil
USE_OSSUTIL=false
if command -v ossutil &> /dev/null; then
    USE_OSSUTIL=true
    ok "检测到 ossutil"
fi

# 如果缺少配置，提示输入
if [ -z "$ALIYUN_ACCESS_KEY_ID" ] || [ -z "$ALIYUN_ACCESS_KEY_SECRET" ] || [ -z "$ALIYUN_OSS_BUCKET" ]; then
    warn "部分配置不完整，请补充输入"
fi

if [ -z "$ALIYUN_ACCESS_KEY_ID" ]; then
    read -rp "请输入 Aliyun AccessKey ID: " ALIYUN_ACCESS_KEY_ID
fi
if [ -z "$ALIYUN_ACCESS_KEY_SECRET" ]; then
    read -rsp "请输入 Aliyun AccessKey Secret: " ALIYUN_ACCESS_KEY_SECRET
    echo ""
fi
if [ -z "$ALIYUN_OSS_BUCKET" ]; then
    read -rp "请输入 OSS Bucket 名称: " ALIYUN_OSS_BUCKET
fi
if [ -z "$ALIYUN_OSS_ENDPOINT" ]; then
    read -rp "请输入 OSS Endpoint [默认: oss-cn-beijing.aliyuncs.com]: " ALIYUN_OSS_ENDPOINT
    ALIYUN_OSS_ENDPOINT=${ALIYUN_OSS_ENDPOINT:-oss-cn-beijing.aliyuncs.com}
fi

# 构建生命周期 XML
LIFECYCLE_XML=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<LifecycleConfiguration>
  <Rule>
    <ID>delete-original-images-24h</ID>
    <Prefix>uploads/original/</Prefix>
    <Status>Enabled</Status>
    <Expiration>
      <Days>1</Days>
    </Expiration>
  </Rule>
  <Rule>
    <ID>delete-result-images-30d</ID>
    <Prefix>results/</Prefix>
    <Status>Enabled</Status>
    <Expiration>
      <Days>30</Days>
    </Expiration>
  </Rule>
  <Rule>
    <ID>delete-hd-images-30d</ID>
    <Prefix>hd/</Prefix>
    <Status>Enabled</Status>
    <Expiration>
      <Days>30</Days>
    </Expiration>
  </Rule>
</LifecycleConfiguration>
EOF
)

echo ""
info "配置的生命周期规则:"
echo "  1. uploads/original/*  →  1天后自动删除 (原图)"
echo "  2. results/*           → 30天后自动删除 (结果图)"
echo "  3. hd/*                → 30天后自动删除 (高清图)"
echo ""

# 保存临时 XML 文件
TMP_XML=$(mktemp)
echo "$LIFECYCLE_XML" > "$TMP_XML"

# 使用 ossutil 或 aliyun CLI 设置
if [ "$USE_OSSUTIL" = true ]; then
    info "使用 ossutil 设置生命周期规则..."
    ossutil lifecycle --method put "$TMP_XML" "oss://${ALIYUN_OSS_BUCKET}" \
        -e "$ALIYUN_OSS_ENDPOINT" \
        -i "$ALIYUN_ACCESS_KEY_ID" \
        -k "$ALIYUN_ACCESS_KEY_SECRET"
else
    info "使用 aliyun CLI 设置生命周期规则..."
    # 使用阿里云命行工具配置
    aliyun oss PutBucketLifecycle \
        --BucketName "$ALIYUN_OSS_BUCKET" \
        --LifecycleConfiguration file://"$TMP_XML" 2>/dev/null || {
        warn "aliyun CLI 调用失败，尝试使用原生 HTTP 请求..."

        # 使用 curl 调用 OSS REST API
        DATE=$(date -u +"%a, %d %b %Y %H:%M:%S GMT")
        CANONICALIZED_RESOURCE="/${ALIYUN_OSS_BUCKET}/?lifecycle"
        STRING_TO_SIGN="PUT\n\n\n${DATE}\n${CANONICALIZED_RESOURCE}"

        # 需要用签名工具生成 HMAC-SHA1 签名
        # 这里直接用 Python 作为备选
        if command -v python3 &> /dev/null; then
            SIGNATURE=$(python3 -c "
import hmac, hashlib, base64
key = '${ALIYUN_ACCESS_KEY_SECRET}'
msg = b'PUT\n\n\n${DATE}\n${CANONICALIZED_RESOURCE}'
sig = base64.b64encode(hmac.new(key.encode(), msg, hashlib.sha1).digest()).decode()
print(sig)
")
            curl -s -o /dev/null -w "%{http_code}" -X PUT \
                -H "Date: $DATE" \
                -H "Authorization: OSS ${ALIYUN_ACCESS_KEY_ID}:${SIGNATURE}" \
                -H "Content-Type: application/xml" \
                --data-binary "@$TMP_XML" \
                "https://${ALIYUN_OSS_BUCKET}.${ALIYUN_OSS_ENDPOINT}/?lifecycle"
        else
            err "未找到合适的工具来设置 OSS 生命周期"
            err "请手动登录 OSS 控制台设置，或安装 ossutil:"
            err "  https://gosspublic.alicdn.com/ossutil/1.7.19/ossutilmac64"
            rm -f "$TMP_XML"
            exit 1
        fi
    }
fi

rm -f "$TMP_XML"

echo ""
ok "OSS 生命周期规则配置完成！"
info "Bucket: ${ALIYUN_OSS_BUCKET}"
info "Endpoint: ${ALIYUN_OSS_ENDPOINT}"
echo ""
info "验证方式:"
if [ "$USE_OSSUTIL" = true ]; then
    echo "  ossutil lifecycle --method get oss://${ALIYUN_OSS_BUCKET} -e ${ALIYUN_OSS_ENDPOINT}"
else
    echo "  登录阿里云 OSS 控制台 → Bucket 列表 → 基础设置 → 生命周期"
fi
