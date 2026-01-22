#!/bin/bash
# setup-universal-skills.sh - 一键配置跨工具 Skills 同步
# 支持：Claude Code、Codex、Gemini、Antigravity、GitHub Copilot

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
SKILLS_DIR="${SKILLS_DIR:-$HOME/AI-Skills}"
BACKUP_DIR="$HOME/ai-skills-backup-$(date +%Y%m%d-%H%M%S)"
USE_GIT="${USE_GIT:-true}"
USE_CLOUD_SYNC="${USE_CLOUD_SYNC:-false}"
CLOUD_DIR="${CLOUD_DIR:-$HOME/Dropbox/AI-Skills}"

echo -e "${BLUE}🚀 开始配置统一 AI Skills 仓库...${NC}"
echo ""

# ============================================
# 步骤 1：创建中央仓库
# ============================================
echo -e "${YELLOW}📁 步骤 1/5: 创建中央 Skills 仓库${NC}"

if [ "$USE_CLOUD_SYNC" = "true" ]; then
    SKILLS_DIR="$CLOUD_DIR"
    echo "使用云同步目录: $SKILLS_DIR"
fi

mkdir -p "$SKILLS_DIR"
echo -e "${GREEN}✅ 中央仓库已创建: $SKILLS_DIR${NC}"
echo ""

# ============================================
# 步骤 2：备份和迁移现有 Skills
# ============================================
echo -e "${YELLOW}📦 步骤 2/5: 备份和迁移现有 Skills${NC}"

MIGRATED=false

for tool_dir in "$HOME/.claude" "$HOME/.codex" "$HOME/.gemini" "$HOME/.antigravity"; do
    skills_path="$tool_dir/skills"

    if [ -d "$skills_path" ] && [ ! -L "$skills_path" ]; then
        tool_name=$(basename "$tool_dir" | sed 's/^\.//')
        echo "发现 $tool_name Skills: $skills_path"

        # 备份
        mkdir -p "$BACKUP_DIR"
        cp -r "$skills_path" "$BACKUP_DIR/${tool_name}-skills"
        echo "  ✅ 已备份到: $BACKUP_DIR/${tool_name}-skills"

        # 迁移到中央仓库
        for skill in "$skills_path"/*; do
            if [ -d "$skill" ] && [ -f "$skill/SKILL.md" ]; then
                skill_name=$(basename "$skill")
                if [ ! -d "$SKILLS_DIR/$skill_name" ]; then
                    cp -r "$skill" "$SKILLS_DIR/"
                    echo "  📦 迁移: $skill_name"
                    MIGRATED=true
                fi
            fi
        done

        # 删除旧目录
        rm -rf "$skills_path"
    fi
done

if [ "$MIGRATED" = "true" ]; then
    echo -e "${GREEN}✅ Skills 迁移完成${NC}"
else
    echo "没有发现需要迁移的 Skills"
fi
echo ""

# ============================================
# 步骤 3：配置所有 AI 工具
# ============================================
echo -e "${YELLOW}🔗 步骤 3/5: 配置 AI 工具软链接${NC}"

# 支持的工具列表
TOOLS=("claude" "codex" "gemini" "antigravity")

for tool in "${TOOLS[@]}"; do
    tool_dir="$HOME/.$tool"
    skills_link="$tool_dir/skills"

    # 创建工具配置目录
    mkdir -p "$tool_dir"

    # 创建软链接
    if [ -L "$skills_link" ]; then
        # 已存在软链接，更新它
        rm "$skills_link"
    elif [ -e "$skills_link" ]; then
        # 存在但不是软链接，跳过（已在步骤2处理）
        echo -e "${YELLOW}⚠️  $tool: skills 目录已存在但不是软链接${NC}"
        continue
    fi

    ln -sf "$SKILLS_DIR" "$skills_link"
    echo -e "${GREEN}✅ $tool${NC}: ~/.${tool}/skills -> $SKILLS_DIR"
done

echo ""

# ============================================
# 步骤 4：初始化 Git 仓库
# ============================================
if [ "$USE_GIT" = "true" ]; then
    echo -e "${YELLOW}🎯 步骤 4/5: 初始化 Git 仓库${NC}"

    cd "$SKILLS_DIR"

    if [ ! -d ".git" ]; then
        git init

        # 创建 .gitignore
        cat > .gitignore << 'EOF'
# 临时文件
*.tmp
*.log
.DS_Store

# 私密配置
secrets/
*.secret
*.env

# 编辑器
.vscode/
.idea/
EOF

        # 创建 README
        cat > README.md << 'EOF'
# 🎯 我的 AI Skills 仓库

统一管理所有 AI 编码工具的 Skills（基于 Agent Skills 标准）。

## 支持的工具
- ✅ Claude Code CLI
- ✅ Codex CLI
- ✅ Gemini CLI
- ✅ Google Antigravity IDE
- ✅ GitHub Copilot
- ✅ VS Code 插件（Claude/Codex/Gemini）

## 快速开始

### 在新电脑上设置

```bash
# 克隆仓库
git clone git@github.com:你的用户名/my-ai-skills.git ~/AI-Skills

# 运行安装脚本
bash ~/AI-Skills/shared/scripts/install.sh
```

### 创建新 Skill

```bash
cd ~/AI-Skills
mkdir -p my-skill
cat > my-skill/SKILL.md << 'SKILL_EOF'
---
name: my-skill
description: 我的 Skill 描述
---

# My Skill

Skill 内容...
SKILL_EOF

git add my-skill/
git commit -m "feat: 添加 my-skill"
git push
```

## 同步机制

通过软链接实现跨工具共享：

```
~/.claude/skills -> ~/AI-Skills
~/.codex/skills -> ~/AI-Skills
~/.gemini/skills -> ~/AI-Skills
~/.antigravity/skills -> ~/AI-Skills
```

## 文档

- [最佳实践](BEST-PRACTICES.md) - 创建跨工具兼容的 Skills
- [兼容性说明](commit-conventional/COMPATIBILITY.md) - 功能兼容性参考

## 维护

```bash
# 更新 Skills
cd ~/AI-Skills
git pull

# 提交新 Skill
git add .
git commit -m "feat: 添加新 Skill"
git push
```
EOF

        # 创建安装脚本目录
        mkdir -p shared/scripts

        # 创建安装脚本
        cat > shared/scripts/install.sh << 'INSTALL_EOF'
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
INSTALL_EOF

        chmod +x shared/scripts/install.sh

        # 创建验证脚本
        cat > shared/scripts/verify.sh << 'VERIFY_EOF'
#!/bin/bash
# verify.sh - 验证 Skills 配置

echo "🔍 验证 AI Skills 配置..."
echo ""

SKILLS_DIR="$HOME/AI-Skills"

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
echo "🔗 工具链接状态："

for tool in claude codex gemini antigravity; do
    link="$HOME/.$tool/skills"
    if [ -L "$link" ]; then
        target=$(readlink "$link")
        if [ "$target" = "$SKILLS_DIR" ]; then
            echo "✅ .$tool/skills -> $SKILLS_DIR"
        else
            echo "⚠️  .$tool/skills -> $target (指向其他位置)"
        fi
    else
        echo "❌ .$tool/skills (不是软链接或不存在)"
    fi
done

echo ""
echo "📋 可用 Skills："
find "$SKILLS_DIR" -name "SKILL.md" | while read skill; do
    skill_name=$(basename "$(dirname "$skill")")
    desc=$(grep "^description:" "$skill" 2>/dev/null | head -1 | sed 's/description: *//' || echo "无描述")
    echo "  - $skill_name: $desc"
done

echo ""
echo "✅ 验证完成！"
VERIFY_EOF

        chmod +x shared/scripts/verify.sh

        # 提交
        git add .
        git commit -m "feat: 初始化统一 AI Skills 仓库" || true

        echo -e "${GREEN}✅ Git 仓库初始化完成${NC}"
    else
        echo "Git 仓库已存在，跳过初始化"
    fi
else
    echo "跳过 Git 初始化（USE_GIT=false）"
fi

echo ""

# ============================================
# 步骤 5：验证配置
# ============================================
echo -e "${YELLOW}🔍 步骤 5/5: 验证配置${NC}"

echo ""
echo "中央仓库："
echo "  位置: $SKILLS_DIR"
if [ -d "$SKILLS_DIR/.git" ]; then
    echo "  Git: ✅ 已初始化"
else
    echo "  Git: ❌ 未初始化"
fi

skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l)
echo "  Skills: $skill_count 个"

echo ""
echo "工具链接："
for tool in claude codex gemini antigravity; do
    link="$HOME/.$tool/skills"
    if [ -L "$link" ]; then
        echo "  ✅ .$tool/skills"
    else
        echo "  ⚠️  .$tool/skills (未配置)"
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 配置完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$MIGRATED" = "true" ]; then
    echo -e "${BLUE}📦 备份位置: $BACKUP_DIR${NC}"
fi

echo ""
echo -e "${BLUE}💡 下一步：${NC}"
echo ""
echo "1. 验证配置："
echo "   bash $SKILLS_DIR/shared/scripts/verify.sh"
echo ""
echo "2. 推送到 GitHub："
echo "   cd $SKILLS_DIR"
echo "   git remote add origin git@github.com:你的用户名/my-ai-skills.git"
echo "   git push -u origin main"
echo ""
echo "3. 在其他电脑上同步："
echo "   git clone git@github.com:你的用户名/my-ai-skills.git ~/AI-Skills"
echo "   bash ~/AI-Skills/shared/scripts/install.sh"
echo ""
echo -e "${YELLOW}📚 文档：${NC}"
echo "   - 最佳实践: $SKILLS_DIR/BEST-PRACTICES.md"
echo "   - 兼容性说明: $SKILLS_DIR/commit-conventional/COMPATIBILITY.md"
echo ""
