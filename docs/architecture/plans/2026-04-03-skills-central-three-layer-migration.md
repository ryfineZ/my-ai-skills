# Skills Central Three-Layer Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前以 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 为中心的单层实现，迁移为“源码管理层 `~/Workspace/skills-central` + 运行时消费层 `~/.agents/skills` + 客户端入口层”的三层结构，同时保持现有 skill 名字、来源元数据和平台发布策略不变。

**Architecture:** 真实源码和包结构迁移到 [`~/Workspace/skills-central`](/Users/zhangyufan/Workspace/skills-central)，运行时目录 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 只保留扁平软链接导出结果，各客户端继续只消费运行时层。创建、安装、更新、卸载都改为先操作源码层，再统一执行“源码层导出到运行时层”和“运行时层同步到客户端层”两段发布。

**Tech Stack:** Bash, Python 3, Git, symlink export, JSON metadata

---

### Task 1: 冻结目标目录结构与迁移边界

**Files:**
- Create: `/Users/zhangyufan/Workspace/skills-central/README.md`
- Create: `/Users/zhangyufan/Workspace/skills-central/docs/`
- Create: `/Users/zhangyufan/Workspace/skills-central/scripts/`
- Create: `/Users/zhangyufan/Workspace/skills-central/shared/`
- Create: `/Users/zhangyufan/Workspace/skills-central/packages/core/`
- Create: `/Users/zhangyufan/Workspace/skills-central/packages/custom/`
- Create: `/Users/zhangyufan/Workspace/skills-central/packages/community/`
- Modify: `/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-design.md`
- Modify: `/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-open-issues.md`

- [ ] **Step 1: 创建源码管理仓库骨架**

Run:
```bash
mkdir -p /Users/zhangyufan/Workspace/skills-central/{docs,scripts,shared,packages/core,packages/custom,packages/community}
```

Expected: `skills-central` 的目录骨架存在，但尚未迁移任何 skill 内容。

- [ ] **Step 2: 在源码仓库中写最小 README**

要求：
- 明确这是源码管理层
- 明确运行时消费层仍是 `~/.agents/skills`
- 明确客户端入口层不直接消费源码层

- [ ] **Step 3: 更新架构文档中的实施状态**

要求：
- `skills-central-repo-design.md` 明确“当前未落地、按计划实施”
- `skills-central-repo-open-issues.md` 补充“旧脚本仍按顶层扫描运行时层”的迁移风险

### Task 2: 实现源码层到运行时层的扁平导出

**Files:**
- Create: `/Users/zhangyufan/Workspace/skills-central/scripts/export-runtime-links.sh`
- Modify: `/Users/zhangyufan/.agents/skills/shared/scripts/install.sh`
- Modify: `/Users/zhangyufan/.agents/skills/shared/scripts/verify.sh`

- [ ] **Step 1: 编写源码层扫描与导出脚本**

要求：
- 递归扫描 `/Users/zhangyufan/Workspace/skills-central/packages`
- 识别所有真实 `SKILL.md`
- 用 skill 目录名作为运行时导出名
- 在 `/Users/zhangyufan/.agents/skills` 创建顶层软链接
- 发现同名冲突时直接失败

- [ ] **Step 2: 让当前运行时发布脚本只负责客户端同步**

要求：
- `shared/scripts/install.sh` 不再假设当前仓库本身就是 skill 实体根
- 它的输入改为已经导出的 `/Users/zhangyufan/.agents/skills`
- 它继续负责 `~/.claude/skills`、`~/.codex/skills`、`~/.cursor/skills` 等入口层同步

- [ ] **Step 3: 扩展 verify 到三层校验**

要求：
- 校验源码层是否存在并可发现 skill
- 校验运行时层是否完整导出
- 校验客户端入口层是否与运行时层一致

- [ ] **Step 4: 验证导出链路**

Run:
```bash
bash /Users/zhangyufan/Workspace/skills-central/scripts/export-runtime-links.sh
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/verify.sh" --json
```

Expected:
- 运行时层生成扁平软链接
- 客户端入口层同步成功
- `verify --json` 输出可用且不报结构性错误

### Task 3: 改造 create-skill 到源码层工作流

**Files:**
- Modify: `/Users/zhangyufan/.agents/skills/create-skill/SKILL.md`
- Modify: `/Users/zhangyufan/.agents/skills/create-skill/scripts/init_skill.py`
- Modify: `/Users/zhangyufan/.agents/skills/create-skill/scripts/quick_validate.py`
- Modify: `/Users/zhangyufan/.agents/skills/create-skill/scripts/package_skill.py`

- [ ] **Step 1: 将默认创建路径切到源码层**

要求：
- 默认创建位置改为 `~/Workspace/skills-central/packages/custom`
- 保留显式 `--path` 覆盖能力

- [ ] **Step 2: 在创建阶段前置检查导出名冲突**

要求：
- 读取源码层所有可导出 skill
- 如果新目录名会与现有运行时导出名冲突，则直接失败

- [ ] **Step 3: 创建完成后自动刷新两段发布**

要求：
- 创建后先执行源码层导出
- 再同步客户端入口层
- 最后重建 `INSTALLED_SKILLS.md`

- [ ] **Step 4: 验证 create-skill 新默认行为**

Run:
```bash
python3 /Users/zhangyufan/.agents/skills/create-skill/scripts/init_skill.py demo-skill --path /Users/zhangyufan/Workspace/skills-central/packages/custom
python3 /Users/zhangyufan/.agents/skills/create-skill/scripts/quick_validate.py /Users/zhangyufan/Workspace/skills-central/packages/custom/demo-skill
```

Expected:
- skill 在源码层创建成功
- 校验通过
- 未出现重名导出冲突

### Task 4: 改造 install-skill、update-skill、uninstall-skill 到源码层工作流

**Files:**
- Modify: `/Users/zhangyufan/.agents/skills/install-skill/install-skill.sh`
- Modify: `/Users/zhangyufan/.agents/skills/install-skill/SKILL.md`
- Modify: `/Users/zhangyufan/.agents/skills/update-skill/update-skill.sh`
- Modify: `/Users/zhangyufan/.agents/skills/update-skill/SKILL.md`
- Modify: `/Users/zhangyufan/.agents/skills/uninstall-skill/uninstall-skill.sh`
- Modify: `/Users/zhangyufan/.agents/skills/uninstall-skill/SKILL.md`

- [ ] **Step 1: install-skill 写入源码层而不是运行时层**

要求：
- 单 skill 安装到源码层目标目录
- bundle 按原样进入 `packages/community/<repo-or-package>/...`
- 每个实际 skill 继续写 `.skill-source.json`
- 安装完成后执行导出和客户端同步

- [ ] **Step 2: update-skill 从源码层扫描并按来源聚合更新**

要求：
- 以源码层 `.skill-source.json` 为准
- 同一 `update_group` 只拉取一次远端
- 更新后执行导出名冲突检查
- 成功后刷新运行时层和客户端层

- [ ] **Step 3: uninstall-skill 删除源码层真实对象**

要求：
- 删除对象是源码层 skill 或整包目录
- 删除后重建运行时层
- 清理客户端入口层残留链接

- [ ] **Step 4: 验证安装、更新、卸载闭环**

Run:
```bash
bash /Users/zhangyufan/.agents/skills/install-skill/install-skill.sh https://github.com/obra/superpowers.git --all-skills --bundle-root skills --global
bash /Users/zhangyufan/.agents/skills/update-skill/update-skill.sh --list
bash /Users/zhangyufan/.agents/skills/uninstall-skill/uninstall-skill.sh --help
```

Expected:
- 三个入口都可运行
- 安装/更新/卸载的真实对象已切到源码层
- 运行时层只保留导出结果

### Task 5: 迁移列表生成、诊断与安全门禁

**Files:**
- Modify: `/Users/zhangyufan/.agents/skills/shared/scripts/update-skills-list.sh`
- Modify: `/Users/zhangyufan/.agents/skills/doctor-skills/doctor-skills.sh`
- Modify: `/Users/zhangyufan/.agents/skills/shared/scripts/skill-security-ci.sh`
- Modify: `/Users/zhangyufan/.agents/skills/INSTALLED_SKILLS.md`

- [ ] **Step 1: 让 skills 列表脚本从源码层扫描真实 skill**

要求：
- 不再把运行时层当成来源真相
- 输出仍写回当前仓库的 `INSTALLED_SKILLS.md`，直到仓库整体迁移完成

- [ ] **Step 2: 让 doctor-skills 按三层结构做诊断**

要求：
- 检查源码层存在性
- 检查运行时导出一致性
- 检查客户端入口层一致性
- 输出能明确指出问题发生在哪一层

- [ ] **Step 3: 让安全门禁扫描源码层真实变更**

要求：
- `skill-security-ci.sh` 默认扫描源码层真实目录
- 仍输出 `summary.json` 与 `summary.sarif`
- 退出码语义保持不变

- [ ] **Step 4: 验证诊断与安全门禁**

Run:
```bash
bash /Users/zhangyufan/.agents/skills/doctor-skills/doctor-skills.sh
bash /Users/zhangyufan/.agents/skills/shared/scripts/skill-security-ci.sh --scope all --threshold high --output-dir /tmp/skill-security-artifacts
```

Expected:
- 诊断结果按三层结构输出
- 安全门禁仍能生成 JSON/SARIF
- 退出码语义保持 `0/1/2`

### Task 6: 完成数据迁移、规则同步与最终验收

**Files:**
- Modify: `/Users/zhangyufan/Workspace/agent-rules/AGENTS.md`
- Modify: `/Users/zhangyufan/Workspace/agent-rules/generated/AGENTS.md`
- Modify: `/Users/zhangyufan/Workspace/agent-rules/generated/CLAUDE.md`
- Modify: `/Users/zhangyufan/Workspace/agent-rules/generated/GEMINI.md`
- Modify: `/Users/zhangyufan/.agents/skills/README.md`
- Modify: `/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-changelog.md`

- [ ] **Step 1: 把现有源码内容迁移到 skills-central**

要求：
- 基础 skills 进入 `packages/core`
- 自定义 skills 进入 `packages/custom`
- 第三方 bundle 进入 `packages/community`
- 文档和脚本按新职责归位

- [ ] **Step 2: 同步全局规则中“中央仓库默认对象”的表述**

要求：
- 源码管理仓库改为 `~/Workspace/skills-central`
- 运行时消费层改为 `~/.agents/skills`
- 不改变“默认操作中央仓库”的总原则

- [ ] **Step 3: 更新 README 为迁移完成态**

要求：
- 去掉“迁移中”描述
- 明确 `~/.agents/skills` 已是纯运行时消费层
- 明确所有管理入口实际操作源码层

- [ ] **Step 4: 做最终验收**

Run:
```bash
bash /Users/zhangyufan/Workspace/skills-central/scripts/export-runtime-links.sh
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/verify.sh" --json
```

Expected:
- 三层结构可稳定工作
- `verify --json` 无结构性错误
- Claude 插件推荐包不重复发布到 `~/.claude/skills`
