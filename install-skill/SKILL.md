---
name: install-skill
description: Install skills from GitHub repositories. Supports global installation (to ~/.agents/skills, shared across projects) and project-level installation (to ./.agents/skills, project-specific). Use when installing from vercel-labs/agent-skills, anthropics/skills, or custom repos.
---

# Install Skill

安装 skills，支持全局和项目级两种模式。

## 快速使用

### 全局安装（跨项目共享）

```bash
bash ~/.agents/skills/install-skill/install-skill.sh \
    vercel-labs/agent-skills --skill frontend-design --global
```

### 项目级安装（仅当前项目）

```bash
cd /path/to/project
bash ~/.agents/skills/install-skill/install-skill.sh \
    anthropics/skills --skill planning
```

## 架构说明

### 全局模式
```
~/.agents/skills/           (真实目录，Git 仓库)
~/Workspace/my-ai-skills -> ~/.agents/skills  (软链接)
~/.claude/skills/skill-name -> ../../.agents/skills/skill-name
```

### 项目级模式
```
/project/.agents/skills/skill-name/  (真实目录)
/project/.claude/skills/skill-name -> ../../.agents/skills/skill-name
```

## 对比

| 特性 | 全局 (-g) | 项目级 (无 -g) |
|------|----------|---------------|
| 位置 | ~/.agents/skills | ./.agents/skills |
| 共享 | 所有项目 | 仅当前项目 |
| Git | 统一仓库管理 | 可选（项目仓库） |
| 列表更新 | ✅ 自动 | ❌ 不需要 |

## 直接使用 npx skills add

如果你想直接使用官方工具：

```bash
# 全局安装（非交互式）
npx skills add vercel-labs/agent-skills --skill frontend-design -y -g

# 项目级安装（非交互式）
npx skills add anthropics/skills --skill planning -y

# 全局安装后更新列表
bash ~/.agents/skills/shared/scripts/update-skills-list.sh
```

## 常见仓库

- **vercel-labs/agent-skills** - Vercel 官方 skills
- **anthropics/skills** - Anthropic 官方 skills
- **openai/skills** - OpenAI 官方 skills
