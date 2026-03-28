#!/bin/bash
# setup-universal-skills.sh - 简化版：与 npx skills add 协同工作
# 作用：在新设备上快速设置 AI Skills 中央仓库

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
WORKSPACE_SKILLS_DIR="${WORKSPACE_SKILLS_DIR:-$HOME/Workspace/my-ai-skills}"
REMOTE_REPO="${REMOTE_REPO:-git@github.com:你的用户名/my-ai-skills.git}"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

resolve_dir() {
    local dir="$1"
    (cd "$dir" 2>/dev/null && pwd -P)
}

echo -e "${BLUE}🚀 AI Skills 中央仓库设置${NC}"
echo ""
echo "本脚本配合 npx skills add 工具使用，实现："
echo "  • 中央仓库管理所有 skills (位于 ~/.agents/skills)"
echo "  • ~/Workspace/my-ai-skills 作为便捷入口软链接"
echo "  • 第三方 skill 安装后直接落成中央仓库顶层真实目录"
echo "  • skills add 自动安装社区 skills"
echo "  • Git 跨设备同步"
echo ""

# ============================================
# 步骤 1：准备中央仓库（真实目录）
# ============================================
echo -e "${YELLOW}📁 步骤 1/4: 设置中央仓库${NC}"

# 迁移旧布局：workspace 为真实目录，~/.agents/skills 不存在
if [ ! -e "$AGENTS_SKILLS_DIR" ] && [ -d "$WORKSPACE_SKILLS_DIR/.git" ] && [ ! -L "$WORKSPACE_SKILLS_DIR" ]; then
    echo "🔁 检测到旧布局，迁移仓库到 ~/.agents/skills ..."
    mkdir -p "$(dirname "$AGENTS_SKILLS_DIR")"
    mv "$WORKSPACE_SKILLS_DIR" "$AGENTS_SKILLS_DIR"
fi

if [ -d "$AGENTS_SKILLS_DIR/.git" ]; then
    AGENTS_SKILLS_DIR="$(resolve_dir "$AGENTS_SKILLS_DIR")"
    echo "✅ 中央仓库已存在: $AGENTS_SKILLS_DIR"
elif [ -d "$AGENTS_SKILLS_DIR" ]; then
    AGENTS_SKILLS_DIR="$(resolve_dir "$AGENTS_SKILLS_DIR")"
    echo "⚠️  目录已存在但不是 Git 仓库，初始化..."
    cd "$AGENTS_SKILLS_DIR"
    git init
    git remote add origin "$REMOTE_REPO" 2>/dev/null || echo "  (远程仓库已配置)"
else
    echo "📥 克隆远程仓库..."
    mkdir -p "$(dirname "$AGENTS_SKILLS_DIR")"
    git clone "$REMOTE_REPO" "$AGENTS_SKILLS_DIR" || {
        echo "克隆失败，创建新仓库..."
        mkdir -p "$AGENTS_SKILLS_DIR"
        cd "$AGENTS_SKILLS_DIR"
        git init
    }
    AGENTS_SKILLS_DIR="$(resolve_dir "$AGENTS_SKILLS_DIR")"
fi

echo ""

# ============================================
# 步骤 2：创建/校验 workspace 便捷入口
# ============================================
echo -e "${YELLOW}🔗 步骤 2/4: 校验 workspace 软链接${NC}"

if [ -L "$WORKSPACE_SKILLS_DIR" ]; then
    workspace_real="$(resolve_dir "$WORKSPACE_SKILLS_DIR")"
    if [ "$workspace_real" != "$AGENTS_SKILLS_DIR" ]; then
        echo "⚠️  发现 $WORKSPACE_SKILLS_DIR 指向其他位置，重新创建..."
        rm "$WORKSPACE_SKILLS_DIR"
        ln -s "$AGENTS_SKILLS_DIR" "$WORKSPACE_SKILLS_DIR"
    else
        echo "✅ workspace 软链接正常: $WORKSPACE_SKILLS_DIR -> $AGENTS_SKILLS_DIR"
    fi
elif [ -e "$WORKSPACE_SKILLS_DIR" ]; then
    backup_path="${WORKSPACE_SKILLS_DIR}.backup-${BACKUP_SUFFIX}"
    echo "⚠️  发现 $WORKSPACE_SKILLS_DIR 为非软链接目录/文件，已备份到: $backup_path"
    mv "$WORKSPACE_SKILLS_DIR" "$backup_path"
    ln -s "$AGENTS_SKILLS_DIR" "$WORKSPACE_SKILLS_DIR"
    echo "✅ 已创建软链接: $WORKSPACE_SKILLS_DIR -> $AGENTS_SKILLS_DIR"
else
    mkdir -p "$(dirname "$WORKSPACE_SKILLS_DIR")"
    ln -s "$AGENTS_SKILLS_DIR" "$WORKSPACE_SKILLS_DIR"
    echo "✅ 已创建软链接: $WORKSPACE_SKILLS_DIR -> $AGENTS_SKILLS_DIR"
fi

echo ""

# ============================================
# 步骤 3：按每个 skill 创建软链接（对齐 npx skills add 行为）
# ============================================
echo -e "${YELLOW}🔗 步骤 3/4: 配置 per-skill 软链接${NC}"

export SKILLS_DIR="$AGENTS_SKILLS_DIR"
if [ -f "$AGENTS_SKILLS_DIR/shared/scripts/install.sh" ]; then
    bash "$AGENTS_SKILLS_DIR/shared/scripts/install.sh"
else
    echo "❌ 未找到安装脚本: $AGENTS_SKILLS_DIR/shared/scripts/install.sh"
    exit 1
fi

echo ""

# ============================================
# 步骤 4：验证配置
# ============================================
echo -e "${YELLOW}🔍 步骤 4/4: 验证配置${NC}"

skill_count=$(find "$AGENTS_SKILLS_DIR" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) 2>/dev/null | while read -r path; do [[ -f "$path/SKILL.md" ]] && echo "$path"; done | wc -l | tr -d ' ')

echo ""
echo "中央仓库："
echo "  位置: $AGENTS_SKILLS_DIR"
echo "  Skills: $skill_count 个"
if [ -d "$AGENTS_SKILLS_DIR/.git" ]; then
    echo "  Git: ✅ 已初始化"
    if git -C "$AGENTS_SKILLS_DIR" remote get-url origin 2>/dev/null; then
        echo "  远程: $(git -C "$AGENTS_SKILLS_DIR" remote get-url origin)"
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
if [ -L "$WORKSPACE_SKILLS_DIR" ]; then
    echo "  ✅ $WORKSPACE_SKILLS_DIR -> $(readlink "$WORKSPACE_SKILLS_DIR")"
else
    echo "  ⚠️  $WORKSPACE_SKILLS_DIR 不是软链接"
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
echo "   cd $WORKSPACE_SKILLS_DIR"
echo "   mkdir my-skill && vim my-skill/SKILL.md"
echo "   git add . && git commit -m 'feat: 添加 my-skill' && git push"
echo ""
echo "3. 同步到其他设备："
echo "   git clone $REMOTE_REPO ~/.agents/skills"
echo "   bash ~/.agents/skills/setup-universal-skills.sh"
echo ""
echo "4. 验证配置："
echo "   SKILLS_DIR=$WORKSPACE_SKILLS_DIR bash $WORKSPACE_SKILLS_DIR/shared/scripts/verify.sh"
echo ""
