# Skills 中央仓库改造需求

> 状态：已确认  
> 最后更新：2026-04-03

## 背景

当前仓库把源码管理、运行时消费、客户端入口三件事放在了同一层目录里：

- [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 同时是 Git 仓库、安装落地点和客户端消费根
- 第三方 bundle 被强制扁平化后再进入中央仓库
- 文档、脚本、基础 skills 与业务 / 社区 skills 混在同一层

这套模型虽然能工作，但随着 bundle 增多、基础 skills 增多，以及 `Codex` / `Claude Code` 的发现逻辑差异越来越明显，已经不利于长期维护。

本次改造的目标，是把中央技能系统拆成“源码管理层 + 运行时消费层 + 客户端入口层”三层结构，同时保留现有 skill 的名字和元数据模型，不新增额外命名机制。

## 核心目标

1. 新的源码管理仓库固定为 [`~/Workspace/skills-central`](/Users/zhangyufan/Workspace/skills-central)。
2. [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 改为独立的运行时消费层，不再是源码仓库本体。
3. 源码层保留技能包原样，不再把 bundle 强制扁平化后作为真实存储结构。
4. 客户端继续统一消费扁平目录，以兼容 `Claude Code`、`Codex` 等不同发现逻辑。
5. 每个 skill 继续使用自己的目录名作为运行时导出名，不引入 `export_name`、alias 或额外命名规则。
6. 每个已安装 skill 继续使用 `.skill-source.json` 作为来源真相。
7. 文档、脚本、基础 skills 与其他 skills 按目录职责分层存放。
8. 架构改造完成后，相关全局规则文件要同步更新。

## 非目标

1. 不让客户端直接消费源码层中的包结构。
2. 不新增 `registry/`、别名、导出名映射等机制。
3. 不在本次改造中额外引入新的 skill 命名规则。
4. 不要求所有平台都支持相同的内部存储结构。
5. 不把 README 变成完整架构设计文档。

## 结构性需求

### 源码管理层

1. 源码管理仓库使用 [`~/Workspace/skills-central`](/Users/zhangyufan/Workspace/skills-central)。
2. 仓库内部至少拆分为：
   - `docs/`
   - `scripts/`
   - `shared/`
   - `packages/`
3. `packages/` 至少支持：
   - `core/`
   - `custom/`
   - `community/`
4. 第三方 bundle 在源码层中应尽量保持原样存放。

### 运行时消费层

1. [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 是独立目录，不是源码仓库软链接。
2. 运行时消费层中的每个 skill 条目都应指向源码层中的真实 skill 目录。
3. 运行时消费层必须保持扁平目录结构。

### 客户端入口层

1. 各客户端继续从扁平运行时层消费 skills。
2. `~/.claude/skills`、`~/.codex/skills`、`~/.cursor/skills` 等目录继续作为入口层存在。
3. 客户端入口层不承担源码管理职责。

## 功能性需求

### 创建

1. `create-skill` 默认在源码管理层中创建新 skill。
2. 创建后必须刷新运行时消费层和客户端入口层。
3. 如果目录名会导致运行时扁平层冲突，必须在创建阶段就报错。

### 安装

1. 支持安装单 skill 仓库。
2. 支持安装 bundle 仓库。
3. 安装结果应进入源码管理层，而不是直接写入运行时消费层。
4. 安装后为每个 skill 写入 `.skill-source.json`。
5. 安装完成后必须刷新运行时消费层和客户端入口层。

### 更新

1. `update-skill` 继续保留独立入口。
2. 更新必须基于源码层 skill 的 `.skill-source.json`。
3. 对同一 bundle 来源，更新时应按来源聚合，只拉取一次远端仓库。
4. 更新完成后必须刷新运行时消费层和客户端入口层。
5. 如果更新后会产生扁平目录名冲突，必须在更新阶段报错。

### 卸载

1. `uninstall-skill` 继续保留独立入口。
2. 卸载的真实对象应是源码层 skill 或整包。
3. 卸载完成后必须刷新运行时消费层和客户端入口层。

### 发布

1. 发布应拆成两段：
   - 源码层导出到运行时消费层
   - 运行时消费层同步到各客户端入口层
2. 运行时消费层的导出名继续沿用 skill 目录名。
3. 不允许在发布阶段引入改名逻辑。
4. 发布阶段必须支持按平台过滤。

### 验证/修复

1. 当前 `verify.sh` 保留，但要覆盖源码层、运行时层、客户端层三段校验。
2. `doctor-skills` 后续应基于三层结构做诊断。

## 冲突需求

1. 同名冲突按硬错误处理。
2. 同名冲突必须优先在 `create-skill`、`install-skill`、`update-skill` 阶段发现。
3. 导出阶段只做兜底校验，不负责自动改名或兼容处理。

## 元数据需求

`.skill-source.json` 继续覆盖至少这些信息：

- `source`
- `source_type`
- `package_name`
- `source_repo`
- `source_ref`
- `source_path`
- `bundle_root`
- `install_mode`
- `update_group`
- `platform_policies`
- `installed_at`
- `updated_at`

其中 `platform_policies.claude_code` 至少应支持：

- `publish`
- `install`
- `plugin_name`
- `install_hint`

## Claude Code 专项需求

1. `Claude Code` 的普通 `/skills/` 目录继续按一层 `skill-name/SKILL.md` 兼容。
2. 如果某个 skill 包官方建议通过 Claude 插件安装，则中央仓库不得再把其同名 skill 发布到 `~/.claude/skills`。
3. 相关提示既要打印到终端，也要写入仓库文档。

## 文档与规则需求

1. 至少保留：需求、设计、遗留问题、更新记录四类架构文档。
2. README 需要明确说明：
   - `skills-central` 是源码管理仓库
   - `~/.agents/skills` 是运行时消费层
   - 客户端默认只消费运行时层
3. 现有全局规则中关于“中央仓库默认是 `~/.agents/skills`”的描述，需要在架构落地后同步更新。

## 验收标准

满足以下条件即可认为改造完成：

1. 源码管理仓库已迁移为 [`~/Workspace/skills-central`](/Users/zhangyufan/Workspace/skills-central)。
2. [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 已成为独立运行时消费层。
3. 源码层中的 bundle 以原样结构存放，不再以扁平目录作为真实存储结构。
4. 运行时消费层能稳定导出为扁平目录。
5. `create-skill`、`install-skill`、`update-skill`、`uninstall-skill` 都能基于新三层结构工作。
6. 同名冲突可在创建 / 安装 / 更新阶段被发现。
7. `Claude Code` 的插件推荐包不会被重复发布到 `~/.claude/skills`。
8. README 和架构主文档已更新到新模型。
