# 📦 已安装的 Skills 列表

> 本文档由 `shared/scripts/update-skills-list.sh` 自动生成和维护
> 文件名：`INSTALLED_SKILLS.md` - 避免与各 skill 目录中的 `SKILL.md` 混淆
> 用途/触发关键词：优先由 AI 自动生成中文（可按需手动补充）
> 最后更新：2026-03-28 19:42:31

---

## 🎨 自己创建的 Skills

### agent-rules-sync
**用途：** 统一多平台全局规则管理（AGENTS/CLAUDE/GEMINI）
**触发关键词：** agent-rules-sync、统一多平台全局规则管理、若是讨论性提问、如“要不要写入全局规则？”、则不触发

**位置：** `/Users/zhangyufan/.agents/skills/agent-rules-sync/`

---

### aigc-v1
**用途：** 论文/技术文档风格改写，让表达更解释性、更像学术写作
**触发关键词：** 论文润色、技术文档改写、学术写作、AI检测规避、词汇替换

**位置：** `/Users/zhangyufan/.agents/skills/aigc-v1/`

---

### code-quality-check
**用途：** 通用代码质量检查
**触发关键词：** code-quality-check、代码质量、通用代码质量检查、提交代码前自动执行

**位置：** `/Users/zhangyufan/.agents/skills/code-quality-check/`

---

### commit-conventional
**用途：** 执行 git commit 创建符合约定式提交规范的提交
**触发关键词：** commit-conventional、约定式提交、仅当用户明确要求"提交代码、创建提交、不要在仅仅讨论提交、询问提交规范、或解释如何提交时触发

**位置：** `/Users/zhangyufan/.agents/skills/commit-conventional/`

---

### create-skill
**用途：** Guide for creating effective skills
**触发关键词：** create-skill、制作自定义技能等场景

**位置：** `/Users/zhangyufan/.agents/skills/create-skill/`

---

### doctor-skills
**用途：** 诊断中央 skills 仓库状态，并在需要时执行轻量修复。
**触发关键词：** doctor-skills、仓库诊断、verify.sh、skill-source.json、平台链接、轻量修复

**位置：** `/Users/zhangyufan/.agents/skills/doctor-skills/`

---

### humanizer-zh
**用途：** 去除 AI 写作痕迹，使文本更自然有人味
**触发关键词：** 去除AI痕迹、去AI味、人性化文本、改写AI文章、降低AI检测、AI写作模式

**位置：** `/Users/zhangyufan/.agents/skills/humanizer-zh/`

---

### install-skill
**用途：** 用于安装和更新 skill、执行 skill 安全审计与风险拦截。
**触发关键词：** install-skill、安装 skill、更新 skill、GitHub 仓库、安全审计、风险扫描、Prompt Injection、GitHub、agents/skills、project-specific

**位置：** `/Users/zhangyufan/.agents/skills/install-skill/`

---

### skill-security-guard
**用途：** 对本地或 GitHub 上的 AI skill 执行安装前安全审计，检测提示词劫持、下载执行、凭证窃取、数据外传、持久化与提权风险，并输出...
**触发关键词：** skill-security-guard、安全审计、提示词劫持、下载执行、凭证窃取、数据外传、持久化、提权风险、风险结论、安装前审计

**位置：** `/Users/zhangyufan/.agents/skills/skill-security-guard/`

---

### uninstall-skill
**用途：** 删除中央仓库中的已安装 skill，并同步清理平台发布结果与已安装列表。
**触发关键词：** uninstall-skill、卸载 skill、删除 skill、bundle 清理、平台清理、INSTALLED_SKILLS

**位置：** `/Users/zhangyufan/.agents/skills/uninstall-skill/`

---

### update-skill
**用途：** 按 .skill-source.json 回放来源信息，更新已安装 skill，并支持 bundle 分组更新。
**触发关键词：** update-skill、更新 skill、bundle 更新、update_group、skill-source.json、已安装 skills

**位置：** `/Users/zhangyufan/.agents/skills/update-skill/`

---

## 🌐 社区安装的 Skills

### agent-browser
**用途：** 用于自动化浏览器交互与网页数据提取。
**触发关键词：** agent-browser、浏览器自动化、网页测试、截图、数据提取

**来源：** vercel-labs/agent-browser

**位置：** `/Users/zhangyufan/.agents/skills/agent-browser/`

---

### brainstorming
**用途：** 用于设计和审查前端界面与交互体验。
**触发关键词：** brainstorming、前端设计、UI、UX、组件、MUST

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/brainstorming/`

---

### chrome-cdp
**用途：** 连接本地运行中的 Chrome 浏览器会话，查看/截图/交互已打开的页面
**触发关键词：** Chrome调试、CDP、浏览器截图、页面交互、DOM查看、实时会话、远程调试

**来源：** pasky/chrome-cdp-skill

**位置：** `/Users/zhangyufan/.agents/skills/chrome-cdp/`

---

### deep-research
**用途：** 执行多步骤深度调研，并输出结构化、带引用的研究报告。
**触发关键词：** deep-research、深度调研、Gemini、带引用报告、competitive landscaping、due diligence

**来源：** sanjay3290/ai-skills

**位置：** `/Users/zhangyufan/.agents/skills/deep-research/`

---

### dispatching-parallel-agents
**用途：** 用于 dispatching-parallel-agents：Use when facing 2+ independent tasks that...
**触发关键词：** dispatching-parallel-agents、dispatching-parallel-

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/dispatching-parallel-agents/`

---

### executing-plans
**用途：** 用于 executing-plans：Use when you have a written implementatio...
**触发关键词：** executing-plans、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/executing-plans/`

---

### find-skills
**用途：** 用于安装和更新 skill。
**触发关键词：** find-skills、安装 skill、更新 skill、GitHub 仓库

**来源：** vercel-labs/skills

**位置：** `/Users/zhangyufan/.agents/skills/find-skills/`

---

### finishing-a-development-branch
**用途：** 用于 finishing-a-development-branch：Use when implementation is complete, all...
**触发关键词：** finishing-a-development-branch、finishing-a-developme、nt-branch、PR

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/finishing-a-development-branch/`

---

### frontend-design
**用途：** 用于设计和审查前端界面与交互体验。
**触发关键词：** frontend-design、前端设计、UI、UX、组件、production-grade、AI

**来源：** anthropics/skills

**位置：** `/Users/zhangyufan/.agents/skills/frontend-design/`

---

### gh-address-comments
**用途：** 用于定位当前分支对应的 GitHub PR 评论，并通过 gh CLI 处理审查意见与回写修复。
**触发关键词：** PR评论、代码审查、gh CLI、GitHub、review comments、issue comments、gh auth、当前分支

**来源：** openai/skills

**位置：** `/Users/zhangyufan/.agents/skills/gh-address-comments/`

---

### planning-with-files
**用途：** 用于规划复杂任务并沉淀执行计划。
**触发关键词：** planning-with-files、任务规划、执行计划、工作流、Manus-style、file-based、plan.md、findings.md、progress.md、multi-step

**来源：** OthmanAdi/planning-with-files

**位置：** `/Users/zhangyufan/.agents/skills/planning-with-files/`

---

### receiving-code-review
**用途：** 用于 receiving-code-review：Use when receiving code review feedback,...
**触发关键词：** receiving-code-review、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/receiving-code-review/`

---

### requesting-code-review
**用途：** 用于 requesting-code-review：Use when completing tasks, implementing m...
**触发关键词：** requesting-code-review、requesting-code-revie

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/requesting-code-review/`

---

### seo-audit
**用途：** 用于执行 skill 安全审计与风险拦截、审计网站 SEO 与页面优化问题。
**触发关键词：** seo-audit、安全审计、风险扫描、Prompt Injection、SEO 审计、站内优化、Meta 标签、SEO、on-page、programmatic-seo

**来源：** coreyhaines31/marketingskills

**位置：** `/Users/zhangyufan/.agents/skills/seo-audit/`

---

### subagent-driven-development
**用途：** 用于 subagent-driven-development：Use when executing implementation plans w...
**触发关键词：** subagent-driven-development、subagent-driven-devel

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/subagent-driven-development/`

---

### systematic-debugging
**用途：** 用于 systematic-debugging：Use when encountering any bug, test failu...
**触发关键词：** systematic-debugging、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/systematic-debugging/`

---

### test-driven-development
**用途：** 用于 test-driven-development：Use when implementing any feature or bugf...
**触发关键词：** test-driven-development、test-driven-developme

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/test-driven-development/`

---

### ui-ux-pro-max
**用途：** 用于设计与审查高质量 Web/移动端 UI/UX，并快速落地设计系统。
**触发关键词：** UI设计、UX审查、设计系统、组件规范、可访问性、响应式布局、React、Next.js

**来源：** nextlevelbuilder/ui-ux-pro-max-skill

**位置：** `/Users/zhangyufan/.agents/skills/ui-ux-pro-max/`

---

### using-git-worktrees
**用途：** 用于 using-git-worktrees：Use when starting feature work that needs...
**触发关键词：** using-git-worktrees、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/using-git-worktrees/`

---

### using-superpowers
**用途：** 用于 using-superpowers：Use when starting any conversation - esta...
**触发关键词：** using-superpowers、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/using-superpowers/`

---

### vercel-react-best-practices
**用途：** 用于设计和审查前端界面与交互体验。
**触发关键词：** vercel-react-best-practices、前端设计、UI、UX、组件、vercel-react-best-pra、React、Next.js、React/Next.js

**来源：** vercel-labs/agent-skills

**位置：** `/Users/zhangyufan/.agents/skills/vercel-react-best-practices/`

---

### verification-before-completion
**用途：** 用于 verification-before-completion：Use when about to claim work is complete,...
**触发关键词：** verification-before-completion、verification-before-c、PRs

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/verification-before-completion/`

---

### web-design-guidelines
**用途：** 用于执行 skill 安全审计与风险拦截、设计和审查前端界面与交互体验。
**触发关键词：** web-design-guidelines、安全审计、风险扫描、Prompt Injection、前端设计、UI、UX、组件

**来源：** vercel-labs/agent-skills

**位置：** `/Users/zhangyufan/.agents/skills/web-design-guidelines/`

---

### writing-plans
**用途：** 用于 writing-plans：Use when you have a spec or requirements...
**触发关键词：** writing-plans、multi-step

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/writing-plans/`

---

### writing-skills
**用途：** 用于 writing-skills：Use when creating new skills, editing exi...
**触发关键词：** writing-skills、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/.agents/skills/writing-skills/`

---

### 用于 相关工作流。
**用途：** 生成 AI 新闻摘要并提供可部署的多源信息流仪表盘。
**触发关键词：** clawfeed、新闻摘要、RSS、Twitter、digest、dashboard

**来源：** https://github.com/kevinho/clawfeed.git

**位置：** `/Users/zhangyufan/.agents/skills/clawfeed/`

---

## 📊 统计信息

- **总计：** 37 个 skills
- **自己创建：** 11 个
- **社区安装：** 26 个

---

## 🔄 如何更新此列表

```bash
# 手动更新
SKILLS_DIR=/Users/zhangyufan/.agents/skills bash /Users/zhangyufan/.agents/skills/shared/scripts/update-skills-list.sh

# 自动更新时机
# 1. 创建新 skill 后
# 2. 安装新 skill 后
# 3. 修改 SKILL.md 中 description/keywords 后
```
