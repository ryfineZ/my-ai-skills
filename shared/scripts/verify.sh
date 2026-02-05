#!/bin/bash
# verify.sh - 验证 Skills 配置（按每个 skill 软链接）

echo "🔍 验证 AI Skills 配置..."
echo ""

SKILLS_DIR="${SKILLS_DIR:-$HOME/Workspace/my-ai-skills}"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"

# 检查中央仓库
if [ -d "$SKILLS_DIR" ]; then
    echo "✅ 中央仓库: $SKILLS_DIR"
    skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" | wc -l)
    echo "   Skills 数量: $skill_count"
else
    echo "❌ 中央仓库不存在: $SKILLS_DIR"
    exit 1
fi

echo ""
echo "🔗 ~/.agents/skills 状态："
if [ -L "$AGENTS_SKILLS_DIR" ]; then
    echo "⚠️  $AGENTS_SKILLS_DIR 是软链接（建议改为目录以匹配 npx skills add 行为）"
elif [ -d "$AGENTS_SKILLS_DIR" ]; then
    echo "✅ $AGENTS_SKILLS_DIR (目录)"
else
    echo "❌ $AGENTS_SKILLS_DIR 不存在"
fi

echo ""
echo "🔗 工具链接状态："

links=(
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.cursor/skills"
    "$HOME/.gemini/skills"
    "$HOME/.antigravity/skills"
    "$HOME/.gemini/antigravity/skills"
    "$HOME/.windsurf/skills"
    "$HOME/.cline/skills"
    "$HOME/.goose/skills"
)

for link in "${links[@]}"; do
    if [ -L "$link" ]; then
        echo "⚠️  $link 是软链接（建议使用 per-skill 目录）"
    elif [ -d "$link" ]; then
        echo "✅ $link (目录)"
    else
        echo "❌ $link (不存在)"
    fi
done

echo ""
echo "📋 可用 Skills："
find "$SKILLS_DIR" -name "SKILL.md" | while read -r skill; do
    skill_name=$(basename "$(dirname "$skill")")
    desc=$(grep "^description:" "$skill" 2>/dev/null | head -1 | sed 's/description: *//' || echo "无描述")
    echo "  - $skill_name: $desc"

    if [ -L "$AGENTS_SKILLS_DIR/$skill_name" ]; then
        target=$(readlink "$AGENTS_SKILLS_DIR/$skill_name")
        if [ "$target" != "$(dirname "$skill")" ]; then
            echo "    ⚠️  ~/.agents/skills/$skill_name -> $target (指向异常)"
        fi
    elif [ -e "$AGENTS_SKILLS_DIR/$skill_name" ]; then
        echo "    ⚠️  ~/.agents/skills/$skill_name 不是软链接"
    else
        echo "    ❌ 缺少 ~/.agents/skills/$skill_name"
    fi

    for link in "${links[@]}"; do
        if [ -L "$link/$skill_name" ]; then
            continue
        elif [ -e "$link/$skill_name" ]; then
            echo "    ⚠️  $link/$skill_name 不是软链接"
        elif [ -d "$link" ]; then
            echo "    ❌ 缺少 $link/$skill_name"
        fi
    done
done

echo ""
echo "✅ 验证完成！"
