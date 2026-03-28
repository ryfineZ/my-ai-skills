# `.skill-source.json` Schema

> 状态：草案，已进入实施  
> 最后更新：2026-03-28

## 目的

`.skill-source.json` 是中央仓库中每个 skill 的来源真相。

它用于：

- 记录 skill 来源
- 驱动安装后索引展示
- 驱动后续更新
- 驱动多平台发布策略
- 标记 Claude Code 的插件安装例外

## 设计原则

1. 单个 skill 的来源信息应自包含，不依赖额外全局清单。
2. 老字段继续保留，保证向后兼容。
3. 新字段用于支撑 bundle、平台策略和更新分组。

## 当前兼容字段

这些字段已在历史 skill 中出现，必须继续兼容读取：

- `source`
- `source_repo`
- `installed_by`
- `installed_at`
- `updated_at`
- `usage_zh`
- `trigger_keywords`
- `meta_generated_by`
- `meta_generation`
- `meta_language`
- `meta_updated_at`

## 推荐字段

### 基础来源字段

- `source`
  - 取值示例：`custom` / `community`
- `source_type`
  - 取值示例：`custom` / `single` / `bundle`
- `package_name`
  - 第三方包名，例如 `superpowers`
- `source_repo`
  - 来源仓库，例如 `https://github.com/obra/superpowers.git`
- `source_ref`
  - 安装时固定的分支、tag 或 commit；未知时可为空字符串
- `source_path`
  - 当前 skill 在来源仓库中的相对路径
- `bundle_root`
  - 如果是 bundle，表示 bundle 的 skill 根目录；非 bundle 可为空字符串

### 安装与更新字段

- `install_mode`
  - 推荐值：`flattened-copy`
- `update_group`
  - 用于将同一来源仓库下的多个 skill 聚合更新
- `installed_by`
  - 例如：`install-skill`
- `installed_at`
- `updated_at`

### 平台策略字段

- `platform_policies`
  - 每个平台一个子对象

建议至少支持：

```json
{
  "platform_policies": {
    "claude_code": {
      "publish": false,
      "install": "plugin",
      "plugin_name": "superpowers",
      "plugin_marketplace": "superpowers-marketplace",
      "plugin_marketplace_source": "obra/superpowers-marketplace",
      "install_hint": "/plugin install superpowers@superpowers-marketplace"
    }
  }
}
```

其中：

- `publish`
  - 是否发布到该平台的 standalone skills 目录
- `install`
  - 推荐安装方式，例如 `skill` / `plugin`
- `plugin_name`
  - 插件名
- `plugin_marketplace`
  - Claude 插件市场名，例如 `superpowers-marketplace`
- `plugin_marketplace_source`
  - Claude 插件市场来源，例如 `obra/superpowers-marketplace`
- `install_hint`
  - 用户可直接执行的提示命令

## 最小合法模型

### 自定义 skill

```json
{
  "source": "custom",
  "source_type": "custom",
  "installed_at": "2026-03-28T08:00:00Z",
  "updated_at": "2026-03-28T08:00:00Z"
}
```

### 第三方单 skill

```json
{
  "source": "community",
  "source_type": "single",
  "package_name": "frontend-design",
  "source_repo": "vercel-labs/agent-skills",
  "source_ref": "",
  "source_path": "frontend-design",
  "bundle_root": "",
  "install_mode": "flattened-copy",
  "update_group": "vercel-labs/agent-skills",
  "installed_by": "install-skill",
  "installed_at": "2026-03-28T08:00:00Z",
  "updated_at": "2026-03-28T08:00:00Z"
}
```

### 第三方 bundle skill

```json
{
  "source": "community",
  "source_type": "bundle",
  "package_name": "superpowers",
  "source_repo": "https://github.com/obra/superpowers.git",
  "source_ref": "eafe962b18f6c5dc70fb7c8cc7e83e61f4cdde06",
  "source_path": "skills/brainstorming",
  "bundle_root": "skills",
  "install_mode": "flattened-copy",
  "update_group": "obra/superpowers",
  "platform_policies": {
    "claude_code": {
      "publish": false,
      "install": "plugin",
      "plugin_name": "superpowers",
      "plugin_marketplace": "superpowers-marketplace",
      "plugin_marketplace_source": "obra/superpowers-marketplace",
      "install_hint": "/plugin install superpowers@superpowers-marketplace"
    }
  },
  "installed_by": "install-skill",
  "installed_at": "2026-03-28T08:00:00Z",
  "updated_at": "2026-03-28T08:00:00Z"
}
```

## Claude Code 自动安装约定

当某个 skill 包满足以下条件时：

- `platform_policies.claude_code.install = "plugin"`
- 且中央仓库执行的是全局安装
- 且本机存在可用的 Claude CLI / `~/.claude`

则安装流程的终点不应只是生成提示，而应继续：

1. 确保对应插件市场已添加
2. 安装或启用目标 Claude 插件
3. 继续保持 `~/.claude/skills` 的 standalone 排除

如果本机没有可用的 Claude 环境，则保留提示和文档记录，等待后续机器或用户显式执行。

## 向后兼容策略

1. 所有读取逻辑必须继续兼容只有 `source_repo` 和时间戳的旧文件。
2. 新写入逻辑应尽量补齐：
   - `source_type`
   - `package_name`
   - `source_path`
   - `install_mode`
   - `update_group`
3. 在迁移完成前，缺少新字段的 skill 不能视为错误，但应视为待补录对象。
