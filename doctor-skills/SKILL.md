---
name: doctor-skills
description: "Use when diagnosing central skill repository drift, especially when platform links look inconsistent, .skill-source.json metadata may be incomplete, verify.sh reports issues, or you want a one-command health check before larger maintenance."
---

# Doctor Skills

## Overview

对中央 skills 仓库做健康检查，并在需要时执行轻量修复。

## 适用场景

- `verify.sh` 报错但不知道该先看哪里
- 平台链接和中央仓库实体可能漂移
- 想找出缺失或不完整的 `.skill-source.json`
- 做大改前，先跑一次仓库体检

## 检查内容

`doctor-skills` 会组合两类检查：

1. 调用 [`verify.sh`](/Users/zhangyufan/.agents/skills/shared/scripts/verify.sh)  
   检查平台目录、中央目录、过期链接、发布一致性

2. 补充元数据检查  
   重点看：
   - 社区 skill 是否缺少 `.skill-source.json`
   - `source_repo` / `source_type` / `update_group` 是否缺失
   - `bundle` skill 是否缺少 `bundle_root` / `source_path`
   - 顶层 skill 是否仍是软链接

## 使用方式

### 只做诊断

```bash
bash ~/.agents/skills/doctor-skills/doctor-skills.sh
```

### JSON 输出

```bash
bash ~/.agents/skills/doctor-skills/doctor-skills.sh --json
```

### 先执行轻量修复再诊断

```bash
bash ~/.agents/skills/doctor-skills/doctor-skills.sh --repair
```

`--repair` 当前只做安全的轻量操作：
- 重建平台链接
- 重建 `INSTALLED_SKILLS.md`

不会自动猜测来源元数据，也不会自动删除 skill。

## 当前边界

- 不自动修补缺失的 `source_repo`
- 不自动选择 bundle 删除策略
- 不替代 `update-skill` 或 `uninstall-skill`

## 脚本

- [`doctor-skills.sh`](/Users/zhangyufan/.agents/skills/doctor-skills/doctor-skills.sh)
