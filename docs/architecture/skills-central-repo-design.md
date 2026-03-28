# Skills 中央仓库改造设计

> 状态：持续实施中  
> 最后更新：2026-03-28

## 设计目标

将中央仓库收敛成：

- 单一权威目录
- 扁平化安装结果
- 统一来源元数据
- 多平台差异化发布
- 可追踪的架构文档体系

## 当前状态与目标状态

### 当前状态

当前中央仓库使用了以下模型：

- [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 作为权威目录和发布根
- `install-skill` 已支持 bundle 安装与 `.skill-source.json` 写入
- `update-skill` 已支持按 `update_group` 聚合更新
- 平台发布链路已开始读取 `platform_policies.claude_code`
- `superpowers` 已通过新框架重装为顶层真实目录，并对 Claude Code 执行插件排除发布

这个模型已能运行，但存在这些问题：

- 历史 skill 的 `.skill-source.json` 覆盖仍不完整
- `update-skill` 还未覆盖 bundle 增删等完整场景
- 远程安全预审仍依赖 GitHub API/网络稳定性，需要继续观察长期稳定性

### 目标状态

目标模型如下：

1. [`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 仍为唯一权威目录和唯一发布根。
2. 每个顶层 skill 都是完整真实目录。
3. 不长期保留第三方源码缓存目录。
4. `.skill-source.json` 成为唯一来源真相。
5. 所有平台发布逻辑都基于顶层 skill + `.skill-source.json`。
6. Claude Code 对插件推荐包采取排除发布策略。
7. 旧版 `superpowers` 不做原位迁移，改为在新框架完成后删除并重新安装验收。

## 目录职责

### 中央仓库

[`~/.agents/skills`](/Users/zhangyufan/.agents/skills) 负责：

- 存放所有最终可消费的 skill
- 存放来源元数据
- 存放文档、脚本、验证工具
- 作为 Git 同步对象

### 平台目录

平台目录只负责消费中央仓库发布结果：

- `~/.codex/skills`
- `~/.claude/skills`
- `~/.cursor/skills`
- `~/.gemini/skills`
- 其他平台目录

平台目录不承担来源管理职责。

## Skill 安装形态

### 自定义 skill

自定义 skill 直接以顶层真实目录存在，例如：

- [`~/.agents/skills/create-skill`](/Users/zhangyufan/.agents/skills/create-skill)

### 第三方 skill

第三方 skill 安装后也落为顶层真实目录，例如：

- [`~/.agents/skills/brainstorming`](/Users/zhangyufan/.agents/skills/brainstorming)

要求：

- 复制整个 skill 目录
- 保留 `SKILL.md`
- 保留 `references/`、`scripts/`、附属 markdown / prompt / shell 文件

不允许只复制 `SKILL.md`。

## 来源元数据模型

`.skill-source.json` 是唯一来源真相。

### 推荐字段

```json
{
  "source": "community",
  "source_type": "bundle",
  "package_name": "superpowers",
  "source_repo": "https://github.com/obra/superpowers.git",
  "source_ref": "eafe962b18f6c5dc70fb7c8cc7e83e61f4cdde06",
  "bundle_root": "skills",
  "source_path": "skills/brainstorming",
  "install_mode": "flattened-copy",
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
  "installed_at": "2026-03-28T08:00:00Z",
  "updated_at": "2026-03-28T08:00:00Z"
}
```

### 设计原则

1. 任何更新和发布逻辑都优先读取 `.skill-source.json`。
2. 单 skill 和 bundle 只在元数据层区分，不在仓库结构层区分。
3. 平台差异通过 `platform_policies` 表达，不通过脚本硬编码例外列表表达。

## 安装流程设计

### 单 skill 仓库

1. 拉取远端仓库到临时目录
2. 识别唯一 skill 目录
3. 完整复制到中央仓库顶层
4. 写入 `.skill-source.json`
5. 发布到各平台
6. 更新索引与文档

### bundle 仓库

1. 拉取远端仓库到临时目录
2. 根据仓库结构识别 bundle 根目录
3. 扫描 bundle 中的所有 skill
4. 将每个 skill 完整复制到中央仓库顶层
5. 为每个 skill 写入 `.skill-source.json`
6. 对平台插件策略进行识别和记录
7. 发布到各平台
8. 更新索引与文档

### 为什么采用扁平化复制

不是因为所有客户端都不支持 bundle。  
主要原因是：

- 中央仓库需要统一来源元数据
- 需要按 skill 粒度安装、卸载、更新
- 需要按平台过滤发布
- Claude Code 需要对部分包进行插件排除

因此扁平化是**管理模型的选择**，不是单纯的运行兼容性补丁。

## 更新流程设计

更新应新增独立入口，由 `update-skill` 驱动。

### 流程

1. 扫描中央仓库顶层 skill
2. 读取每个 skill 的 `.skill-source.json`
3. 按 `update_group` 聚合来源
4. 每个来源仓库只拉取一次
5. 对应回放更新：
   - 更新已有 skill
   - 补装新增 skill
   - 记录或处理已删除 skill
6. 重建平台发布结果
7. 更新 `INSTALLED_SKILLS.md`
8. 记录变更到 changelog

## 发布流程设计

发布从中央仓库顶层 skill 出发。

### 规则

1. 默认发布到所有支持 standalone skills 的平台目录。
2. 发布前读取 `.skill-source.json`。
3. 若平台策略禁止发布，则跳过并输出提示。
4. 发布后清理过期链接。

### Claude Code 专项策略

对于官方建议使用插件安装的 skill 包：

- 不发布到 `~/.claude/skills`
- 全局安装时，如果本机可用 Claude Code，则自动执行插件市场添加与插件安装 / 启用
- 同时将插件信息写入文档，便于新设备或缺失环境时补装

这是为了避免 Claude Code 同时看到：

- 官方插件版 skill
- 中央仓库 standalone 版同名 skill

## Claude Code 设计决策

Claude Code 必须视为平台特例。

原因：

- 插件能力大于 standalone skills
- 插件支持 commands、hooks、session start、版本化分发
- 官方 `superpowers` 已明确推荐 Claude 通过插件安装

因此：

- 中央仓库不尝试复刻 Claude 插件能力
- 中央仓库负责识别、排除、记录，并在可用时直接完成插件安装
- 若当前机器缺少 Claude 环境，则退化为记录和提示，等待后续补装

## 文档设计

本次改造采用以下文档体系：

- 需求：[`skills-central-repo-requirements.md`](/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-requirements.md)
- 设计：[`skills-central-repo-design.md`](/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-design.md)
- 遗留问题：[`skills-central-repo-open-issues.md`](/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-open-issues.md)
- 更新记录：[`skills-central-repo-changelog.md`](/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-changelog.md)

README 只作为入口文档，不承载完整架构设计。

## 实施阶段

### Phase 1：文档定稿

- 建立架构文档
- 更新 README 的 Claude Code 注意事项

### Phase 2：元数据统一

- 扩展 `.skill-source.json`
- 补齐已有 skill 元数据

### Phase 3：链路重构

- 改造 `install-skill`
- 新增 `update-skill`
- 改造平台发布脚本

### Phase 4：旧版清理与新框架验收

- 删除旧版 `superpowers`
- 用新框架重新安装 `superpowers`
- 淘汰 `THIRD_PARTY_SKILLS.toml`
- 清理第三方 bundle 缓存依赖
