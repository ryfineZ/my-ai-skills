---
name: update-skill
description: "Use when updating installed skills from their original repositories, especially for centrally managed skills with .skill-source.json metadata. Supports single-skill updates and bundle-aware updates grouped by update_group."
---

# Update Skill

更新已经安装到中央仓库的 skills。

这个 skill 依赖每个 skill 自带的 `.skill-source.json`，按来源仓库和 `update_group` 驱动更新，而不是依赖手工维护的第三方仓库清单。

## 适用场景

- 用户说“更新这个 skill”
- 用户说“同步一下已安装的 skills”
- 需要更新某个 bundle 来源，例如 `superpowers`
- 需要先看哪些 skill 可更新，再决定执行

## 工作方式

### 单 skill

如果 skill 的来源类型是 `single`，则直接根据 `.skill-source.json` 中的：

- `source_repo`
- `source_path`

回调 [`install-skill`](/Users/zhangyufan/.agents/skills/install-skill/SKILL.md) 的安装链路完成更新。

### bundle

如果 skill 的来源类型是 `bundle`，则按 `update_group` 聚合，只更新一次来源仓库。

更新时会使用：

- `source_repo`
- `bundle_root`
- `update_group`

回调 `install-skill --all-skills` 完成整包更新。

## Claude Code 注意事项

如果某个来源包在 `.skill-source.json.platform_policies.claude_code` 中标记为：

- `publish = false`
- `install = plugin`

则更新后不应发布到 `~/.claude/skills`，而应按同一来源包的 Claude 插件路径继续收敛状态。

由于 `update-skill` 的实际更新动作会回调全局 `install-skill`，因此当某个包要求 Claude 插件安装时：
- 仍会继续通过中央仓库完成更新
- 不会发布到 `~/.claude/skills`
- 若本机存在可用的 Claude CLI / `~/.claude`，则会继续自动执行对应插件的安装 / 更新 / 启用路径，而不是只保留提示

## 使用方式

### 查看可更新对象

```bash
bash ~/.agents/skills/update-skill/update-skill.sh --list
```

### 更新单个 skill

```bash
bash ~/.agents/skills/update-skill/update-skill.sh --skill brainstorming
```

### 更新一个来源分组

```bash
bash ~/.agents/skills/update-skill/update-skill.sh --group obra/superpowers
```

### 更新全部可更新 skill

```bash
bash ~/.agents/skills/update-skill/update-skill.sh --all
```

## 脚本

主脚本：

- [`update-skill.sh`](/Users/zhangyufan/.agents/skills/update-skill/update-skill.sh)

## 当前边界

当前版本优先覆盖中央仓库场景：

- 中央仓库顶层 skill
- `.skill-source.json` 完整或基本可读
- 单 skill 仓库和 bundle 仓库

如果某个 skill 缺少必要元数据，脚本会跳过并提示，而不是猜测来源。
