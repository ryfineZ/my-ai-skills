---
name: install-skill
description: Install or update skills from GitHub repositories. Supports global installation (to ~/.agents/skills, shared across projects) and project-level installation (to ./.agents/skills, project-specific). Enforces security checks before and after install/update with skill-security-guard. Use when installing from vercel-labs/agent-skills, anthropics/skills, or custom repos.
---

# Install Skill

安装 skills，支持全局和项目级两种模式。
安装和更新都会执行两次安全检查：远程预审 + 本地深扫。

默认目标是**中央仓库** `~/.agents/skills`。只有用户明确要求“项目级 / 当前项目专用 / 本地临时”时，才应改为 `./.agents/skills`。

安装完成后，**由当前执行该 skill 的 AI** 直接生成并写入元数据（不依赖 API key）：
- `用途`：中文一句话
- `触发关键词`：5-10 个
- `来源`：安装仓库（`source_repo`）
- `来源类型`：例如 `single` / `bundle`
- `更新分组`：例如 `update_group`

如果某个包的来源元数据或上游文档表明 **Claude Code 应通过插件安装**，则：
- 中央仓库仍然要安装并维护这批 skill
- 不应再把它们发布到 `~/.claude/skills`
- 全局安装时，如本机可用 Claude Code，应继续自动执行对应插件的安装 / 启用，而不是只给提示

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

## AI 后处理（必须）

安装脚本成功后，当前 AI 需基于该 skill 的 `SKILL.md` 生成中文用途与关键词，并写回：

```bash
python3 ~/.agents/skills/install-skill/scripts/set_skill_meta.py \
    --skill-dir ~/.agents/skills/<skill-name> \
    --repo <owner/repo> \
    --usage-zh "<中文用途一句话>" \
    --keywords "<关键词1>、<关键词2>、<关键词3>"
```

然后刷新列表：

```bash
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
```

## 安全检查（强制）

`install-skill.sh` 现在会自动执行：

1. **远程预审**：扫描 `owner/repo`（高危阈值）  
2. **本地深扫**：扫描安装后的 skill 目录（高危阈值）

任一步骤发现高危/严重风险会直接终止流程。
本地深扫失败时默认执行自动回滚（安装删除新目录，更新恢复旧版本）。
可通过 `--no-rollback-on-fail` 显式关闭回滚。

## 架构说明

### 全局模式
```
~/.agents/skills/           (真实目录，Git 仓库)
~/Workspace/my-ai-skills -> ~/.agents/skills  (软链接)
~/.claude/skills/skill-name -> ../../.agents/skills/skill-name
```

补充规则：
- `install-skill` 默认面向中央仓库，不面向当前客户端私有目录
- 若 `platform_policies.claude_code.install=plugin`，则全局安装完成后会尝试自动为 Claude Code 安装 / 启用插件
- 若该包不应发布为 Claude standalone skill，则 `~/.claude/skills` 中不会出现对应顶层链接

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
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
```

## 常见仓库

- **vercel-labs/agent-skills** - Vercel 官方 skills
- **anthropics/skills** - Anthropic 官方 skills
- **openai/skills** - OpenAI 官方 skills
