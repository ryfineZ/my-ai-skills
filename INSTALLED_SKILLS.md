# 📦 已安装的 Skills 列表

> 本文档由 `shared/scripts/update-skills-list.sh` 自动生成和维护
> 文件名：`INSTALLED_SKILLS.md` - 避免与各 skill 目录中的 `SKILL.md` 混淆
> 最后更新：2026-01-25 17:47:58

---

## 🎨 自己创建的 Skills

### add-skill
**用途：** Install and manage skills using npx add-skill. Use when users want to (1) install a specific skill, (2) install from custom GitHub repos, (3) update existing skills, or (4) browse available skills from vercel-labs/agent-skills or other repos for installation. 当用户说"安装 skill"、"更新 skill"、"从 XX 安装 skill"时触发。

**位置：** `~/Workspace/my-ai-skills/add-skill/`

---

### agent-browser
**用途：** Automates browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, test web applications, or extract information from web pages.

**位置：** `~/Workspace/my-ai-skills/agent-browser/`

---

### agent-rules-sync
**用途：** 统一多平台全局规则管理（AGENTS/CLAUDE/GEMINI）。触发语义包含“新增一条全局规则”“新增全局规则”“把这句话写入全局规则”等明确写入指令；用于新增/修改规则并同步到 Claude/Codex/Gemini/Antigravity。若是讨论性提问（如“要不要写入全局规则？”）则不触发。

**位置：** `~/Workspace/my-ai-skills/agent-rules-sync/`

---

### code-quality-check
**用途：** 通用代码质量检查。在提交代码前自动执行，根据项目类型应用对应的检查规则

**位置：** `~/Workspace/my-ai-skills/code-quality-check/`

---

### commit-conventional
**用途：** 执行 git commit 创建符合约定式提交规范的提交。仅当用户明确要求"提交代码"、"创建提交"、"帮我commit"、"git commit"等执行提交操作时使用。不要在仅仅讨论提交、询问提交规范、或解释如何提交时触发

**位置：** `~/Workspace/my-ai-skills/commit-conventional/`

---

### frontend-design
**用途：** Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, or applications. Generates creative, polished code that avoids generic AI aesthetics.

**位置：** `~/Workspace/my-ai-skills/frontend-design/`

---

### skill-creator
**用途：** Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. 用于创建新技能、构建skill、制作自定义技能等场景。

**位置：** `~/Workspace/my-ai-skills/skill-creator/`

---

## 🌐 社区安装的 Skills

### vercel-react-best-practices
**用途：** React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns. Triggers on tasks involving React components, Next.js pages, data fetching, bundle optimization, or performance improvements.

**来源：** vercel-labs/agent-skills

**位置：** `~/Workspace/my-ai-skills/vercel-react-best-practices/`

---

### web-design-guidelines
**用途：** Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices".

**来源：** vercel-labs/agent-skills

**位置：** `~/Workspace/my-ai-skills/web-design-guidelines/`

---

## 📊 统计信息

- **总计：** 9 个 skills
- **自己创建：** 7 个
- **社区安装：** 2 个

---

## 🔄 如何更新此列表

```bash
# 手动更新
bash ~/Workspace/my-ai-skills/shared/scripts/update-skills-list.sh

# 自动更新时机
# 1. 创建新 skill 后
# 2. 安装新 skill 后
# 3. 修改 skill 描述后
```
