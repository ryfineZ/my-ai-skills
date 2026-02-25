# 🎯 我的 AI Skills 仓库

统一管理所有 AI 编码工具的 Skills（基于 Agent Skills 标准）。

**兼容 npx skills add** - 可安装社区 skills 并自动同步。

**当前权威目录**：`~/.agents/skills`（真实 Git 仓库）  
**便捷入口**：`~/Workspace/my-ai-skills -> ~/.agents/skills`（软链接）

## 架构设计

本仓库采用反向软链接 + skills add 集成的方式：

```
Git 仓库: ~/.agents/skills/ (真实目录)
         ↑
         │ (反向软链接，方便访问)
         │
~/Workspace/my-ai-skills → ~/.agents/skills
         ↑
         │ (skills add 自动为各 agent 建立软链接)
         │
~/.claude/skills/skill-name → ../../.agents/skills/skill-name
~/.codex/skills/skill-name → ../../.agents/skills/skill-name
~/.cursor/skills/skill-name → ../../.agents/skills/skill-name
...等所有支持的 agents
```

**优势：**
- ✅ Git 仓库在 `~/.agents/skills`（真实目录，版本控制）
- ✅ `~/Workspace/my-ai-skills` 反向软链接，方便访问和编辑
- ✅ skills add 自动为所有平台创建软链接
- ✅ Git 跨设备同步
- ✅ 兼容 25+ 种 coding agents

## 支持的工具

通过 skills add 自动支持：
- ✅ Claude Code、Codex、Cursor
- ✅ Gemini CLI、Antigravity
- ✅ Windsurf、Cline、Goose
- ✅ GitHub Copilot、Roo Code
- ✅ 及其他 20+ 种工具

## 快速开始

### 在新电脑上设置

```bash
# 1. 克隆仓库到权威目录
git clone git@github.com:你的用户名/my-ai-skills.git ~/.agents/skills

# 2. 运行设置脚本（一键配置）
bash ~/.agents/skills/setup-universal-skills.sh

# 3. 验证（脚本会自动创建 ~/Workspace/my-ai-skills 软链接）
bash ~/Workspace/my-ai-skills/shared/scripts/verify.sh
```

### 安装社区 Skills

```bash
# 使用 skills add 安装
npx skills add vercel-labs/agent-skills -g

# 安装特定 skill
npx skills add vercel-labs/agent-skills --skill frontend-design -g

# 列出可用的社区 skills
npx skills add vercel-labs/agent-skills --list
```

### 创建自己的 Skill

```bash
cd ~/Workspace/my-ai-skills
mkdir -p my-skill
cat > my-skill/SKILL.md << 'SKILL_EOF'
---
name: my-skill
description: 我的 Skill 描述
---

# My Skill

Skill 内容...
SKILL_EOF

# 刷新各平台 per-skill 软链接（让新 skill 立即可见）
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"

# 更新 skills 列表
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"

# 提交到 Git
git add my-skill/ INSTALLED_SKILLS.md
git commit -m "feat: 添加 my-skill"
git push
```

## 工作流程

### 日常使用

```bash
# 安装社区 skills
npx skills add vercel-labs/agent-skills -g

# 创建自己的 skill
cd ~/Workspace/my-ai-skills
mkdir new-skill && vim new-skill/SKILL.md
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"

# 提交到 Git
git add . && git commit -m "feat: 添加新 skill" && git push
```

### 跨设备同步

```bash
# 在新设备上
git clone git@github.com:你的用户名/my-ai-skills.git ~/.agents/skills
bash ~/.agents/skills/setup-universal-skills.sh

# 在旧设备上同步
cd ~/Workspace/my-ai-skills
git pull
```

## 验证配置

```bash
# 验证设置是否正确
bash ~/Workspace/my-ai-skills/shared/scripts/verify.sh
```

## 文档

- [已安装的 Skills](INSTALLED_SKILLS.md) - 查看所有已安装的 skills（自动更新）
- [最佳实践](BEST-PRACTICES.md) - 创建跨工具兼容的 Skills
- [设置总结](SETUP-SUMMARY.md) - 详细的设置说明

## 与中央仓库关联的关键 Skills

### install-skill
用于封装 `npx skills add` 的安装/更新流程（支持全局/项目级），并在全局安装后自动尝试更新 `INSTALLED_SKILLS.md`。  
安装和更新都会执行强制安全审计（远程预审 + 本地深扫）。

常用命令：
```bash
# 全局安装（共享到所有项目）
bash ~/.agents/skills/install-skill/install-skill.sh \
  vercel-labs/agent-skills --skill frontend-design --global

# 项目级安装（仅当前项目）
bash ~/.agents/skills/install-skill/install-skill.sh \
  anthropics/skills --skill planning
```

### skill-security-guard
用于对 skill 执行安装前安全审计，并输出 `SAFE/CAUTION/REVIEW/BLOCK` 结论。

常用命令：
```bash
# 本地目录扫描
python3 ~/.agents/skills/skill-security-guard/scripts/skill_security_guard.py \
  --min-severity high local --path ~/.agents/skills/some-skill

# GitHub 仓库扫描
python3 ~/.agents/skills/skill-security-guard/scripts/skill_security_guard.py \
  --min-severity high github --repo owner/repo
```

### create-skill
用于创建和维护自定义 skill（模板初始化、校验、打包）。

常用命令：
```bash
# 1) 初始化新 skill 目录
python3 ~/.agents/skills/create-skill/scripts/init_skill.py \
  my-skill --path ~/.agents/skills

# 2) 校验
python3 ~/.agents/skills/create-skill/scripts/quick_validate.py \
  ~/.agents/skills/my-skill

# 3) 打包（可选）
python3 ~/.agents/skills/create-skill/scripts/package_skill.py \
  ~/.agents/skills/my-skill ./dist

# 4) 刷新多平台链接 + 更新列表
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
```

## 当前 Skills

📋 查看完整的 skills 列表：**[INSTALLED_SKILLS.md](INSTALLED_SKILLS.md)**

该文档由脚本自动维护，包含所有已安装 skills 的详细信息（用途、位置、来源等）。

## 技术细节

### 目录结构

```
~/Workspace/my-ai-skills/
├── .git/                           # Git 仓库
├── commit-conventional/            # 你的 skills
├── code-quality-check/
├── create-skill/                   # 创建 skill 的指南工具
├── install-skill/                  # 安装 skill 的管理工具
├── skill-security-guard/           # skill 安全扫描与门禁
├── vercel-react-best-practices/    # skills add 安装的
├── web-design-guidelines/          # skills add 安装的
├── shared/
│   └── scripts/
│       ├── install.sh              # 新设备安装脚本
│       ├── skill-security-ci.sh    # 中央仓库安全门禁 CI
│       ├── verify.sh               # 验证脚本
│       └── update-skills-list.sh   # 更新 skills 列表
├── setup-universal-skills.sh       # 主设置脚本
├── README.md
├── INSTALLED_SKILLS.md             # 已安装的 skills 列表（自动生成）
├── BEST-PRACTICES.md
└── SETUP-SUMMARY.md
```

### 软链接架构

```
~/.agents/skills/                   (真实目录，Git 仓库)
         ↑
~/Workspace/my-ai-skills -> ~/.agents/skills (反向软链接)
         ↑
~/.claude/skills/skill-name -> ../../.agents/skills/skill-name
~/.cursor/skills/skill-name -> ../../.agents/skills/skill-name
...
```

## Skills 管理工具

本仓库包含两个辅助工具来管理 skills：

### install-skill
用于通过 `npx skills add` 安装和管理社区 skills。

**触发方式：** 对话中说"安装 XXX skill"

**功能：**
- 从 vercel-labs/agent-skills 等仓库安装 skills
- 支持全局安装（`-g`）和项目级安装
- 安装和更新均强制执行安全检查（skill-security-guard）
- 自动更新 INSTALLED_SKILLS.md
- 提醒提交到 Git

### skill-security-ci
用于中央仓库 PR/提交的自动安全门禁，输出 JSON/SARIF 并按阈值阻断高危变更。

手动执行：
```bash
bash ~/.agents/skills/shared/scripts/skill-security-ci.sh \
  --scope all --threshold high --output-dir ~/.agents/skills/.artifacts/skill-security
```

### create-skill
用于创建新的自定义 skills。

**触发方式：** 对话中说"创建新 skill"

**功能：**
- 提供 skill 创建指导
- 支持全局目录与项目目录两种创建方式（通过 `init_skill.py --path` 指定）
- 遵循最佳实践
- 支持校验与打包流程（`quick_validate.py` / `package_skill.py`）

## FAQ

**Q: install-skill 和手动创建的区别？**
- install-skill：使用 npx skills add 从社区安装，自动管理软链接
- 手动创建：你自己的 skills，直接在 ~/.agents/skills 或项目目录创建

**Q: 会不会安装多份？**
- 不会！所有 skills 都在 `~/.agents/skills`（真实目录），`~/Workspace/my-ai-skills` 只是软链接

**Q: 如何查看已安装的 skills？**
```bash
# 查看详细列表
cat ~/Workspace/my-ai-skills/INSTALLED_SKILLS.md

# 或者在对话中说
"列出已安装的 skills"
```

**Q: 如何更新社区 skills？**
```bash
npx skills add vercel-labs/agent-skills --skill skill-name -g
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
```

**Q: 如何删除 skill？**
```bash
cd ~/Workspace/my-ai-skills
rm -rf skill-name
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
git add . && git commit -m "remove: skill-name" && git push
```

## 相关链接

- [add-skill 工具](https://github.com/vercel-labs/add-skill)
- [Vercel Agent Skills](https://github.com/vercel-labs/agent-skills)
- [Agent Skills 标准](https://vercel-labs.github.io/agent-skills/)
