#!/bin/bash
# setup-universal-skills.sh - 简化版：与 npx skills add 协同工作
# 作用：在新设备上快速设置 AI Skills 中央仓库

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
SKILLS_DIR="${SKILLS_DIR:-$HOME/Workspace/my-ai-skills}"
REMOTE_REPO="${REMOTE_REPO:-git@github.com:你的用户名/my-ai-skills.git}"

echo -e "${BLUE}🚀 AI Skills 中央仓库设置${NC}"
echo ""
echo "本脚本配合 npx skills add 工具使用，实现："
echo "  • 中央仓库管理所有 skills (位于 ~/Workspace/my-ai-skills)"
echo "  • skills add 自动安装社区 skills"
echo "  • Git 跨设备同步"
echo ""

# ============================================
# 步骤 1：克隆或确认中央仓库存在
# ============================================
echo -e "${YELLOW}📁 步骤 1/3: 设置中央仓库${NC}"

if [ -d "$SKILLS_DIR/.git" ]; then
    echo "✅ 中央仓库已存在: $SKILLS_DIR"
elif [ -d "$SKILLS_DIR" ]; then
    echo "⚠️  目录已存在但不是 Git 仓库，初始化..."
    cd "$SKILLS_DIR"
    git init
    git remote add origin "$REMOTE_REPO" 2>/dev/null || echo "  (远程仓库已配置)"
else
    echo "📥 克隆远程仓库..."
    mkdir -p "$(dirname "$SKILLS_DIR")"
    git clone "$REMOTE_REPO" "$SKILLS_DIR" || {
        echo "克隆失败，创建新仓库..."
        mkdir -p "$SKILLS_DIR"
        cd "$SKILLS_DIR"
        git init
    }
fi

echo ""

# ============================================
# 步骤 2：按每个 skill 创建软链接（对齐 npx skills add 行为）
# ============================================
echo -e "${YELLOW}🔗 步骤 2/3: 配置 per-skill 软链接${NC}"

export SKILLS_DIR
if [ -f "$SKILLS_DIR/shared/scripts/install.sh" ]; then
    bash "$SKILLS_DIR/shared/scripts/install.sh"
else
    echo "❌ 未找到安装脚本: $SKILLS_DIR/shared/scripts/install.sh"
    exit 1
fi

echo ""

# ============================================
# 步骤 3：验证配置
# ============================================
echo -e "${YELLOW}🔍 步骤 3/3: 验证配置${NC}"

skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "中央仓库："
echo "  位置: $SKILLS_DIR"
echo "  Skills: $skill_count 个"
if [ -d "$SKILLS_DIR/.git" ]; then
    echo "  Git: ✅ 已初始化"
    if git -C "$SKILLS_DIR" remote get-url origin 2>/dev/null; then
        echo "  远程: $(git -C "$SKILLS_DIR" remote get-url origin)"
    fi
else
    echo "  Git: ❌ 未初始化"
fi

echo ""
echo "per-skill 链接："
if [ -d "$HOME/.agents/skills" ]; then
    echo "  ✅ ~/.agents/skills (目录)"
else
    echo "  ❌ ~/.agents/skills 未配置"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 设置完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}💡 下一步：${NC}"
echo ""
echo "1. 安装社区 skills (使用 npx skills add)："
echo "   npx skills add vercel-labs/agent-skills -g"
echo ""
echo "2. 创建自己的 skill："
echo "   cd $SKILLS_DIR"
echo "   mkdir my-skill && vim my-skill/SKILL.md"
echo "   git add . && git commit -m 'feat: 添加 my-skill' && git push"
echo ""
echo "3. 同步到其他设备："
echo "   git clone $REMOTE_REPO ~/Workspace/my-ai-skills"
echo "   bash ~/Workspace/my-ai-skills/setup-universal-skills.sh"
echo ""
echo "4. 验证配置："
echo "   bash $SKILLS_DIR/shared/scripts/verify.sh"
echo ""
