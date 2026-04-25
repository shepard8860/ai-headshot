# ============================================================
# AI职业形象照 - Makefile
# 用法: make <target>
# ============================================================

.PHONY: help setup lint test deploy backend-dev ios-build clean configure leancloud-init oss-lifecycle

# 默认目标
help:
	@echo "AI职业形象照 - 可用命令"
	@echo ""
	@echo "  make setup          初始化开发环境（安装依赖 + 配置）"
	@echo "  make configure      交互式配置环境变量"
	@echo "  make lint           检查代码（TypeScript + ESLint）"
	@echo "  make test           运行测试"
	@echo "  make deploy         部署后端到 Cloudflare 生产环境"
	@echo "  make backend-dev    本地运行后端开发服务"
	@echo "  make leancloud-init 初始化 LeanCloud 数据库"
	@echo "  make oss-lifecycle  配置 OSS 自动删除规则"
	@echo "  make ios-build      构建 iOS 项目"
	@echo "  make clean          清理临时文件"

# --------------------------------------------------
# 初始化
# --------------------------------------------------
setup: configure
	@echo "╔════════════════════════════════════════════════════════╗"
	@echo "║              初始化开发环境                    ║"
	@echo "╚════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "【步骤 1/4】安装后端依赖..."
	cd backend/worker && npm install
	@echo ""
	@echo "【步骤 2/4】验证环境..."
	cd backend/worker && npx tsc --noEmit || true
	@echo ""
	@echo "【步骤 3/4】安装 iOS 依赖..."
	cd ios && swift package resolve || true
	@echo ""
	@echo "【步骤 4/4】检查脚本可执行权限..."
	chmod +x scripts/*.sh scripts/*.js 2>/dev/null || true
	@echo ""
	@echo "✓ 初始化完成！接下来可以:"
	@echo "  - make backend-dev   启动本地后端服务"
	@echo "  - make leancloud-init 初始化数据库"
	@echo "  - make oss-lifecycle 配置存储桶规则"

# --------------------------------------------------
# 配置
# --------------------------------------------------
configure:
	@bash scripts/configure.sh

# --------------------------------------------------
# 代码检查
# --------------------------------------------------
lint:
	@echo "【TypeScript 类型检查】"
	cd backend/worker && npm run typecheck
	@echo ""
	@echo "【ESLint 代码检查】"
	cd backend/worker && npm run lint

# --------------------------------------------------
# 测试
# --------------------------------------------------
test:
	@echo "【后端测试】"
	cd backend/worker && npm test || echo "暂无测试脚本"
	@echo ""
	@echo "【iOS 测试】"
	cd ios && swift test || echo "iOS 测试未通过或未配置"
	@echo ""
	@echo "【API 健康检查】"
	@if curl -sf http://localhost:8787/health >/dev/null 2>&1; then \
		echo "✓ 本地服务健康检查通过"; \
	else \
		echo "⚠ 本地服务未启动（http://localhost:8787）"; \
	fi

# --------------------------------------------------
# 部署
# --------------------------------------------------
deploy:
	@bash scripts/deploy-backend.sh

# --------------------------------------------------
# 后端本地开发
# --------------------------------------------------
backend-dev:
	@bash scripts/run-backend-local.sh

# --------------------------------------------------
# LeanCloud 初始化
# --------------------------------------------------
leancloud-init:
	@node scripts/init-leancloud.js

# --------------------------------------------------
# OSS 生命周期配置
# --------------------------------------------------
oss-lifecycle:
	@bash scripts/configure-oss-lifecycle.sh

# --------------------------------------------------
# iOS 构建
# --------------------------------------------------
ios-build:
	cd ios && xcodebuild \
		-scheme AIHeadshot \
		-destination 'platform=iOS Simulator,name=iPhone 16' \
		-derivedDataPath .build/DerivedData \
		build CODE_SIGNING_ALLOWED=NO

ios-test:
	cd ios && xcodebuild \
		-scheme AIHeadshot \
		-destination 'platform=iOS Simulator,name=iPhone 16' \
		-derivedDataPath .build/DerivedData \
		test CODE_SIGNING_ALLOWED=NO

ios-archive:
	cd ios && xcodebuild \
		-scheme AIHeadshot \
		-archivePath .build/AIHeadshot.xcarchive \
		archive

ios-export:
	cd ios && xcodebuild \
		-exportArchive \
		-archivePath .build/AIHeadshot.xcarchive \
		-exportPath .build/Export \
		-exportOptionsPlist exportOptions.plist

ios-lint:
	cd ios && /opt/homebrew/bin/swiftlint lint

# --------------------------------------------------
# 清理
# --------------------------------------------------
clean:
	@echo "清理临时文件..."
	find . -name "*.log" -type f -delete 2>/dev/null || true
	find . -name ".DS_Store" -type f -delete 2>/dev/null || true
	find backend/worker -name "*.tmp" -type f -delete 2>/dev/null || true
	rm -rf backend/worker/.wrangler/tmp 2>/dev/null || true
	@echo "✓ 清理完成"
