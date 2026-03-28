# Skills 中央仓库改造需求

> 状态：已确认  
> 最后更新：2026-03-28

## 背景

当前中央仓库同时承担了 skills 发布根、第三方 bundle 接入点、多平台同步源等职责，但第三方 bundle 仍依赖额外清单和源码目录，Claude Code 又存在插件安装这一类平台特例，导致来源追踪、更新、平台发布策略还不统一。

本次改造的目标，是把中央仓库收敛为一套可长期维护的技能分发系统，并把需求、设计、遗留问题和更新记录正式沉淀下来。

## 核心目标

1. 中央仓库继续以 [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 作为唯一权威目录和唯一发布根。
2. 第三方 skill 安装后以顶层扁平目录形式落地，每个 skill 都是完整真实目录，不依赖长期保留的第三方源码缓存目录。
3. 每个已安装 skill 都有可机器读取的来源元数据，作为安装、更新、发布的唯一来源真相。
4. 多平台发布逻辑统一由中央仓库驱动，但允许按平台应用差异化策略。
5. 对官方明确建议通过 Claude Code 插件安装的 skill 包，中央仓库必须支持：
   - 自动排除发布到 `~/.claude/skills`
   - 给出明确提示，说明应通过插件安装
6. 中央仓库改造过程要有正式文档记录，包含需求、设计、遗留问题、更新记录。

## 非目标

1. 不追求所有平台都使用完全相同的安装形态。
2. 不要求中央仓库复刻 Claude Code 插件的全部能力。
3. 不在本次改造中优先解决所有历史 skill 的质量问题或文案问题。
4. 不把 README 变成架构设计文档；README 只保留入口和关键注意事项。

## 功能性需求

### 安装

1. 支持安装单 skill 仓库。
2. 支持安装 bundle 仓库。
3. 安装 bundle 时，按 skill 目录完整复制到中央仓库顶层。
4. 安装后为每个 skill 写入 `.skill-source.json`。

### 更新

1. 必须新增独立的 `update-skill` 能力。
2. 更新必须基于已安装 skill 的 `.skill-source.json`。
3. 对同一 bundle 来源，更新时应按来源聚合，只拉取一次远端仓库。
4. 更新时应支持：
   - 刷新已安装 skill
   - 识别并补装 bundle 新增 skill
   - 识别 bundle 删除的 skill，并给出记录或处理

### 卸载

1. 应补充独立的 `uninstall-skill` 能力。
2. 卸载时应清理：
   - skill 目录
   - 平台发布链接
   - 相关提示与索引记录

### 发布

1. 平台发布应从中央仓库顶层 skill 出发。
2. 发布规则必须支持按平台过滤。
3. Claude Code 必须支持“推荐插件安装”的排除策略。

### 验证/修复

1. 当前 `verify.sh` 保留。
2. 后续应补充 `doctor-skills` 或同类能力，用于诊断和修复：
   - 缺失或损坏的 `.skill-source.json`
   - 过期平台链接
   - 平台策略不一致
   - Claude 插件推荐与实际发布不一致

## 元数据需求

`.skill-source.json` 需要覆盖至少这些信息：

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

1. 如果某个 skill 包官方建议通过 Claude 插件安装，则中央仓库不得再把其同名 skill 发布到 `~/.claude/skills`。
2. 发布时必须给出明确提示，避免用户误以为同步失败。
3. 提示信息不仅要打印到终端，也应写入仓库内的可追踪文档。

## 文档需求

中央仓库改造至少要有这些文档：

1. 需求文档
2. 设计文档
3. 遗留问题文档
4. 更新记录文档

README 还必须单独强调：

1. Claude Code 同时支持 standalone skills 和 plugins
2. 某些官方 skill 包不应同步到 `~/.claude/skills`
3. 这不是报错，而是平台策略

## 验收标准

满足以下条件即可认为改造完成：

1. 中央仓库不再依赖长期保留的第三方源码缓存目录。
2. 第三方 skill 的来源真相统一到 `.skill-source.json`。
3. `install-skill` 支持扁平化安装。
4. `update-skill` 可用。
5. Claude Code 的插件推荐包不会被重复发布到 `~/.claude/skills`。
6. README 和架构文档都已更新。
7. 相关验证脚本可证明平台发布结果与策略一致。
