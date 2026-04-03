# Skills 中央仓库

统一管理各类 AI 客户端使用的 skills，并保留 `create-skill`、`install-skill`、`update-skill`、`uninstall-skill`、`doctor-skills`、`skill-security-guard` 这套基础管理能力。

## 当前架构

当前已经收口为三层结构：

1. 源码管理层：[`~/Workspace/skills-central`](/Users/zhangyufan/Workspace/skills-central)
2. 运行时消费层：[`~/.agents/skills`](/Users/zhangyufan/.agents/skills)
3. 客户端入口层：`~/.claude/skills`、`~/.codex/skills`、`~/.cursor/skills` 等

职责划分如下：

- `skills-central` 保存真实源码、文档、脚本、CI、管理技能和第三方 bundle 原始结构
- `~/.agents/skills` 只保留运行时扁平导出结果
- 各客户端只消费 `~/.agents/skills`，不直接理解源码层结构

设计约束如下：

- skill 原名保持不变
- 不引入 `export_name`
- 不引入 alias
- 不新增额外命名规则
- bundle 在源码层尽量保留原样
- 运行时层统一导出为扁平目录

## 目录结构

```text
源码管理层
~/Workspace/skills-central/
├── .github/
├── docs/
├── scripts/
├── shared/
└── packages/
   ├── core/
   ├── custom/
   └── community/

运行时消费层
~/.agents/skills/
├── create-skill -> ~/Workspace/skills-central/packages/core/create-skill
├── install-skill -> ~/Workspace/skills-central/packages/core/install-skill
└── brainstorming -> ~/Workspace/skills-central/packages/community/.../brainstorming

客户端入口层
~/.claude/skills/create-skill -> ~/.agents/skills/create-skill
~/.codex/skills/create-skill -> ~/.agents/skills/create-skill
~/.cursor/skills/create-skill -> ~/.agents/skills/create-skill
```

## 命令入口

以后所有管理命令都应从源码管理层发起，而不是从 `~/.agents/skills` 发起。

### 发布运行时层与客户端入口层

```bash
bash ~/Workspace/skills-central/shared/scripts/install.sh
```

这个脚本会做两件事：

1. 把源码层的真实 skill 导出到 `~/.agents/skills`
2. 把 `~/.agents/skills` 同步到各客户端入口目录

### 验证三层结构

```bash
# 常规验证
bash ~/Workspace/skills-central/shared/scripts/verify.sh

# 机器可读输出
bash ~/Workspace/skills-central/shared/scripts/verify.sh --json
```

### 安装第三方 skill

```bash
# 安装单个 skill
bash ~/Workspace/skills-central/packages/core/install-skill/install-skill.sh \
  vercel-labs/agent-skills --skill frontend-design --global

# 安装 bundle 的全部 skills
bash ~/Workspace/skills-central/packages/core/install-skill/install-skill.sh \
  https://github.com/obra/superpowers.git --all-skills --bundle-root skills --global
```

### 更新已安装 skill

```bash
bash ~/Workspace/skills-central/packages/core/update-skill/update-skill.sh --list
bash ~/Workspace/skills-central/packages/core/update-skill/update-skill.sh --skill brainstorming
bash ~/Workspace/skills-central/packages/core/update-skill/update-skill.sh --group obra/superpowers
bash ~/Workspace/skills-central/packages/core/update-skill/update-skill.sh --all
```

### 卸载已安装 skill

```bash
bash ~/Workspace/skills-central/packages/core/uninstall-skill/uninstall-skill.sh --skill gh-address-comments
bash ~/Workspace/skills-central/packages/core/uninstall-skill/uninstall-skill.sh --group obra/superpowers
```

### 诊断中央仓库状态

```bash
bash ~/Workspace/skills-central/packages/core/doctor-skills/doctor-skills.sh
bash ~/Workspace/skills-central/packages/core/doctor-skills/doctor-skills.sh --repair
```

### 执行安全审计

```bash
# 本地目录扫描
python3 ~/Workspace/skills-central/packages/core/skill-security-guard/scripts/skill_security_guard.py \
  --min-severity high local --path ~/.agents/skills/some-skill

# GitHub 仓库扫描
python3 ~/Workspace/skills-central/packages/core/skill-security-guard/scripts/skill_security_guard.py \
  --min-severity high github --repo owner/repo
```

### 创建自定义 skill

```bash
# 初始化
python3 ~/Workspace/skills-central/packages/core/create-skill/scripts/init_skill.py my-skill

# 校验
python3 ~/Workspace/skills-central/packages/core/create-skill/scripts/quick_validate.py \
  ~/Workspace/skills-central/packages/custom/my-skill

# 打包
python3 ~/Workspace/skills-central/packages/core/create-skill/scripts/package_skill.py \
  ~/Workspace/skills-central/packages/custom/my-skill ./dist

# 刷新运行时层和客户端入口层
bash ~/Workspace/skills-central/shared/scripts/install.sh

# 重建已安装列表
bash ~/Workspace/skills-central/shared/scripts/update-skills-list.sh
```

## Claude Code 注意事项

`Claude Code` 同时支持 standalone skills 和 plugins。

对于官方明确建议通过 Claude 插件安装的 skill 包，中央仓库策略保持不变：

- 仍通过中央仓库完成安装与管理
- 不再把同包 standalone skill 发布到 `~/.claude/skills`
- 在可用环境中自动执行对应插件安装 / 启用
- 保留插件安装提示和文档记录

## 关键文档

- [需求文档](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-requirements.md)
- [设计文档](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-design.md)
- [元数据 Schema](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skill-source-schema.md)
- [Skills 重叠审计](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skill-overlap-audit.md)
- [Claude 插件安装建议](/Users/zhangyufan/Workspace/skills-central/docs/architecture/claude-plugin-recommendations.md)
- [遗留问题](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-open-issues.md)
- [更新记录](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-changelog.md)

## Skills 列表

完整列表见：

- [INSTALLED_SKILLS.md](/Users/zhangyufan/Workspace/skills-central/INSTALLED_SKILLS.md)

该文档由脚本自动维护，记录当前可用 skills 的用途、来源和位置。
