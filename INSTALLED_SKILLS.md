# 📦 已安装的 Skills 列表

> 本文档由 `shared/scripts/update-skills-list.sh` 自动生成和维护
> 文件名：`INSTALLED_SKILLS.md` - 避免与各 skill 目录中的 `SKILL.md` 混淆
> 最后更新：2026-02-22 19:32:27

---

## 🎨 自己创建的 Skills

### agent-rules-sync
**用途：** 统一维护并同步多平台全局规则，处理明确写入指令。
**触发关键词：** 新增全局规则、写入全局规则、同步规则、AGENTS、CLAUDE、GEMINI

**位置：** `/Users/zhangyufan/.agents/skills/agent-rules-sync/`

---

### code-quality-check
**用途：** 提交前执行项目相关的代码质量检查与验证。
**触发关键词：** 代码质量检查、lint、测试、提交前检查、质量门禁

**位置：** `/Users/zhangyufan/.agents/skills/code-quality-check/`

---

### commit-conventional
**用途：** 按约定式提交规范生成并执行 git commit。
**触发关键词：** git commit、提交代码、创建提交、约定式提交、commit message

**位置：** `/Users/zhangyufan/.agents/skills/commit-conventional/`

---

### create-skill
**用途：** 创建或更新 skill 的流程与规范指南。
**触发关键词：** 创建 skill、更新 skill、制作自定义技能、skill 设计、工作流

**位置：** `/Users/zhangyufan/.agents/skills/create-skill/`

---

### humanize-text
**用途：** 通过优化句法、节奏和写作模式降低 AI 文本检测率，帮助内容通过 GPTZero、腾讯朱雀等检测器；优化困惑度(Perplexity)和爆发性(Burstiness)指标，去除 Claude/ChatGPT 写作模式。
**触发关键词：** 降低AI检测率、去AI味、通过GPTZero检测、让文章更像人写的、humanize、AI检测、腾讯朱雀、困惑度、Burstiness

**位置：** `/Users/zhangyufan/.agents/skills/humanize-text/`

---

### install-skill
**用途：** 使用 npx skills add 安装、更新并管理 skills 与来源仓库。
**触发关键词：** 安装 skill、更新 skill、skills add、从 GitHub 安装、浏览 skills

**位置：** `/Users/zhangyufan/.agents/skills/install-skill/`

---

### skill-security-guard
**用途：** 对本地目录或 GitHub 仓库中的 skill 做安装前安全审计，检测提示词劫持、下载执行、凭证窃取、数据外传、持久化和提权风险，并输出可用于门禁的 SAFE/CAUTION/REVIEW/BLOCK 结论。
**触发关键词：** skill 安全检测、安装前审计、scan skill security、恶意 skill、prompt injection 检查、中央仓库门禁

**位置：** `/Users/zhangyufan/.agents/skills/skill-security-guard/`

---

## 🌐 社区安装的 Skills

### agent-browser
**用途：** 自动化浏览器操作，支持导航、交互、表单、截图与数据提取。
**触发关键词：** 浏览器自动化、网页测试、表单填写、截图、数据提取、网页交互

**来源：** vercel-labs/agent-browser

**位置：** `/Users/zhangyufan/.agents/skills/agent-browser/`

---

### brainstorming
**用途：** 创意工作前进行需求澄清、方案探索与设计整理。
**触发关键词：** 需求澄清、方案探索、创意设计、功能构思、设计讨论

**来源：** mikeastock/agents

**位置：** `/Users/zhangyufan/.agents/skills/brainstorming/`

---

### find-skills
**用途：** （待补充）
**触发关键词：** （待补充）

**来源：** vercel-labs/skills

**位置：** `/Users/zhangyufan/.agents/skills/find-skills/`

---

### frontend-design
**用途：** 生成高质量、具有设计感的前端界面与组件代码。
**触发关键词：** 前端设计、UI、Web 组件、页面构建、Web 应用、高质量界面

**来源：** anthropics/skills

**位置：** `/Users/zhangyufan/.agents/skills/frontend-design/`

---

### gh-address-comments
**用途：** 使用 gh CLI 协助处理当前分支对应的 GitHub PR 审查/问题评论；会先验证 gh 登录状态并提示用户认证。
**触发关键词：** 处理 PR 评论、address comments、gh 评论、GitHub 审查、review comments、gh CLI

**来源：** 

**位置：** `/Users/zhangyufan/.agents/skills/gh-address-comments/`

---

### humanizer
**用途：** 去除 AI 写作痕迹，让文本更自然、更像人写；基于 Wikipedia “Signs of AI writing” 指南，识别并修复夸张象征、宣传语、空泛 -ing 分析、含糊归因、破折号滥用、三段式、AI 词汇、负面平行结构、过多连接短语等模式。
**触发关键词：** 去除AI痕迹、humanize、润色文本、自然表达、AI写作、改写、写作风格

**来源：** blader/humanizer

**位置：** `/Users/zhangyufan/.agents/skills/humanizer/`

---

### notebooklm
**用途：** 通过 Claude Code 直接查询 Google NotebookLM 笔记本，输出基于来源的可引用回答；支持浏览器自动化、库管理与持久化认证，显著降低幻觉。
**触发关键词：** NotebookLM、Claude Code、引用回答、文档检索、Gemini、浏览器自动化

**来源：** PleasePrompto/notebooklm-skill

**位置：** `/Users/zhangyufan/.agents/skills/notebooklm-skill/`

---

### planning-with-files
**用途：** Manus 风格的文件化规划：生成 task_plan.md、findings.md、progress.md；用于复杂多步骤任务或研究（通常 >5 次工具调用），支持 /clear 后会话恢复。
**触发关键词：** 任务规划、文件化计划、task_plan.md、复杂任务、研究流程、会话恢复

**来源：** OthmanAdi/planning-with-files

**位置：** `/Users/zhangyufan/.agents/skills/planning-with-files/`

---

### seo-audit
**用途：** 用于审计、评估或诊断网站 SEO 问题；覆盖技术 SEO、排名异常、页面优化、元标签检查等场景。
**触发关键词：** SEO 审计、技术 SEO、排名异常、站内优化、meta 标签、SEO 健康检查

**来源：** coreyhaines31/marketingskills

**位置：** `/Users/zhangyufan/.agents/skills/seo-audit/`

---

### vercel-react-best-practices
**用途：** Vercel 的 React/Next.js 性能优化实践与模式指南，涵盖组件、数据获取与 bundle 优化。
**触发关键词：** React、Next.js、性能优化、Vercel、数据获取、bundle 优化

**来源：** vercel-labs/agent-skills

**位置：** `/Users/zhangyufan/.agents/skills/vercel-react-best-practices/`

---

### web-design-guidelines
**用途：** 审查 UI/UX 与可访问性，确保符合 Web 设计规范。
**触发关键词：** 审查 UI、可访问性、审计设计、审查 UX、最佳实践

**来源：** vercel-labs/agent-skills

**位置：** `/Users/zhangyufan/.agents/skills/web-design-guidelines/`

---

## 📊 统计信息

- **总计：** 18 个 skills
- **自己创建：** 7 个
- **社区安装：** 11 个

---

## 🔄 如何更新此列表

```bash
# 手动更新
SKILLS_DIR=/Users/zhangyufan/.agents/skills bash /Users/zhangyufan/.agents/skills/shared/scripts/update-skills-list.sh

# 自动更新时机
# 1. 创建新 skill 后
# 2. 安装新 skill 后
# 3. 修改技能列表中文描述后
```
