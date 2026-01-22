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
