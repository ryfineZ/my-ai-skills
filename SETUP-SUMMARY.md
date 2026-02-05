# 🎉 AI Skills 仓库配置完成总结

本文档记录了 AI Skills 中央仓库的配置方案和使用指南。

**架构版本**: v2.1 - skills add 集成版

---

## ✅ 架构设计

### 核心理念

本方案结合了**中央仓库管理**和 **skills add 工具**的优势：

```
Git 仓库: ~/.agents/skills/ (真实目录)
         ↑
         │ 反向软链接（方便访问）
         │
~/Workspace/my-ai-skills → ~/.agents/skills
         ↑
         │ 自动为各个 agent 创建软链接
         │
  • ~/.claude/skills/skill-name → ../../.agents/skills/skill-name
  • ~/.cursor/skills/skill-name → ../../.agents/skills/skill-name
  • ~/.codex/skills/skill-name → ../../.agents/skills/skill-name
  • ... 及其他 25+ 种 agents
```

### 架构优势

✅ **统一管理** - 所有 skills 存储在一个位置
✅ **Git 同步** - 版本控制，跨设备同步
✅ **社区集成** - 使用 skills add 安装社区 skills
✅ **自动配置** - skills add 自动为所有 agents 创建软链接
✅ **单一副本** - 虽然软链接到多个 agents，但只有一份实际文件

---

## 🚀 快速开始

### 在新设备上设置

```bash
# 1. 克隆仓库
git clone git@github.com:你的用户名/my-ai-skills.git ~/Workspace/my-ai-skills

# 2. 运行设置脚本
bash ~/Workspace/my-ai-skills/setup-universal-skills.sh

# 3. 验证配置
bash ~/Workspace/my-ai-skills/shared/scripts/verify.sh
```

### 工作流程

**安装社区 skills：**
```bash
npx skills add vercel-labs/agent-skills -g
# 自动安装到 ~/Workspace/my-ai-skills/
# 自动为所有 agents 创建软链接
```

**创建自己的 skill：**
```bash
cd ~/Workspace/my-ai-skills
mkdir my-skill
cat > my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: 我的技能描述
---

# 技能内容...
EOF

git add . && git commit -m "feat: 添加 my-skill" && git push
```

---

## 📁 目录结构

```
~/Workspace/my-ai-skills/
├── .git/                           # Git 仓库
├── commit-conventional/            # 你的 skills
├── code-quality-check/
├── agent-rules-sync/
├── create-skill/                   # 创建 skill 的指南工具
├── install-skill/                  # 安装 skill 的管理工具
├── vercel-react-best-practices/    # skills add 安装的
├── web-design-guidelines/          # skills add 安装的
├── shared/
│   └── scripts/
│       ├── install.sh              # 新设备安装脚本
│       ├── verify.sh               # 验证脚本
│       └── update-skills-list.sh   # 更新 skills 列表
├── setup-universal-skills.sh       # 主设置脚本
├── README.md
├── INSTALLED_SKILLS.md             # 已安装的 skills 列表（自动生成）
├── BEST-PRACTICES.md
└── SETUP-SUMMARY.md (本文件)
```

---

## 🔗 软链接架构详解

### 层级关系

```
层级 1 (Git 仓库):
~/.agents/skills/
  ├── skill-a/
  ├── skill-b/
  └── skill-c/

层级 2 (方便访问的软链接):
~/Workspace/my-ai-skills → ~/.agents/skills

层级 3 (各 agent 的 skills):
~/.claude/skills/skill-a/ → ../../.agents/skills/skill-a/
~/.cursor/skills/skill-a/ → ../../.agents/skills/skill-a/
~/.codex/skills/skill-a/ → ../../.agents/skills/skill-a/
```

### 实际效果

- 真实文件在 `~/.agents/skills/skill-a/SKILL.md`
- 通过 `~/Workspace/my-ai-skills/skill-a/SKILL.md` 也可访问（软链接）
- 所有 agents 立即看到更新 ✨
- 只有一份实际文件，节省空间

---

## 🛠️ 脚本说明

### setup-universal-skills.sh

**主设置脚本** - 在新设备上运行

功能：
1. 检查/克隆中央仓库
2. 创建 `~/.agents/skills/<skill>` 的 per-skill 软链接
3. 验证配置

用法：
```bash
bash ~/Workspace/my-ai-skills/setup-universal-skills.sh
```

### shared/scripts/install.sh

**快速安装脚本** - 仅配置软链接

前提：中央仓库已存在

用法：
```bash
bash ~/Workspace/my-ai-skills/shared/scripts/install.sh
```

### shared/scripts/verify.sh

**验证脚本** - 检查配置是否正确

检查项：
- 中央仓库是否存在
- Git 是否初始化
- ~/.agents/skills 是否为目录且每个 skill 软链接是否正确
- 列出所有可用 skills

用法：
```bash
bash ~/Workspace/my-ai-skills/shared/scripts/verify.sh
```

### shared/scripts/update-skills-list.sh

**Skills 列表更新脚本** - 自动维护 INSTALLED_SKILLS.md

功能：
- 扫描所有已安装的 skills
- 从 SKILL.md frontmatter 提取名称和描述
- 自动更新 INSTALLED_SKILLS.md
- 区分自己创建的和社区安装的 skills
- 添加时间戳

用法：
```bash
bash ~/Workspace/my-ai-skills/shared/scripts/update-skills-list.sh
```

**自动更新时机：**
- 创建新 skill 后
- 通过 skills add 安装 skill 后
- 修改 skill 描述后

---

## 🤝 skills add 集成

### 什么是 skills add？

[add-skill](https://github.com/vercel-labs/add-skill) 是 Vercel Labs 开发的官方工具，当前以 `npx skills add` 形式提供，用于从 git 仓库安装 agent skills。

### 支持的 agents

- Claude Code、Codex、Cursor
- Gemini CLI、Antigravity
- Windsurf、Cline、Goose、Trae
- GitHub Copilot、Roo Code
- 及其他 20+ 种工具

### 常用命令

```bash
# 安装所有 skills
npx skills add vercel-labs/agent-skills -g

# 安装特定 skill
npx skills add vercel-labs/agent-skills --skill frontend-design -g

# 列出可用的 skills
npx skills add vercel-labs/agent-skills --list

# 自动确认安装（CI/CD）
npx skills add vercel-labs/agent-skills -g -y
```

### 工作原理

```
1. npx skills add xxx -g
   ↓
2. 从 git 拉取 skills
   ↓
3. 安装到 ~/.agents/skills/<skill>
   ↓
4. 为所有检测到的 agents 创建软链接
```

---

## 📚 与旧版本的区别

### v1.0 (旧版本)

```
~/.claude/skills → ~/Workspace/my-ai-skills
~/.codex/skills → ~/Workspace/my-ai-skills
~/.gemini/skills → ~/Workspace/my-ai-skills
...
```

**问题**：
- ❌ 需要手动维护多个软链接
- ❌ 不兼容 skills add 工具
- ❌ 新 agent 需要手动配置

### v2.1 (当前版本)

```
~/.agents/skills/ (真实目录，Git 仓库)
~/Workspace/my-ai-skills → ~/.agents/skills (反向软链接)
各 agent 自动创建: ~/.xxx/skills/skill-name → ../../.agents/skills/skill-name
```

**优势**：
- ✅ 每个 skill 独立软链接（脚本自动）
- ✅ 完全兼容 skills add
- ✅ 新 agent 自动配置

---

## 🎯 最佳实践

### Skill 管理

**自己的 skills** - 直接在中央仓库创建：
```bash
cd ~/Workspace/my-ai-skills
mkdir my-skill && vim my-skill/SKILL.md

# 更新 skills 列表
bash shared/scripts/update-skills-list.sh

# 提交
git add my-skill/ INSTALLED_SKILLS.md
git commit -m "feat: 添加 my-skill"
git push
```

**社区 skills** - 使用 skills add 安装：
```bash
# 安装
npx skills add vercel-labs/agent-skills --skill xxx -g

# 更新列表
cd ~/Workspace/my-ai-skills
bash shared/scripts/update-skills-list.sh

# 提交
git add xxx/ INSTALLED_SKILLS.md
git commit -m "feat: 安装 xxx skill"
git push
```

**查看已安装的 skills：**
```bash
cat ~/Workspace/my-ai-skills/INSTALLED_SKILLS.md
```

### Git 工作流

```bash
# 开发新 skill
cd ~/Workspace/my-ai-skills
mkdir new-skill && vim new-skill/SKILL.md

# 测试
# (在 Claude Code / Cursor 等工具中测试)

# 提交
git add new-skill
git commit -m "feat: 添加 new-skill"
git push

# 同步到其他设备
# (在其他设备上)
cd ~/Workspace/my-ai-skills && git pull
```

---

## 🔧 故障排除

### Skills 未被识别

```bash
# 1. 检查软链接
ls -la ~/.agents/skills
# 应该看到每个 skill 的软链接或目录

# 2. 运行验证脚本
bash ~/Workspace/my-ai-skills/shared/scripts/verify.sh

# 3. 重新设置
bash ~/Workspace/my-ai-skills/setup-universal-skills.sh
```

### skills add 安装失败

```bash
# 检查 ~/.agents/skills 是否为目录
ls -la ~/.agents/skills

# 重新创建 per-skill 软链接
bash ~/Workspace/my-ai-skills/shared/scripts/install.sh
```

### Git 推送/拉取问题

**SSH 方式**：
```bash
# 测试连接
ssh -T git@github.com

# 添加 SSH 公钥
# https://github.com/settings/ssh/new
```

**HTTPS 方式**：
```bash
# 使用 Personal Access Token
# https://github.com/settings/tokens/new
```

---

## 📖 相关文档

- **README.md** - 快速入门和使用指南
- **INSTALLED_SKILLS.md** - 已安装的 skills 列表（自动生成和维护）
- **BEST-PRACTICES.md** - 创建跨工具兼容的 skills
- **GITHUB-PUSH-GUIDE.md** - GitHub 推送指南

---

## 📞 FAQ

**Q: 为什么要用 skills add？**
A: skills add 是官方标准工具，自动管理多平台软链接，节省手动配置时间。

**Q: 会不会安装多份 skills？**
A: 不会！skills add 为各 agents 创建软链接，实际文件只在 `~/.agents/skills` 或中央仓库保留一份。

**Q: 如何更新社区 skills？**
A: 重新运行 `npx skills add vercel-labs/agent-skills --skill xxx -g` 即可。

**Q: 如何删除不需要的 skill？**
A:
```bash
cd ~/Workspace/my-ai-skills
rm -rf skill-name

# 更新列表
bash shared/scripts/update-skills-list.sh

# 提交
git add . && git commit -m "remove: skill-name" && git push
```

**Q: 如何在团队中共享 skills？**
A:
1. 推送到 GitHub（私有仓库）
2. 团队成员克隆仓库
3. 运行 setup-universal-skills.sh
4. 也可以发布公开仓库，其他人用 `npx skills add 你的用户名/my-ai-skills` 安装

---

**版本**: v2.0
**更新时间**: 2026-01-26
**状态**: ✅ 完成
