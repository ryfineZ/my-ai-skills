# Skills 编写最佳实践

> 状态：有效  
> 最后更新：2026-03-28

本文件是**编写 skill 的经验指南**。  
它回答的是：

- skill 应该怎么写，才更容易被多个客户端识别和正确使用
- skill 内容应该怎么组织，才更稳定、可维护

它**不是**中央仓库当前实现的权威说明。以下内容请看正式文档：

- 仓库架构与目录职责：[`README.md`](/Users/zhangyufan/.agents/skills/README.md)
- 中央仓库设计：[`skills-central-repo-design.md`](/Users/zhangyufan/.agents/skills/docs/architecture/skills-central-repo-design.md)
- 来源元数据：[`skill-source-schema.md`](/Users/zhangyufan/.agents/skills/docs/architecture/skill-source-schema.md)
- Claude 插件例外：[`claude-plugin-recommendations.md`](/Users/zhangyufan/.agents/skills/docs/architecture/claude-plugin-recommendations.md)

---

## 1. 总原则

### 1.1 先保证 skill 本体通用，再考虑平台增强

优先写出：

- 只依赖 `SKILL.md`
- 即使没有平台特性也能成立
- 不依赖某个单一客户端私有行为

平台增强能力可以有，但不能让核心流程依赖它。

### 1.2 不要把“仓库发布策略”写进 skill 本体

当前中央仓库的发布差异，例如：

- 是否发布到 `~/.claude/skills`
- Claude Code 是否建议改走 plugin
- 来源仓库、更新分组、bundle 信息

这些都属于 [`.skill-source.json`](/Users/zhangyufan/.agents/skills/docs/architecture/skill-source-schema.md) 的职责，不应混进 `SKILL.md`。

### 1.3 skill 是“可复用知识”，不是“问题复盘”

适合做成 skill 的内容：

- 可重复触发的工作流
- 稳定的判断规则
- 反复要用的工具说明
- 经验证有效的模式

不适合做成 skill 的内容：

- 只适用于某个项目的一次性方案
- 纯粹的开发日志
- 可以直接自动化、无需模型判断的机械步骤

---

## 2. 推荐结构

### 2.1 最小结构

```text
skill-name/
├── SKILL.md
└── .skill-source.json
```

其中：

- `SKILL.md` 是 skill 主体
- `.skill-source.json` 是中央仓库来源元数据

### 2.2 常见扩展结构

```text
skill-name/
├── SKILL.md
├── .skill-source.json
├── scripts/
├── references/
└── assets/
```

用途建议：

- `scripts/`
  放可执行脚本、稳定工具、重复性强的辅助程序

- `references/`
  放较长的补充文档、规范、API 说明、流程细节

- `assets/`
  放模板、示例资源、输出素材

### 2.3 不推荐的结构

不再推荐维护：

- `SKILL.basic.md`
- “Claude 完整版 / 通用基础版” 双文件分发
- 仅为了某个平台复制一套几乎相同的 skill

当前仓库的方向是：

- skill 实体保持单一
- 平台差异尽量放在发布层和元数据层处理

---

## 3. SKILL.md 写法

### 3.1 frontmatter 只保留真正有价值的字段

最稳的最小模板：

```yaml
---
name: your-skill-name
description: Use when [具体触发条件]
---
```

优先保证这两个字段：

- `name`
- `description`

### 3.2 `name` 规则

- 使用小写字母、数字、连字符
- 与目录名保持一致
- 尽量短，但要表达清楚语义

推荐：

- `update-skill`
- `doctor-skills`
- `agent-rules-sync`

不推荐：

- `UpdateSkill`
- `skill_update`
- `my-awesome-skill-v2-final`

### 3.3 `description` 规则

`description` 的重点是：**什么时候该用这个 skill**，不是“它内部做了什么”。

推荐写法：

- 从 `Use when ...` 开始
- 写清触发条件、症状、适用场景
- 避免在这里塞实现细节

推荐：

```yaml
description: Use when updating installed skills from their original repositories, especially for centrally managed skills with .skill-source.json metadata.
```

不推荐：

```yaml
description: This skill scans metadata, groups bundles, reinstalls directories, refreshes links, and rewrites installed lists.
```

---

## 4. 内容组织建议

### 4.1 把 `SKILL.md` 写成“入口文档”

好的 `SKILL.md` 应该让模型快速知道：

- 什么时候用
- 不该什么时候用
- 关键步骤是什么
- 需要时去哪里看细节

推荐结构：

```markdown
# Skill Title

## Overview

## 适用场景

## 核心流程

## 关键约束

## 使用方式

## 脚本 / 参考文件
```

### 4.2 长内容移到 `references/`

如果某段内容满足任一条件，建议拆出去：

- 超过 100 行
- 只有少数场景才会用到
- 属于详细参考，而不是核心流程

### 4.3 重复逻辑优先脚本化

如果你发现某个 skill 每次都会重复：

- 同一段 shell
- 同一段 Python
- 同一类目录扫描
- 同一套校验逻辑

优先放到 `scripts/`，而不是把大量代码直接塞进 `SKILL.md`。

---

## 5. 跨工具兼容建议

### 5.1 核心流程不要依赖单一平台私有特性

像下面这些能力，不能假设所有客户端都支持：

- hooks
- tool allowlist
- 特定平台 commands
- plugin 生命周期

所以建议：

- 把它们写成“可选增强”
- 不要让 skill 的核心路径依赖这些能力

### 5.2 Claude Code 要特殊看待，但不要反向绑架通用 skill

Claude Code 支持的插件能力比普通 standalone skills 更强。  
因此：

- 若某个官方包明确建议 Claude 用 plugin 安装
- 中央仓库应在发布层处理排除
- 不要为了 Claude 单独复制一套 skill 结构

### 5.3 不要在最佳实践里夸大“跨工具完全等价”

更稳的说法是：

- 尽量让 skill 本体通用
- 平台特性通过增强路径处理
- 不追求所有平台 100% 同形态

---

## 6. 与当前中央仓库的关系

### 6.1 新建自定义 skill

你自己创建的 skill，应直接落在：

- [`~/.agents/skills`](/Users/zhangyufan/.agents/skills)

并提交到中央仓库 Git。

### 6.2 第三方安装 skill

第三方 skill 不要手工复制散装文件。  
统一走：

- [`install-skill`](/Users/zhangyufan/.agents/skills/install-skill/SKILL.md)

安装后会自动：

- 扁平化落地到中央仓库顶层
- 写 `.skill-source.json`
- 按平台发布

### 6.3 skill 的来源信息不要手填到 README

来源真相应写在：

- `.skill-source.json`

展示层如 [`INSTALLED_SKILLS.md`](/Users/zhangyufan/.agents/skills/INSTALLED_SKILLS.md) 由脚本生成，不要手工维护。

---

## 7. 编写检查清单

创建或修改 skill 后，至少检查这些：

- `name` 是否和目录名一致
- `description` 是否写的是触发条件，不是内部流程
- `SKILL.md` 是否足够短、足够清晰
- 复杂细节是否已经拆到 `references/` 或 `scripts/`
- 是否避免了平台私有能力作为核心依赖
- 是否补了 `.skill-source.json`

推荐命令：

```bash
python3 ~/.agents/skills/create-skill/scripts/quick_validate.py ~/.agents/skills/your-skill
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
SKILLS_DIR="$HOME/.agents/skills" bash "$HOME/.agents/skills/doctor-skills/doctor-skills.sh"
```

---

## 8. 常见反模式

### 8.1 `description` 写成实现摘要

问题：

- 模型可能只看描述，不看正文
- skill 触发会变模糊

### 8.2 为每个平台维护一套几乎一样的 skill

问题：

- 维护成本高
- 内容漂移快
- 容易出现行为不一致

### 8.3 把来源、安装、发布策略写死在 `SKILL.md`

问题：

- 污染 skill 主体
- 和中央仓库元数据职责冲突

### 8.4 把大段参考内容直接塞进主文档

问题：

- 上下文成本高
- 模型更难扫描核心流程

---

## 9. 一句话建议

写 skill 时，优先追求这四件事：

1. 触发条件清晰
2. 核心流程精炼
3. 细节按需拆分
4. 平台差异留给发布层和元数据层
