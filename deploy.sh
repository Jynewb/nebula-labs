#!/bin/bash

# 一键部署脚本 - 星云实验室网站到 GitHub Pages

set -e

echo "🚀 开始部署到 GitHub Pages..."
echo ""

# 检查是否已登录
echo "📝 检查 GitHub 登录状态..."
if ! gh auth status &>/dev/null; then
    echo "❌ 未登录 GitHub，请先运行："
    echo "   gh auth login"
    echo ""
    echo "然后选择："
    echo "   - GitHub.com"
    echo "   - HTTPS"
    echo "   - Login with a web browser"
    echo ""
    exit 1
fi

# 获取用户名
USERNAME=$(gh api user --jq '.login')
echo "✅ 已登录: $USERNAME"
echo ""

# 切换到 main 分支
echo "📦 准备代码..."
cd /Users/jytao/Desktop/nebula-labs
git branch -M main 2>/dev/null || true
echo "✅ 代码准备完成"
echo ""

# 创建仓库
echo "🌐 创建 GitHub 仓库..."
if gh repo view nebula-labs &>/dev/null; then
    echo "✅ 仓库已存在"
else
    gh repo create nebula-labs --public --source=. --push
    echo "✅ 仓库创建成功"
fi
echo ""

# 推送代码
echo "⬆️ 推送代码到 GitHub..."
git remote set-url origin https://github.com/$USERNAME/nebula-labs.git 2>/dev/null || \
    git remote add origin https://github.com/$USERNAME/nebula-labs.git
git push -u origin main -f
echo "✅ 代码推送完成"
echo ""

# 启用 GitHub Pages
echo "🌐 启用 GitHub Pages..."
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  repos/$USERNAME/nebula-labs/pages \
  -f source='{"branch":"main","path":"/"}' 2>/dev/null || echo "✅ Pages 可能已配置"
echo ""

# 等待部署
echo "⏳ 等待 GitHub Pages 部署中..."
echo "这可能需要 1-3 分钟，请稍候..."
echo ""

# 获取 Pages 状态
sleep 3
MAX_ATTEMPTS=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "检查部署状态 ($ATTEMPT/$MAX_ATTEMPTS)..."

    STATUS=$(gh api repos/$USERNAME/nebula-labs/pages --jq '.status' 2>/dev/null || echo "unknown")

    if [ "$STATUS" = "built" ] || [ "$STATUS" = "deployed" ]; then
        echo ""
        echo "✅ 部署成功！"
        echo ""
        echo "🌐 访问链接:"
        echo "   https://$USERNAME.github.io/nebula-labs/"
        echo ""
        echo "💡 如果链接打不开，请等待 1-2 分钟（DNS 传播）"
        echo ""
        exit 0
    fi

    sleep 10
done

echo ""
echo "⚠️  部署仍在进行中"
echo "🌐 你的链接:"
echo "   https://$USERNAME.github.io/nebula-labs/"
echo ""
echo "💡 请稍后访问，或查看 GitHub 仓库的 Actions 标签页"
echo ""
