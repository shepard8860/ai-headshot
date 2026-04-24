#!/usr/bin/env bash
#
# setup-testflight.sh
# 用于配置并执行 AI职业照 iOS App 的 TestFlight 自动化上传
#
# 用法:
#   chmod +x scripts/setup-testflight.sh
#   ./scripts/setup-testflight.sh [upload|check|archive|help]
#
# 环境要求:
#   - macOS + Xcode 15+ (iOS 16+)
#   - Apple Developer 账号已登录 Xcode
#   - 已配置 iOS Distribution 证书和 App Store Provisioning Profile
#   - 如需自动上传，需配置 App Store Connect API Key
#

set -euo pipefail

# ============================================================
# 配置参数
# ============================================================
SCHEME="AIHeadshot"
BUNDLE_ID="com.ai-headshot.app"
APP_NAME="AI职业照"

# 目录设置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IOS_DIR="${PROJECT_ROOT}/ios"
BUILD_DIR="${IOS_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/AIHeadshot.xcarchive"
EXPORT_PATH="${BUILD_DIR}/AIHeadshot.ipa"

# App Store Connect API Key 配置（用于自动上传，可选）
# 建议将敏感信息存放于 Keychain 或 .env 文件，勿硬编码在脚本中
ASC_KEY_ID="${ASC_KEY_ID:-}"
ASC_ISSUER_ID="${ASC_ISSUER_ID:-}"
ASC_KEY_PATH="${ASC_KEY_PATH:-}"

# ============================================================
# 工具函数
# ============================================================
log_info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
log_ok()    { echo -e "\033[1;32m[OK]\033[0m    $*"; }
log_warn()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

die() { log_error "$*"; exit 1; }

print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║         AI职业照 iOS - TestFlight 发布脚本               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
}

print_help() {
    cat <<'EOF'
用法: ./scripts/setup-testflight.sh [command]

命令:
  check      检查发布环境（Xcode、证书、Profile、代码状态）
  build      执行模拟器构建（验证编译）
  archive    执行真机归档（生成 .xcarchive）
  export     导出 IPA（用于 TestFlight 上传）
  upload     上传已导出的 IPA 到 App Store Connect
  full       完整流程：check -> archive -> export -> upload
  help       显示此帮助

环境变量（用于自动上传）:
  ASC_KEY_ID      App Store Connect API Key ID
  ASC_ISSUER_ID   App Store Connect Issuer ID
  ASC_KEY_PATH    API Key 私钥 .p8 文件路径

示例:
  ASC_KEY_ID=ABC123 ASC_ISSUER_ID=xxxx-xxxx ./scripts/setup-testflight.sh upload

注意:
  - 本项目为纯 Swift Package Manager 结构，无 .xcodeproj
  - archive 需要有已登录 Xcode 的 Apple Developer Team
  - 上传前请确保 Info.plist 中版本号已递增
EOF
}

# ============================================================
# 环境检查
# ============================================================
cmd_check() {
    print_banner
    log_info "检查发布环境..."
    echo ""

    # 1. 系统检查
    log_info "系统: $(uname -sr)"

    # 2. Xcode 检查
    if ! command -v xcodebuild &>/dev/null; then
        die "未找到 xcodebuild。请安装 Xcode 并执行: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    fi
    local xcode_version
    xcode_version=$(xcodebuild -version 2>/dev/null | head -n1 || true)
    log_ok "Xcode 已安装: ${xcode_version}"

    # 3. Swift 检查
    if ! command -v swift &>/dev/null; then
        die "未找到 Swift 工具链。"
    fi
    local swift_version
    swift_version=$(swift --version 2>/dev/null | head -n1 || true)
    log_ok "Swift 已安装: ${swift_version}"

    # 4. 检查是否为 SPM 项目
    if [[ -f "${IOS_DIR}/Package.swift" ]]; then
        log_ok "SPM 项目检测: Package.swift 存在"
    else
        die "未找到 ios/Package.swift，请确认在正确的项目目录下运行"
    fi

    if [[ -d "${IOS_DIR}/AIHeadshot.xcodeproj" ]] || [[ -d "${IOS_DIR}/AIHeadshot.xcworkspace" ]]; then
        log_warn "检测到 .xcodeproj/.xcworkspace，将优先使用现有 Xcode 项目"
    else
        log_warn "未发现 .xcodeproj，将使用 Package.swift 直接归桢"
        log_warn "提示: 若归桢失败，可尝试在 Xcode 中打开 Package.swift 生成工程后归桢"
    fi

    # 5. 检查签名身份
    log_info "检查签名证书..."
    local identities
    identities=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "iPhone Distribution" || true)
    if [[ "$identities" -gt 0 ]]; then
        log_ok "发现 ${identities} 个 iPhone Distribution 证书"
        security find-identity -v -p codesigning 2>/dev/null | grep "iPhone Distribution" | head -n3 || true
    else
        log_warn "未发现 iPhone Distribution 证书，将无法归桢"
        log_warn "请在 Xcode -> Settings -> Accounts 中登录 Apple ID，并确保已下载 Distribution 证书"
    fi

    # 6. 检查 Provisioning Profiles
    log_info "检查 Provisioning Profiles..."
    local profile_dir="${HOME}/Library/MobileDevice/Provisioning Profiles"
    if [[ -d "$profile_dir" ]]; then
        local profile_count
        profile_count=$(find "$profile_dir" -name "*.mobileprovision" 2>/dev/null | wc -l | tr -d ' ')
        log_ok "本地共有 ${profile_count} 个 Provisioning Profiles"
        # 尝试查找匹配的 Profile
        if command -v security &>/dev/null; then
            local matched=0
            while IFS= read -r -d '' f; do
                if security cms -D -i "$f" 2>/dev/null | grep -q "${BUNDLE_ID}"; then
                    matched=$((matched + 1))
                fi
            done < <(find "$profile_dir" -name "*.mobileprovision" -print0 2>/dev/null)
            if [[ "$matched" -gt 0 ]]; then
                log_ok "发现 ${matched} 个匹配 Bundle ID (${BUNDLE_ID}) 的 Profile"
            else
                log_warn "未发现匹配 ${BUNDLE_ID} 的 Profile，归桢时可能需 Xcode 自动签名"
            fi
        fi
    else
        log_warn "Provisioning Profiles 目录不存在"
    fi

    # 7. 检查 Info.plist 版本
    log_info "检查版本信息..."
    if [[ -f "${IOS_DIR}/Info.plist" ]]; then
        local short_ver build_ver bundle_id
        short_ver=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${IOS_DIR}/Info.plist" 2>/dev/null || true)
        build_ver=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${IOS_DIR}/Info.plist" 2>/dev/null || true)
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${IOS_DIR}/Info.plist" 2>/dev/null || true)
        log_ok "Bundle ID: ${bundle_id:-N/A}"
        log_ok "Version:   ${short_ver:-N/A} (${build_ver:-N/A})"
        if [[ "${build_ver:-0}" == "1" ]]; then
            log_warn "Build 号仍为 1，TestFlight 上传旰建议递增"
        fi
    else
        log_warn "未找到 ios/Info.plist"
    fi

    # 8. 检查 App Icon
    log_info "检查 App Icon..."
    local icon_dir="${IOS_DIR}/Sources/AIHeadshot/Resources/Assets.xcassets/AppIcon.appiconset"
    if [[ -f "${icon_dir}/Contents.json" ]]; then
        local has_png
        has_png=$(find "$icon_dir" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$has_png" -gt 0 ]]; then
            log_ok "AppIcon 配置存在，共 ${has_png} 个 PNG 资源"
        else
            log_warn "AppIcon Contents.json 存在，但未发现 PNG 图片文件"
            log_warn "请在 ${icon_dir} 下添加 1024x1024 的营销图标"
        fi
    else
        log_warn "未发现 AppIcon 配置"
    fi

    # 9. 检查隐私清单
    if [[ -f "${IOS_DIR}/PrivacyInfo.xcprivacy" ]]; then
        log_ok "PrivacyInfo.xcprivacy 已配置"
    else
        log_warn "未发现 PrivacyInfo.xcprivacy"
    fi

    # 10. 检查 ASC API Key（用于自动上传）
    echo ""
    log_info "检查 App Store Connect API Key 配置..."
    if [[ -n "$ASC_KEY_ID" && -n "$ASC_ISSUER_ID" && -n "$ASC_KEY_PATH" && -f "$ASC_KEY_PATH" ]]; then
        log_ok "API Key 配置完整，支持自动上传"
    else
        log_warn "API Key 未配置或文件不存在，上传阶段将使用 Transporter / Xcode Organizer 手动上传"
        log_warn "配置方法: 在 App Store Connect -> 用户和访问 -> 键 -> 生成 API Key"
    fi

    echo ""
    log_ok "环境检查完成"
}

# ============================================================
# 构建（模拟器）
# ============================================================
cmd_build() {
    print_banner
    log_info "开始模拟器构建（验证编译）..."
    mkdir -p "$BUILD_DIR"

    cd "$IOS_DIR"

    local xcodebuild_args=(
        -scheme "$SCHEME"
        -destination 'platform=iOS Simulator,name=iPhone 15'
        -derivedDataPath "${BUILD_DIR}/DerivedData"
        build
    )

    # 如果存在 .xcodeproj 优先使用
    if [[ -d "${IOS_DIR}/AIHeadshot.xcodeproj" ]]; then
        xcodebuild_args=(-project "AIHeadshot.xcodeproj" "${xcodebuild_args[@]}")
    fi

    log_info "执行: xcodebuild ${xcodebuild_args[*]}"
    if xcodebuild "${xcodebuild_args[@]}" 2>&1 | tee "${BUILD_DIR}/build.log"; then
        log_ok "模拟器构建成功"
    else
        die "模拟器构建失败，请查看 ${BUILD_DIR}/build.log"
    fi
}

# ============================================================
# 归桢（真机 / Generic）
# ============================================================
cmd_archive() {
    print_banner
    log_info "开始真机归桢..."
    mkdir -p "$BUILD_DIR"

    cd "$IOS_DIR"

    # 检查是否存在 .xcodeproj
    local proj_args=()
    if [[ -d "${IOS_DIR}/AIHeadshot.xcodeproj" ]]; then
        proj_args=(-project "AIHeadshot.xcodeproj")
    fi

    local archive_args=(
        "${proj_args[@]}"
        -scheme "$SCHEME"
        -destination 'generic/platform=iOS'
        -archivePath "$ARCHIVE_PATH"
        archive
    )

    log_info "执行: xcodebuild ${archive_args[*]}"
    if xcodebuild "${archive_args[@]}" 2>&1 | tee "${BUILD_DIR}/archive.log"; then
        log_ok "归桢成功: ${ARCHIVE_PATH}"
    else
        die "归桢失败，请查看 ${BUILD_DIR}/archive.log"
    fi
}

# ============================================================
# 导出 IPA
# ============================================================
cmd_export() {
    print_banner

    if [[ ! -d "$ARCHIVE_PATH" ]]; then
        log_warn "未发现归桢: ${ARCHIVE_PATH}"
        log_info "将先执行 archive..."
        cmd_archive
    fi

    log_info "开始导出 IPA..."
    mkdir -p "$BUILD_DIR"

    # 创建 exportOptions.plist
    local export_plist="${BUILD_DIR}/ExportOptions.plist"
    cat > "$export_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
EOF
    log_warn "导出配置使用了占位符 teamID，请将 ${export_plist} 中的 YOUR_TEAM_ID 替换为实际的 Apple Developer Team ID"

    local export_args=(
        -archivePath "$ARCHIVE_PATH"
        -exportPath "$EXPORT_PATH"
        -exportOptionsPlist "$export_plist"
        -allowProvisioningUpdates
    )

    log_info "执行: xcodebuild -exportArchive ${export_args[*]}"
    if xcodebuild -exportArchive "${export_args[@]}" 2>&1 | tee "${BUILD_DIR}/export.log"; then
        log_ok "IPA 导出成功: ${EXPORT_PATH}"
        local ipa_file
        ipa_file=$(find "$EXPORT_PATH" -name "*.ipa" 2>/dev/null | head -n1)
        if [[ -n "$ipa_file" ]]; then
            log_ok "IPA 文件: ${ipa_file}"
            ls -lh "$ipa_file"
        fi
    else
        die "IPA 导出失败，请查看 ${BUILD_DIR}/export.log"
    fi
}

# ============================================================
# 上传到 App Store Connect
# ============================================================
cmd_upload() {
    print_banner

    local ipa_file
    ipa_file=$(find "$EXPORT_PATH" -name "*.ipa" 2>/dev/null | head -n1)

    if [[ -z "$ipa_file" || ! -f "$ipa_file" ]]; then
        die "未找到 IPA 文件，请先执行 export 或确保 ${EXPORT_PATH} 下有 .ipa"
    fi

    log_ok "找到 IPA: ${ipa_file}"
    log_info "开始上传到 App Store Connect..."

    if [[ -n "$ASC_KEY_ID" && -n "$ASC_ISSUER_ID" && -n "$ASC_KEY_PATH" && -f "$ASC_KEY_PATH" ]]; then
        log_info "使用 App Store Connect API Key 上传..."
        xcrun altool --upload-app \
            --type ios \
            --file "$ipa_file" \
            --apiKey "$ASC_KEY_ID" \
            --apiIssuer "$ASC_ISSUER_ID" \
            2>&1 | tee "${BUILD_DIR}/upload.log"
    else
        log_warn "未配置 API Key，尝试使用 xcrun altool 交互式上传..."
        log_warn "您也可以使用 Xcode -> Window -> Organizer 手动上传"
        echo ""
        log_info "命令如下（需要输入 Apple ID 密码）:"
        echo "  xcrun altool --upload-app --type ios --file \"${ipa_file}\" --username \"your-apple-id@example.com\" --password \"@keychain:AC_PASSWORD\""
        echo ""
        log_info "提示: 建议将专用密码存入钥匙串："
        echo "  xcrun altool --store-password-in-keychain-item AC_PASSWORD -u \"your-apple-id@example.com\" -p"
    fi
}

# ============================================================
# 完整流程
# ============================================================
cmd_full() {
    print_banner
    cmd_check
    echo ""
    read -rp "环境检查通过，是否继续归桢? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "已取消"
        exit 0
    fi

    cmd_archive

    echo ""
    read -rp "归桢成功，是否继续导出 IPA? (y/N): " confirm2
    if [[ "$confirm2" != "y" && "$confirm2" != "Y" ]]; then
        log_info "已取消"
        exit 0
    fi

    cmd_export

    echo ""
    read -rp "IPA 导出成功，是否继续上传到 TestFlight? (y/N): " confirm3
    if [[ "$confirm3" != "y" && "$confirm3" != "Y" ]]; then
        log_info "已取消"
        exit 0
    fi

    cmd_upload
}

# ============================================================
# 主入口
# ============================================================
main() {
    case "${1:-help}" in
        check)
            cmd_check
            ;;
        build)
            cmd_build
            ;;
        archive)
            cmd_archive
            ;;
        export)
            cmd_export
            ;;
        upload)
            cmd_upload
            ;;
        full)
            cmd_full
            ;;
        help|--help|-h|"" )
            print_banner
            print_help
            ;;
        *)
            die "未知命令: $1，请使用 help 查看帮助"
            ;;
    esac
}

main "$@"
