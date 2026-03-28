---
name: uninstall-skill
description: "Use when removing installed skills from the central repository, especially when cleaning unused community skills, deleting a whole bundle group, or ensuring platform links and installed-skills indexes are cleaned up consistently."
---

# Uninstall Skill

## Overview

删除中央仓库中的已安装 skill，并同步清理平台发布结果、已安装列表和 Claude 插件建议文档。

## 适用场景

- 用户说“删掉这个 skill”
- 用户说“卸载某个 community skill”
- 需要整组删除一个 bundle，例如 `obra/superpowers`
- 清理无用 skill 后，希望多平台链接和 `INSTALLED_SKILLS.md` 一起保持一致

## 工作方式

### 单 skill

按 skill 名删除顶层目录：

```bash
bash ~/.agents/skills/uninstall-skill/uninstall-skill.sh --skill <skill-name>
```

### 按来源组

按 `.skill-source.json.update_group` 删除整组：

```bash
bash ~/.agents/skills/uninstall-skill/uninstall-skill.sh --group obra/superpowers
```

### 列出可卸载对象

```bash
bash ~/.agents/skills/uninstall-skill/uninstall-skill.sh --list
```

## 行为约束

- 只处理中央仓库顶层真实 skill 目录
- 删除后必须重跑平台发布刷新
- 删除后必须重建 `INSTALLED_SKILLS.md`
- 不猜测来源；缺少元数据的 skill 也允许按名字删除，但会在输出中标记

## bundle 注意事项

如果只删除 bundle 中的单个 skill，而不是整组删除：

- 当前是允许的
- 但后续执行 `update-skill --group <update_group>` 时，该 skill 可能被重新装回

因此，对 bundle 更推荐按 `--group` 删除。

## 脚本

- [`uninstall-skill.sh`](/Users/zhangyufan/.agents/skills/uninstall-skill/uninstall-skill.sh)
