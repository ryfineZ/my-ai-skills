---
name: code-quality-check
description: 通用代码质量检查。在提交代码前自动执行，根据项目类型应用对应的检查规则
argument-hint: [项目路径]
disable-model-invocation: false

compatibility:
  claude-code: full
  codex: basic
  gemini: basic
---

# 通用代码质量检查 Skill

在提交代码前自动检查代码质量，根据项目类型智能应用对应的检查规则。

---

## 🎯 核心特性

### 1. 智能项目类型识别

自动检测项目类型，无需手动配置：

- **Obsidian 插件**：检测 `manifest.json` 中的 Obsidian 特征
- **浏览器扩展**：检测 `manifest.json` 中的 `manifest_version`
- **React/Vue/Angular**：检测 `package.json` 中的依赖
- **Electron 应用**：检测 `package.json` 中的 Electron
- **通用项目**：其他所有项目

### 2. 分层检查规则

根据项目类型应用不同级别的规则：

```
通用规则（所有项目）
    ↓
前端规则（前端项目）
    ↓
平台特定规则（Obsidian/浏览器扩展/Electron）
```

### 3. 模块化设计

规则独立管理，易于扩展：

```
code-quality-check/
├── SKILL.md
└── scripts/
    ├── check.sh           # 主检查脚本
    └── rules/             # 规则库
        ├── common.sh      # 通用规则
        ├── frontend.sh    # 前端规则
        └── obsidian.sh    # Obsidian 规则
```

---

## 📋 检查规则

### 通用规则（所有项目）

| 规则 | 级别 | 说明 |
|------|------|------|
| 硬编码的敏感信息 | 🔴 必须修复 | API key、password、secret、token |
| 正则表达式控制字符 | 🔴 必须修复 | `\x00-\x1f` 等控制字符 |
| 未使用的变量 | 🟡 建议优化 | ESLint 检测 |

### 前端规则（React/Vue/前端项目）

| 规则 | 级别 | 说明 |
|------|------|------|
| innerHTML/outerHTML | 🔴 必须修复 | XSS 安全风险 |
| dangerouslySetInnerHTML | 🟡 建议优化 | React 特定（需注意） |
| console.log 残留 | 🟡 建议优化 | 生产环境清理 |

### Obsidian 插件规则

| 规则 | 级别 | 说明 |
|------|------|------|
| 直接创建 style 元素 | 🔴 必须修复 | 必须使用 styles.css |
| 导入 Node.js 模块 | 🔴 必须修复 | 禁止 fs、path 等模块 |

---

## 🚀 使用方式

### 自动触发（推荐）

通过 `commit-conventional` skill 自动触发：

```bash
# 1. 修改代码
# 2. 暂存文件
git add .

# 3. 触发提交（会自动执行检查）
# 对 AI 说："帮我提交代码"
```

### 手动触发

```bash
# 在项目根目录运行
bash ~/.claude/skills/code-quality-check/scripts/check.sh

# 或指定项目路径
bash ~/.claude/skills/code-quality-check/scripts/check.sh /path/to/project
```

---

## 🔧 常见问题修复

### 1. innerHTML/outerHTML（XSS 风险）

**❌ 错误：**
```typescript
element.innerHTML = `<div class="content">${text}</div>`;
```

**✅ 修复：**
```typescript
// 通用方案
const div = document.createElement('div');
div.className = 'content';
div.textContent = text;
element.appendChild(div);

// Obsidian 专用
const div = element.createEl('div', { cls: 'content', text: text });
```

### 2. 创建 style 元素（Obsidian）

**❌ 错误：**
```typescript
const style = document.createElement('style');
style.textContent = '.my-class { color: red; }';
document.head.appendChild(style);
```

**✅ 修复：**
将 CSS 移到 `styles.css` 文件

### 3. Node.js 模块（Obsidian）

**❌ 错误：**
```typescript
import fs from 'fs';
const content = fs.readFileSync('file.txt', 'utf-8');
```

**✅ 修复：**
```typescript
const file = this.app.vault.getAbstractFileByPath('file.txt');
if (file instanceof TFile) {
    const content = await this.app.vault.read(file);
}
```

### 4. 硬编码敏感信息

**❌ 错误：**
```typescript
const apiKey = "sk_live_1234567890abcdef";
```

**✅ 修复：**
```typescript
// 使用环境变量或用户配置
const apiKey = this.settings.apiKey;
```

---

## 🎯 与 commit-conventional 集成

本 Skill 已集成到 `commit-conventional` 中，在提交时自动执行。

---

**版本**：v2.0（通用代码质量检查）
**最后更新**：2026-01-23
