# Skills 中央仓库改造设计

> 状态：设计确认，待分阶段实施  
> 最后更新：2026-04-03

## 设计目标

本次改造的目标不是继续强化“单目录扁平中央仓库”，而是把 skills 系统拆成三个职责清晰的层：

1. 源码管理层：保留技能包原样，便于维护、阅读和发布
2. 运行时消费层：统一扁平目录，兼容各客户端
3. 客户端入口层：继续沿用各客户端已有的 skills 目录约定

在这个过程中，保持以下约束不变：

- skill 本身的名字保持原样
- 不引入 `export_name`
- 不引入 alias
- 不新增额外命名规则
- `.skill-source.json` 继续作为来源真相

## 设计背景

旧模型把 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 同时当作：

- Git 源码仓库
- 第三方 bundle 扁平化落地点
- 客户端消费根

这会带来三个问题：

1. bundle 被强制扁平化后，源码层真实结构丢失
2. 文档、脚本、基础 skills 与其他 skills 混在一层，可读性差
3. `Codex` 与 `Claude Code` 的 skills 发现逻辑不同，继续共用一个“源码即消费”的目录会越来越难维护

其中最关键的现实约束已经确认：

- `Codex` 可以从 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 递归发现 `SKILL.md`
- `Claude Code` 的普通 `/skills/` 目录只支持一层 `skill-name/SKILL.md`

因此，新的设计不再让客户端直接消费源码层。

## 三层模型

### 1. 源码管理层

源码管理层固定为：

- [`~/Workspace/skills-central`](/Users/zhangyufan/Workspace/skills-central)

这是新的真实 Git 仓库，负责：

- 保存所有 skill 的真实目录
- 保留 bundle 原样结构
- 保存文档、脚本、基础 skills
- 保存 `.skill-source.json`
- 作为安装、创建、更新、卸载的真实操作对象

源码层不直接暴露给客户端消费。

### 2. 运行时消费层

运行时消费层固定为：

- [`~/.agents/skills`](/Users/zhangyufan/.agents/skills)

它是一个独立目录，不是源码仓库软链接。

它负责：

- 为所有客户端提供统一扁平 skill 根目录
- 每个顶层条目都指向源码层中的真实 skill 目录
- 屏蔽源码层中的 bundle / 文档 / 脚本分层差异

运行时层中的条目形式如下：

```text
~/.agents/skills/create-skill -> ~/Workspace/skills-central/packages/core/create-skill
~/.agents/skills/brainstorming -> ~/Workspace/skills-central/packages/community/obra__superpowers/brainstorming
```

### 3. 客户端入口层

客户端入口层继续使用各自的约定目录，例如：

- `~/.claude/skills`
- `~/.codex/skills`
- `~/.cursor/skills`
- `~/.gemini/skills`

它们只负责消费 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills)：

```text
~/.claude/skills/create-skill -> ~/.agents/skills/create-skill
~/.codex/skills/create-skill -> ~/.agents/skills/create-skill
```

客户端入口层不再理解源码层结构。

## 源码仓库目录设计

源码仓库采用下面的职责分层：

```text
~/Workspace/skills-central/
├── README.md
├── docs/
├── scripts/
├── shared/
├── packages/
│   ├── core/
│   ├── custom/
│   └── community/
└── INSTALLED_SKILLS.md
```

其中：

- `docs/`：仓库文档
- `scripts/`：仓库级脚本
- `shared/`：共享脚本与公共实现
- `packages/core/`：基础 skills，例如 `create-skill`、`install-skill`
- `packages/custom/`：自定义 skills
- `packages/community/`：第三方仓库或 bundle

## 命名与导出规则

本次设计故意不增加额外命名机制。

### 已确认规则

1. 运行时层的目录名继续沿用源码层 skill 目录名
2. `SKILL.md` 的 `name` 保持原样
3. 不引入 `export_name`
4. 不引入 alias
5. 不增加新的名字映射表

这意味着：

- 一个源码层 skill 目录名，对应一个运行时导出目录名
- 如果两个不同 skill 最终导出到同名目录，则视为冲突

## 冲突处理设计

### 前置检查

冲突必须优先在这些阶段发现：

- `create-skill`
- `install-skill`
- `update-skill`

检查方式是：

- 扫描源码层所有可导出 skill
- 计算它们在运行时层将占用的目录名
- 如果即将新增或更新的 skill 会与已有导出名冲突，则直接失败

### 兜底检查

运行时导出阶段仍需保留最终一致性校验：

- 如果源码层被手动修改
- 如果 Git pull 带来了冲突
- 如果跳过了标准 skill 管理流程

则导出脚本必须能检测到冲突并拒绝输出不一致结果。

导出阶段不负责改名，也不负责兼容处理。

## 元数据模型

`.skill-source.json` 继续作为来源真相。

这次改造不改变它的基础定位，只调整它所描述的“真实存储结构”和“发布结构”语义：

- skill 的真实目录位于源码层
- skill 的运行时暴露位于消费层
- 平台发布仍由 `platform_policies` 控制

推荐字段保持现有模型，不再新增命名相关字段：

```json
{
  "source": "community",
  "source_type": "bundle",
  "package_name": "superpowers",
  "source_repo": "https://github.com/obra/superpowers.git",
  "source_ref": "eafe962b18f6c5dc70fb7c8cc7e83e61f4cdde06",
  "bundle_root": "skills",
  "source_path": "skills/brainstorming",
  "install_mode": "package-source-plus-runtime-export",
  "update_group": "obra/superpowers",
  "platform_policies": {
    "codex": {
      "publish": true,
      "install": "skill"
    },
    "claude_code": {
      "publish": false,
      "install": "plugin",
      "plugin_name": "superpowers",
      "plugin_marketplace": "superpowers-marketplace",
      "plugin_marketplace_source": "obra/superpowers-marketplace",
      "install_hint": "/plugin install superpowers@superpowers-marketplace"
    }
  },
  "installed_at": "2026-04-03T00:00:00Z",
  "updated_at": "2026-04-03T00:00:00Z"
}
```

## 核心流程设计

### 创建流程

1. 在源码层目标分组创建 skill
2. 写入或更新 `.skill-source.json`
3. 执行运行时导出
4. 刷新客户端入口层
5. 更新 `INSTALLED_SKILLS.md`

### 安装流程

1. 拉取单 skill 仓库或 bundle 仓库到临时目录
2. 将结果写入源码层的合适位置
3. 保留 bundle 原样结构
4. 为每个 skill 写入 `.skill-source.json`
5. 检查导出名冲突
6. 导出到运行时层
7. 刷新客户端入口层
8. 更新 `INSTALLED_SKILLS.md`

### 更新流程

1. 从源码层扫描所有已安装 skill
2. 基于 `.skill-source.json` 聚合来源
3. 回放更新到源码层
4. 检查更新后导出名是否冲突
5. 重建运行时层
6. 刷新客户端入口层
7. 更新 `INSTALLED_SKILLS.md`

### 卸载流程

1. 删除源码层中的 skill 或整包
2. 重建运行时层
3. 清理客户端入口层
4. 更新 `INSTALLED_SKILLS.md`

## 发布流程设计

发布拆成两段。

### 第一段：源码层导出到运行时层

新增或重构一个“导出脚本”，职责是：

- 递归扫描 [`~/Workspace/skills-central/packages`](/Users/zhangyufan/Workspace/skills-central/packages)
- 找到所有真实 `SKILL.md`
- 为每个 skill 在 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 创建软链
- 清理失效导出链接
- 对同名冲突执行硬失败

### 第二段：运行时层同步到客户端入口层

继续保留现有 per-skill 链接发布模型：

- 从 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 扫描顶层 skill
- 按平台策略决定是否发布
- 为各客户端创建或清理入口链接

这样可以兼容不同客户端，而不要求它们理解源码层包结构。

## Claude Code 设计决策

`Claude Code` 继续视为平台特例，但特例只发生在“客户端入口层”，不再反向影响源码层结构。

原因：

- 普通 `/skills/` 目录只支持一层 `skill-name/SKILL.md`
- 对部分包还需要插件安装而不是 standalone skill 发布

因此：

- 源码层允许保留 bundle 原样
- 运行时层始终导出为扁平目录
- `Claude Code` 继续从扁平目录消费
- 对官方建议插件安装的 skill 包，继续执行排除发布

## 验证设计

`verify.sh` 在新架构中要覆盖三段检查：

1. 源码层是否存在、是否能发现所有 skill
2. 运行时层是否完整导出
3. 客户端入口层是否与运行时层一致

`doctor-skills` 也应基于这三段模型给出诊断结果。

## 文档与规则联动

本次改造至少涉及这些主文档：

- 需求：[`skills-central-repo-requirements.md`](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-requirements.md)
- 设计：[`skills-central-repo-design.md`](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-design.md)
- 遗留问题：[`skills-central-repo-open-issues.md`](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-open-issues.md)
- 更新记录：[`skills-central-repo-changelog.md`](/Users/zhangyufan/Workspace/skills-central/docs/architecture/skills-central-repo-changelog.md)

另外，这次改造落地后还必须同步更新全局规则文件中关于“中央仓库默认对象”的表述：

- 源码管理仓库改为 [`~/Workspace/skills-central`](/Users/zhangyufan/Workspace/skills-central)
- 运行时发布目录改为 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills)

## 实施阶段

### Phase 1：文档定稿

- 更新需求与设计文档到三层模型
- 在 README 中明确 `skills-central` 与运行时层职责

### Phase 2：目录迁移

- 建立 `skills-central` 仓库结构
- 迁移文档、脚本、基础 skills 到新目录

### Phase 3：导出链路重构

- 实现源码层到运行时层导出
- 保留运行时层到客户端入口层同步

### Phase 4：skill 管理链路重构

- 改造 `create-skill`
- 改造 `install-skill`
- 改造 `update-skill`
- 改造 `uninstall-skill`

### Phase 5：验证与规则同步

- 重构 `verify.sh`
- 适配 `doctor-skills`
- 同步更新全局规则表述
