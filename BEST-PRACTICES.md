# 跨工具 Skills 最佳实践指南

本指南帮助你创建兼容多个 AI 编码工具的 Skills。

---

## 📋 通用兼容性原则

### 1. **分层设计**

```
┌─────────────────────────────────┐
│  核心功能层（所有工具支持）        │  ← 必需功能
├─────────────────────────────────┤
│  标准扩展层（大部分工具支持）      │  ← 常见功能
├─────────────────────────────────┤
│  工具特定层（特定工具支持）        │  ← 可选增强
└─────────────────────────────────┘
```

### 2. **Frontmatter 字段优先级**

| 优先级 | 字段 | 兼容性 |
|--------|------|--------|
| **必需** | `name`, `description` | 所有工具 |
| **推荐** | `argument-hint`, `disable-model-invocation` | 大部分工具 |
| **可选** | `compatibility`, `allowed-tools`, `model` | Claude Code |
| **高级** | `hooks`, `context`, `agent` | Claude Code |

### 3. **内容组织原则**

```markdown
---
# 必需字段（所有工具）
name: skill-name
description: 清晰的描述

# 标准字段（大部分工具）
argument-hint: [参数提示]
disable-model-invocation: false

# 兼容性标记（推荐添加）
compatibility:
  claude-code: full
  codex: basic
  gemini: basic

# 高级字段（工具特定，注释掉）
# allowed-tools: Read, Grep, Bash
# model: sonnet
---

# 核心功能（所有工具都能理解）

基础指令和流程...

## 标准功能（大部分工具支持）

常见操作...

---

## 🔧 高级功能（工具特定）

> **兼容性说明**：以下功能仅在特定工具中可用

### Claude Code 专属功能

...
```

---

## 🛠️ 实用模板

### **模板 1：通用 Skill（推荐）**

```yaml
---
name: your-skill-name
description: 简洁清晰的描述，说明何时使用此 Skill
argument-hint: [参数说明]
disable-model-invocation: false

# 兼容性标记
compatibility:
  claude-code: full
  codex: basic
  gemini: basic
  github-copilot: basic
---

# Your Skill Name

## 核心功能

所有 AI 工具都支持的基础功能...

## 使用步骤

1. 步骤一
2. 步骤二
3. 步骤三

---

## 🔧 高级功能（可选）

> **兼容性**：以下功能仅在支持的工具中启用

### 自动化验证（Claude Code）

说明如何启用 Hooks...

### 其他增强功能

...
```

---

### **模板 2：Claude Code 完整版 + 基础版**

**目录结构**：
```
your-skill/
├── SKILL.md              # Claude Code 完整版
├── SKILL.basic.md        # 通用基础版（可选）
├── COMPATIBILITY.md      # 兼容性说明
└── scripts/              # 辅助脚本
    └── validate.sh
```

**SKILL.md（完整版）**：
```yaml
---
name: your-skill
description: ...
allowed-tools: Read, Grep, Bash
model: sonnet

hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
---

# 完整功能实现...
```

**SKILL.basic.md（基础版）**：
```yaml
---
name: your-skill
description: ...
---

# 基础功能实现（无 Hooks）...
```

---

## 📊 兼容性测试清单

创建 Skill 后，使用以下清单验证：

### **基础测试**

- [ ] 所有工具都能识别 Skill（出现在列表中）
- [ ] description 清晰，能正确触发
- [ ] 核心功能在所有工具中都能执行
- [ ] 没有报错或警告

### **高级功能测试**

- [ ] Claude Code 中高级功能正常工作
- [ ] 其他工具会优雅忽略不支持的字段
- [ ] 文档中清晰标注了兼容性信息

### **测试脚本**

```bash
#!/bin/bash
# test-skill-compatibility.sh

SKILL_NAME="your-skill-name"

echo "🧪 测试 Skill 兼容性: $SKILL_NAME"
echo ""

# 测试 Claude Code
if command -v claude &> /dev/null; then
    echo "测试 Claude Code..."
    claude "列出可用的 skills" | grep -i "$SKILL_NAME" && echo "✅ Claude Code" || echo "❌ Claude Code"
fi

# 测试 Codex
if command -v codex &> /dev/null; then
    echo "测试 Codex..."
    codex "列出可用的 skills" | grep -i "$SKILL_NAME" && echo "✅ Codex" || echo "❌ Codex"
fi

# 测试 Gemini
if command -v gemini &> /dev/null; then
    echo "测试 Gemini..."
    gemini "列出可用的 skills" | grep -i "$SKILL_NAME" && echo "✅ Gemini" || echo "❌ Gemini"
fi

echo ""
echo "✅ 兼容性测试完成"
```

---

## 🎯 常见场景处理

### **场景 1：Hooks 功能**

**问题**：Hooks 是 Claude Code 特有的，其他工具不支持。

**解决方案**：
1. 在 frontmatter 中注释掉 hooks 配置
2. 在文档中提供启用说明
3. 核心功能不依赖 Hooks

```yaml
---
name: example-skill
description: ...

# 需要时取消注释（仅 Claude Code）
# hooks:
#   PreToolUse:
#     - matcher: "Bash"
#       hooks:
#         - type: command
#           command: "./scripts/check.sh"
---

# 核心功能（不依赖 Hooks）

执行主要任务...

---

## 🔧 可选：启用自动验证（Claude Code）

在 frontmatter 中取消注释 hooks 配置以启用。
```

---

### **场景 2：工具限制（allowed-tools）**

**问题**：allowed-tools 限制可能不被所有工具支持。

**解决方案**：
```yaml
---
name: read-only-skill
description: 只读分析 Skill

# 可选：限制工具（仅 Claude Code 有效）
# allowed-tools: Read, Grep, Glob
---

# 核心指令

**注意**：此 Skill 设计为只读操作，不会修改文件。

## 分析步骤

1. 使用 Read/Grep 读取文件
2. 分析内容
3. 返回结果（不修改文件）
```

---

### **场景 3：动态上下文（!`command`）**

**好消息**：大部分工具都支持动态上下文注入！

```yaml
---
name: pr-analysis
description: 分析 Pull Request
---

# PR 分析

## 当前 PR 信息

**变更文件**：
!`gh pr diff --name-only`

**代码差异**：
!`gh pr diff`

## 分析任务

基于以上信息分析 PR...
```

**兼容性**：✅ Claude Code、✅ Codex、✅ Gemini

---

## 📚 示例：完整的跨工具兼容 Skill

### **code-review Skill**

```yaml
---
name: code-review
description: 全面的代码审查，检查质量、安全和最佳实践。当用户要求审查代码或代码变更后使用
argument-hint: [文件路径或范围]
disable-model-invocation: false

compatibility:
  claude-code: full
  codex: basic
  gemini: basic
  github-copilot: basic

# Claude Code 高级功能（需要时取消注释）
# allowed-tools: Read, Grep, Bash
# model: sonnet
---

# 代码审查 Skill

全面审查代码质量、安全性和最佳实践。

## 审查清单

### 1. 代码质量
- [ ] 代码清晰易读
- [ ] 函数和变量命名良好
- [ ] 没有重复代码（DRY 原则）
- [ ] 适当的代码注释

### 2. 类型安全（TypeScript/Python）
- [ ] 使用类型注解
- [ ] 无 any 类型（TypeScript）
- [ ] 类型推断正确

### 3. 错误处理
- [ ] 显式错误处理，不静默失败
- [ ] 边界条件已考虑
- [ ] 异常情况有适当处理

### 4. 安全性
- [ ] 无硬编码密钥或敏感信息
- [ ] 输入验证已实现
- [ ] SQL 注入防护（如适用）

### 5. 测试
- [ ] 关键逻辑有单元测试
- [ ] 测试覆盖充分
- [ ] 边界用例已测试

### 6. 文档
- [ ] 复杂逻辑有注释
- [ ] API 变更有文档
- [ ] README 更新（如需要）

## 审查流程

### 步骤 1：读取代码

使用参数 `$ARGUMENTS` 确定审查范围，如果未指定，检查最近的变更：

```bash
git diff --staged
```

### 步骤 2：按清单检查

逐项检查上述清单，记录发现的问题。

### 步骤 3：生成报告

按优先级组织反馈：

- 🔴 **严重问题**（必须修复）：安全漏洞、类型错误、逻辑错误
- 🟡 **警告**（应该修复）：代码规范、可读性问题
- 🟢 **建议**（考虑改进）：性能优化、架构建议

### 步骤 4：提供修复示例

对于严重问题和警告，提供具体的修复代码示例。

---

## 🔧 高级功能（可选）

> **兼容性说明**：
> - ✅ **Claude Code**：支持自动化验证
> - ⚠️ **其他工具**：手动执行审查流程

### 自动化检查（Claude Code）

在 frontmatter 中添加以下配置启用自动化：

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/pre-review-check.sh"
```

### 工具限制

限制为只读操作（推荐）：

```yaml
allowed-tools: Read, Grep, Glob
```

---

## 使用示例

```bash
# 审查所有暂存的变更
/code-review

# 审查特定文件
/code-review src/auth/login.ts

# 审查整个目录
/code-review src/components/
```
```

---

## 💡 总结建议

### **优先级顺序**

1. **✅ 优先保证基础功能通用**
   - 核心流程在所有工具都能用
   - 最小化对工具特定功能的依赖

2. **✅ 高级功能作为可选增强**
   - 用注释标注工具特定功能
   - 提供启用说明
   - 不影响基础使用

3. **✅ 清晰的兼容性文档**
   - 在 Skill 中标注兼容性
   - 创建 COMPATIBILITY.md
   - 说明降级行为

### **推荐的文件组织**

```
~/AI-Skills/
├── skill-name/
│   ├── SKILL.md              # 主 Skill（通用 + 可选高级功能）
│   ├── COMPATIBILITY.md      # 兼容性说明
│   ├── README.md             # 使用文档
│   └── scripts/              # 辅助脚本（可选）
│       └── validate.sh
└── BEST-PRACTICES.md         # 本文档
```

---

## 🎓 快速参考

### **跨工具兼容的 Frontmatter 模板**

```yaml
---
# === 必需字段（所有工具） ===
name: skill-name
description: 简洁清晰的描述

# === 标准字段（推荐） ===
argument-hint: [参数]
disable-model-invocation: false

# === 兼容性标记（推荐） ===
compatibility:
  claude-code: full
  codex: basic
  gemini: basic

# === 高级功能（可选，注释掉） ===
# allowed-tools: Read, Grep, Bash
# model: sonnet
# context: default
# hooks:
#   PreToolUse:
#     - matcher: "Bash"
#       hooks:
#         - type: command
#           command: "./scripts/check.sh"
---
```

### **工具特定功能对照表**

| 功能 | Claude Code | Codex | Gemini | GitHub Copilot |
|------|-------------|-------|--------|----------------|
| 基础 SKILL.md | ✅ | ✅ | ✅ | ✅ |
| 动态上下文 !`cmd` | ✅ | ✅ | ✅ | ⚠️ |
| allowed-tools | ✅ | ❌ | ❌ | ❌ |
| hooks | ✅ | ❌ | ❌ | ❌ |
| context: fork | ✅ | ❌ | ❌ | ❌ |
| model 指定 | ✅ | ⚠️ | ⚠️ | ❌ |

**图例**：
- ✅ 完全支持
- ⚠️ 部分支持或未确认
- ❌ 不支持（会被忽略）
