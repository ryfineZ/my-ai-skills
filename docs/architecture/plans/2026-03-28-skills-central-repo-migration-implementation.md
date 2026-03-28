# Skills 中央仓库改造实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将中央仓库从“第三方源码目录 + bundle 清单 + 软链接发布”迁移到“扁平 skill 实体 + `.skill-source.json` 统一来源真相 + 按平台差异化发布”的目标架构。

**Architecture:** 先冻结文档和元数据 schema，再重构安装/更新/发布脚本，最后删除旧版 `superpowers` 并用新框架重新安装验收，同时移除旧 bundle 管理链路。Claude Code 的插件排除策略只在发布层体现，不反向污染中央仓库实体结构。

**Tech Stack:** Bash, Python 3, JSON metadata, Git, central repo scripts

---

### Task 1: 定义 `.skill-source.json` schema 与迁移边界

**Files:**
- Modify: `install-skill/install-skill.sh`
- Modify: `install-skill/scripts/set_skill_meta.py`
- Create: `docs/architecture/skill-source-schema.md`
- Modify: `docs/architecture/skills-central-repo-design.md`

- [x] **Step 1: 写 schema 文档**

Create: `docs/architecture/skill-source-schema.md`

内容应至少包含：
- 必填字段
- 可选字段
- `source_type=custom|single|bundle`
- `platform_policies.claude_code`
- 向后兼容策略

- [x] **Step 2: 明确当前兼容读法**

在 `install-skill/scripts/set_skill_meta.py` 和后续脚本中统一兼容：
- 老字段：`source`, `source_repo`, `installed_by`, `installed_at`, `updated_at`
- 新字段：`source_type`, `package_name`, `source_ref`, `source_path`, `bundle_root`, `install_mode`, `update_group`, `platform_policies`

- [x] **Step 3: 更新安装元数据写入逻辑**

Modify: `install-skill/install-skill.sh`

要求：
- 安装单 skill 时写入新 schema 的最小闭环字段
- 保留旧字段兼容性
- 不破坏现有已安装 skill

- [x] **Step 4: 验证元数据写入**

Run: `python3 /Users/zhangyufan/.agents/skills/install-skill/scripts/set_skill_meta.py --help`
Expected: 命令可正常输出帮助或参数说明

Run: `rg -n "source_type|platform_policies|update_group" /Users/zhangyufan/.agents/skills/install-skill /Users/zhangyufan/.agents/skills/docs/architecture`
Expected: schema 与写入逻辑已同步出现

### Task 2: 重构安装链路为扁平化复制

**Files:**
- Modify: `install-skill/install-skill.sh`
- Modify: `shared/scripts/install.sh`
- Modify: `shared/scripts/verify.sh`
- Delete: `shared/scripts/publish-third-party-skills.sh`
- Modify: `README.md`
- Modify: `SETUP-SUMMARY.md`

- [x] **Step 1: 停止依赖长期第三方源码目录**

Modify: `install-skill/install-skill.sh`

要求：
- 第三方仓库只允许临时拉取到临时目录
- 安装完成后移除临时目录

- [x] **Step 2: 实现 bundle 扁平复制**

Modify: `install-skill/install-skill.sh`

要求：
- 识别 bundle 根目录
- 扫描所有 skill 目录
- 将每个 skill 完整复制到中央仓库顶层
- 每个 skill 单独写 `.skill-source.json`

- [x] **Step 3: 清理旧发布前置脚本依赖**

Modify: `shared/scripts/install.sh`

要求：
- 不再依赖 `publish-third-party-skills.sh`
- 只从中央仓库顶层 skill 实体出发创建各平台链接

- [x] **Step 4: 更新验证逻辑**

Modify: `shared/scripts/verify.sh`

要求：
- 验证中央仓库顶层 skill 为真实目录或明确允许的结构
- 不再假设第三方 bundle 源码目录存在

- [x] **Step 5: 验证安装链路**

Run: `SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"`
Expected: 平台链接正常重建，无新增错误

Run: `SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/verify.sh" --json`
Expected: JSON 输出状态可用，错误为 0

### Task 3: 新增 `update-skill`

**Files:**
- Create: `update-skill/SKILL.md`
- Create: `update-skill/update-skill.sh`
- Modify: `README.md`
- Modify: `INSTALLED_SKILLS.md`
- Modify: `docs/architecture/skills-central-repo-design.md`
- Modify: `docs/architecture/skills-central-repo-open-issues.md`

- [x] **Step 1: 创建 `update-skill` skill**

Create: `update-skill/SKILL.md`

要求：
- 明确触发场景
- 说明单 skill 与 bundle 更新差异
- 说明 Claude 插件排除策略

- [x] **Step 2: 实现更新脚本**

Create: `update-skill/update-skill.sh`

要求：
- 扫描顶层 skill 的 `.skill-source.json`
- 按 `update_group` 聚合
- 临时拉取来源仓库
- 更新已有 skill
- 识别 bundle 新增 skill

- [x] **Step 3: 输出更新报告**

要求：
- 输出哪些 skill 被更新
- 哪些 skill 是新增
- 哪些 skill 被跳过
- 哪些包需要 Claude 插件安装

- [x] **Step 4: 验证更新脚本可运行**

Run: `bash /Users/zhangyufan/.agents/skills/update-skill/update-skill.sh --help`
Expected: 输出帮助信息，不报错

### Task 4: 增加 Claude Code 平台过滤与插件提示

**Files:**
- Modify: `shared/scripts/install.sh`
- Modify: `shared/scripts/verify.sh`
- Modify: `shared/scripts/update-skills-list.sh`
- Create: `docs/architecture/claude-plugin-recommendations.md`
- Modify: `README.md`

- [x] **Step 1: 在发布脚本里读取平台策略**

Modify: `shared/scripts/install.sh`

要求：
- 读取每个 skill 的 `.skill-source.json`
- 若 `platform_policies.claude_code.publish=false`，则跳过发布到 `~/.claude/skills`

- [x] **Step 2: 输出明确提示**

要求：
- 提示被跳过的 skill
- 提示插件安装原因
- 提供 `install_hint`

- [x] **Step 3: 生成 Claude 插件建议文档**

Create: `docs/architecture/claude-plugin-recommendations.md`

内容至少包括：
- package 名
- skill 名
- 原因
- 推荐安装命令
- 最后检查时间

- [x] **Step 4: 验证 Claude 发布结果**

Run: `find "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 | sort`
Expected: 官方建议插件安装的包不再出现在 Claude standalone skills 目录

### Task 5: 删除旧版 `superpowers` 并用新框架重装验收

**Files:**
- Modify: top-level installed `superpowers` skills under `~/.agents/skills/`
- Delete: `THIRD_PARTY_SKILLS.toml`
- Delete: `shared/scripts/publish-third-party-skills.sh`
- Modify: `docs/architecture/skills-central-repo-changelog.md`
- Modify: `docs/architecture/skills-central-repo-open-issues.md`

- [x] **Step 1: 为 `superpowers` 确定删除与重装策略**

要求：
- 不迁移旧软链接 skill 数据
- 新框架完成后删除旧版 `superpowers`
- 使用新框架重新安装 `superpowers`
- 标记 Claude 为插件安装策略

- [x] **Step 2: 删除旧版 `superpowers`**

要求：
- 删除历史软链接发布结果
- 清理与旧 bundle 发布相关的残留状态

- [x] **Step 3: 删除旧 bundle 清单**

Delete: `THIRD_PARTY_SKILLS.toml`

要求：
- 确认所有逻辑都已不再依赖它

- [x] **Step 4: 用新框架重新安装 `superpowers`**

要求：
- 使用新安装链路完成 bundle 安装
- 生成完整 `.skill-source.json`
- 验证 Claude 平台排除策略

- [x] **Step 5: 更新文档与遗留项**

Modify: `docs/architecture/skills-central-repo-changelog.md`

要求：
- 记录旧版删除和新框架重装完成
- 关闭已完成遗留项

- [x] **Step 6: 最终回归验证**

Run: `SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/install.sh"`
Expected: 所有平台链接正常重建

Run: `SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"`
Expected: `INSTALLED_SKILLS.md` 正常更新

Run: `SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/verify.sh" --json`
Expected: 错误为 0，Claude 平台排除符合策略
