#!/bin/bash
set -e

echo "🚀 AI Headshot — GitHub 推送脚本"
echo ""

# 检查 git
if ! command -v git &> /dev/null; then
    echo "❌ 未安装 git"
    exit 1
fi

# 检查是否在项目目录
if [ ! -f "Package.swift" ] && [ ! -d "ios" ]; then
    echo "⚠️  请在项目根目录运行此脚本"
    echo "   cd ~/AIFactory/projects/ai-headshot"
    exit 1
fi

# 配置 git（如果未设置）
if [ -z "$(git config user.name)" ]; then
    read -p "输入你的 Git 用户名: " git_name
    git config user.name "$git_name"
fi
if [ -z "$(git config user.email)" ]; then
    read -p "输入你的 Git 邮箱: " git_email
    git config user.email "$git_email"
fi

# 检查远程仓库
if git remote | grep -q "origin"; then
    echo "✅ 已关联远程仓库: $(git remote get-url origin)"
else
    echo ""
    echo "📦 尚未关联远程仓库"
    echo ""
    echo "步骤 1: 在 GitHub 创建新仓库（不要初始化 README）"
    echo "   https://github.com/new"
    echo ""
    read -p "步骤 2: 输入你的 GitHub 仓库地址 (如 https://github.com/你的用户名/ai-headshot.git): " repo_url
    git remote add origin "$repo_url"
    echo "✅ 已关联远程仓库"
fi

echo ""
echo "📤 推送到 GitHub..."
git branch -M main
git push -u origin main

echo ""
echo "✅ 推送完成！"
echo ""
echo "下一步："
echo "   1. 打开 GitHub 仓库页面"
echo "   2. 点击 Actions 标签，查看 iOS CI 编译状态"
echo "   3. 如果编译失败，把错误日志贴给我，我会修复"
echo ""
