#!/bin/bash
# install.sh - 在新电脑上自动配置 Skills

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "🚀 开始配置 AI Skills..."
echo "Skills 目录: $SKILLS_DIR"
echo ""

# 配置所有 AI 工具
tools=("claude" "codex" "gemini" "antigravity")

for tool in "${tools[@]}"; do
    tool_dir="$HOME/.$tool"
    skill_link="$tool_dir/skills"

    mkdir -p "$tool_dir"

    # 备份已存在的非软链接目录
    if [ -e "$skill_link" ] && [ ! -L "$skill_link" ]; then
        backup_dir="$HOME/skills-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        mv "$skill_link" "$backup_dir/${tool}-skills"
        echo "📦 备份旧 Skills: $backup_dir/${tool}-skills"
    fi

    # 创建软链接
    ln -sf "$SKILLS_DIR" "$skill_link"
    echo "✅ .$tool/skills -> $SKILLS_DIR"
done

echo ""
echo "✅ 配置完成！"
echo ""
echo "📊 验证："
for tool in "${tools[@]}"; do
    if [ -L "$HOME/.$tool/skills" ]; then
        echo "  ✅ .$tool/skills"
    fi
done
