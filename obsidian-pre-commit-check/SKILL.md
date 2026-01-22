---
name: obsidian-pre-commit-check
description: Obsidian 插件 commit 前代码检查。在提交 Obsidian 插件代码前自动执行，检查常见的审查问题
argument-hint: [项目路径]
disable-model-invocation: false

compatibility:
  claude-code: full
  codex: basic
  gemini: basic
---

# Obsidian 插件 Commit 前检查 Skill

在提交代码前自动检查 Obsidian 插件的常见问题，避免 PR 被 ObsidianReviewBot 拒绝。

## 检查项目

### 🔴 必须修复（Required）

1. **禁止直接创建 style 元素**
   - 检查：`createElement('style')` 或 `new HTMLStyleElement()`
   - 正确做法：使用 `styles.css` 文件

2. **禁止使用 innerHTML/outerHTML**
   - 检查：`.innerHTML` 或 `.outerHTML` 赋值
   - 正确做法：使用 `createEl()` 或 `textContent`

3. **正则表达式控制字符**
   - 检查：`/[\x00-\x1f]/` 等控制字符
   - 正确做法：使用 Unicode 转义或避免

4. **async 函数必须有 await**
   - 检查：async 函数体内没有 await
   - 正确做法：添加 await 或移除 async

5. **禁止导入 Node.js 模块**
   - 检查：`import.*['"]fs['"]` 或 `import.*['"]path['"]`
   - 正确做法：使用 Obsidian Vault API

### 🟡 建议优化（Optional）

6. **未使用的变量**
   - 检查：定义但未使用的变量
   - 建议：删除或使用下划线前缀

---

## 执行流程

### 步骤 1：确定项目路径

优先级：
1. 用户提供的参数 `$ARGUMENTS`
2. 当前工作目录如果是 Obsidian 插件项目
3. 询问用户项目路径

默认 O2Any 项目路径：`/Users/zhangyufan/Workspace/Projects/Obsidian-Plugins/O2Any`

### 步骤 2：检查暂存的文件

运行 `git diff --staged --name-only` 获取即将提交的文件列表。

只检查暂存区中的 `.ts` 和 `.js` 文件。

### 步骤 3：执行检查

对每个暂存的文件执行以下检查：

#### 检查 1：禁止直接创建 style 元素

```bash
grep -n "createElement.*['\"]style['\"]" file.ts
```

如果发现：
- 位置：文件名:行号
- 问题：直接创建 style 元素
- 修复：将 CSS 移到 `styles.css` 文件

#### 检查 2：禁止使用 innerHTML/outerHTML

```bash
grep -n "\.innerHTML\s*=" file.ts
grep -n "\.outerHTML\s*=" file.ts
```

如果发现：
- 位置：文件名:行号
- 问题：使用 innerHTML/outerHTML
- 修复：使用 `createEl()` 或 `textContent`

#### 检查 3：正则表达式控制字符

```bash
grep -n "\\\\x[0-1][0-9a-fA-F]" file.ts
```

如果发现：
- 位置：文件名:行号
- 问题：正则表达式包含控制字符
- 修复：使用 Unicode 转义或重写正则

#### 检查 4：async 函数必须有 await

这个检查相对复杂，需要：
1. 找到所有 `async` 函数定义
2. 检查函数体内是否有 `await` 关键字

简化检查：
```bash
# 查找可疑的 async 函数（启发式）
grep -n "async.*{" file.ts | while read line; do
  # 提示可能需要人工检查
done
```

#### 检查 5：禁止导入 Node.js 模块

```bash
grep -n "import.*['\"]fs['\"]" file.ts
grep -n "import.*['\"]path['\"]" file.ts
grep -n "require.*['\"]fs['\"]" file.ts
grep -n "require.*['\"]path['\"]" file.ts
```

如果发现：
- 位置：文件名:行号
- 问题：导入 Node.js 内置模块
- 修复：使用 Obsidian API 替代

#### 检查 6：未使用的变量

运行 ESLint（如果项目已配置）：
```bash
npx eslint --no-eslintrc --rule 'no-unused-vars: error' file.ts
```

### 步骤 4：生成检查报告

格式：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Obsidian 插件代码检查报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

检查文件数：X 个
暂存的 TS/JS 文件：
  - file1.ts
  - file2.ts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 必须修复的问题（X 个）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] 禁止使用 innerHTML
📍 位置：src/main.ts:125
❌ 问题代码：
   element.innerHTML = '<div>content</div>';

✅ 修复建议：
   const div = element.createEl('div');
   div.textContent = 'content';

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟡 建议优化（X 个）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] 未使用的变量
📍 位置：src/utils.ts:45
⚠️  变量 'temp' 定义但未使用

✅ 建议：删除或重命名为 '_temp'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 检查通过
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ 没有直接创建 style 元素
✓ 没有正则表达式控制字符
✓ 没有导入 Node.js 模块

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 检查结果
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 必须修复：X 个
🟡 建议优化：X 个
✅ 通过检查：X 项

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 下一步
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[如果有必须修复的问题]
❌ 不建议现在提交！
请先修复上述必须修复的问题，然后重新检查。

修复后运行：
  git add .
  再次触发检查

[如果没有必须修复的问题]
✅ 可以安全提交！
所有必须修复的问题都已解决。

建议：
- 考虑修复可选优化问题
- 或者直接提交

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 步骤 5：决定是否继续提交

- 如果有 🔴 必须修复的问题：**停止提交**，提示用户先修复
- 如果只有 🟡 建议优化：**允许提交**，但提示可以优化
- 如果全部 ✅ 通过：**允许提交**

---

## 常见问题快速修复

### 问题 1：innerHTML/outerHTML

**错误：**
```typescript
element.innerHTML = `<div class="content">${text}</div>`;
```

**修复：**
```typescript
const div = element.createEl('div', { cls: 'content' });
div.textContent = text;
```

### 问题 2：创建 style 元素

**错误：**
```typescript
const style = document.createElement('style');
style.textContent = '.class { color: red; }';
document.head.appendChild(style);
```

**修复：**
1. 将 CSS 移到 `styles.css`
2. 删除 JavaScript 中的代码

### 问题 3：Node.js fs 模块

**错误：**
```typescript
import fs from 'fs';
const content = fs.readFileSync('file.txt', 'utf-8');
```

**修复：**
```typescript
const file = this.app.vault.getAbstractFileByPath('file.txt');
if (file instanceof TFile) {
  const content = await this.app.vault.read(file);
}
```

### 问题 4：async 没有 await

**错误：**
```typescript
async loadData() {
  return this.loadSettings();
}
```

**修复：**
```typescript
async loadData() {
  return await this.loadSettings();
}
// 或
loadData() {
  return this.loadSettings();
}
```

---

## 与 commit-conventional 集成

这个 Skill 应该在 `commit-conventional` Skill 之前执行。

建议工作流程：

1. 用户修改代码
2. 运行 `git add .`
3. 说："帮我提交代码"
4. **自动执行**：
   - 如果是 Obsidian 插件项目 → 先运行本 Skill 检查
   - 检查通过 → 继续运行 `commit-conventional` 创建提交
   - 检查不通过 → 停止，提示修复问题

---

## 项目识别

通过以下方式识别是否为 Obsidian 插件项目：

1. 检查 `manifest.json` 存在
2. 检查 `manifest.json` 包含 `id`, `name`, `version` 字段
3. 检查项目路径包含 "Obsidian" 或 "obsidian"

如果是 Obsidian 插件项目，自动启用此检查。

---

## Obsidian API 参考

### 常用替代方案

| ❌ 禁止 | ✅ 使用 Obsidian API |
|--------|---------------------|
| `innerHTML` | `element.createEl('div', { cls: 'class', text: 'content' })` |
| `createElement('style')` | 使用 `styles.css` 文件 |
| `fs.readFileSync()` | `await this.app.vault.read(file)` |
| `fs.writeFileSync()` | `await this.app.vault.modify(file, data)` |
| `fs.existsSync()` | `this.app.vault.getAbstractFileByPath(path)` |
| `path.join()` | 字符串拼接，Obsidian 处理路径 |

### 文档

- Obsidian API: https://docs.obsidian.md/
- Plugin 开发: https://docs.obsidian.md/Plugins/Getting+started/Build+a+plugin
- 提交规范: https://docs.obsidian.md/Plugins/Releasing/Submit+your+plugin

---

## 使用示例

### 示例 1：检查当前项目

```
帮我提交代码
```

如果是 Obsidian 插件项目，会自动执行检查。

### 示例 2：手动触发检查

```
检查 Obsidian 插件代码
```

或

```
/obsidian-pre-commit-check
```

### 示例 3：检查特定项目

```
/obsidian-pre-commit-check /Users/zhangyufan/Workspace/Projects/Obsidian-Plugins/O2Any
```

---

## 注意事项

1. **只检查暂存的文件**
   - 未暂存的修改不会被检查
   - 运行 `git add .` 后再检查

2. **快速反馈**
   - 检查应该在几秒内完成
   - 使用简单的文本搜索，不做完整的 AST 分析

3. **误报可能**
   - 正则表达式检查可能有误报
   - 提供人工确认选项

4. **与 ESLint 配合**
   - 如果项目有 ESLint，优先使用 ESLint
   - 本 Skill 作为补充检查

---

## 快速参考

```bash
# O2Any 项目路径
/Users/zhangyufan/Workspace/Projects/Obsidian-Plugins/O2Any

# 暂存文件
git add .

# 触发检查（通过提交触发）
# 说："帮我提交代码"

# 手动检查
# 说："检查 Obsidian 插件代码"
```
