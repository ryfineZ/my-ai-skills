---
name: commit-conventional
description: 执行 git commit 创建符合约定式提交规范的提交。仅当用户明确要求"提交代码"、"创建提交"、"帮我commit"、"git commit"等执行提交操作时使用。不要在仅仅讨论提交、询问提交规范、或解释如何提交时触发
argument-hint: [额外上下文]
disable-model-invocation: false

# 兼容性标记（所有工具会忽略未知字段）
compatibility:
  claude-code: full      # 完整功能
  codex: basic          # 基础功能（无 Hooks）
  gemini: basic         # 基础功能（无 Hooks）
  github-copilot: basic # 基础功能

# Claude Code 专属特性（其他工具会自动忽略）
# allowed-tools: Read, Grep, Bash
# model: sonnet
---

# 约定式提交 (Conventional Commits) Skill

创建符合规范的 Git 提交，遵循用户的编码规范。

## 提交格式

```
<type>(<scope>): <description>

[可选的正文]

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 提交类型 (type)

- **feat**: 新功能
- **fix**: 修复 bug
- **docs**: 文档变更
- **refactor**: 重构（既不是新功能也不是修复）
- **test**: 测试相关
- **chore**: 构建工具、辅助工具、依赖等
- **perf**: 性能优化

## 执行步骤

### 0. 代码质量检查（预处理）

**在开始提交流程前，自动执行代码质量检查：**

```bash
# 运行通用代码质量检查脚本（会自动识别项目类型）
bash ~/.claude/skills/code-quality-check/scripts/check.sh
```

**检查逻辑：**
- 脚本会**自动检测项目类型**（Obsidian、React、Vue、Electron 等）
- 根据项目类型应用对应的检查规则：
  - **通用规则**：所有项目都执行（硬编码敏感信息、正则控制字符等）
  - **前端规则**：前端项目执行（innerHTML、console.log 等）
  - **平台特定规则**：特定平台执行（Obsidian 的 style 元素、Node.js 模块等）

**检查结果处理：**
- **退出码 0**：检查通过，继续提交流程
- **退出码 1**：检查失败，**停止提交**，提示用户先修复问题

**重要**：
- 如果代码检查失败，**不要继续执行后续步骤**
- 向用户说明发现的具体问题和修复建议
- 用户修复问题并重新 `git add` 后，可以再次触发提交

### 1. 查看变更
并行运行以下命令了解代码变更：
- `git status` - 查看所有未跟踪和已修改文件
- `git diff --staged` - 查看暂存区的具体变更
- `git log --oneline -5` - 查看最近的提交记录，学习项目的提交风格

### 2. 分析变更
- 确定变更的**本质类型**（feat/fix/refactor 等）
- 识别变更的**作用域** (scope)：影响的模块、组件或功能区域
- 理解变更的**目的**（为什么做这个改动）

### 3. 生成提交信息
- **描述要求**：
  - 用简洁的中文描述
  - 长度控制在 50 字以内
  - 重点说明"为什么"而不是"是什么"
  - 使用祈使语气（如"添加"而不是"添加了"）

- **示例**：
  - ✅ `feat(auth): 添加 JWT 认证支持`
  - ✅ `fix(api): 修复用户登录时的空指针异常`
  - ✅ `refactor(utils): 优化日期格式化函数性能`
  - ❌ `update code` (太模糊)
  - ❌ `修改了登录功能的一些代码` (不够精确)

### 4. 暂存文件（如果需要）
- 如果有未暂存的相关文件，使用 `git add <文件路径>` 添加
- **优先按文件名添加**，避免使用 `git add .` 或 `git add -A`
- **安全检查**：确保不会添加敏感文件（.env, credentials, API keys 等）

### 5. 创建提交
使用 HEREDOC 格式创建提交，确保格式正确：

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 6. 验证提交
运行 `git status` 确认提交成功。

## 安全规则

⚠️ **禁止提交的文件类型**：
- `.env` 文件
- `credentials.json` 或包含 `secret`/`password` 的文件
- `node_modules/` 或其他依赖目录
- 大型二进制文件（除非明确需要）

如果用户明确要求提交这些文件，**必须警告风险**并请求确认。

## 额外上下文

参数 `$ARGUMENTS` 可用于提供额外的提交上下文或说明。

## 注意事项

- **不要推送到远程**：除非用户明确要求 `git push`
- **不要使用破坏性操作**：不使用 `--amend`、`--force`、`reset --hard` 等（除非明确要求）
- **遵循项目风格**：参考 `git log` 中的历史提交，保持一致性
- **处理钩子失败**：如果 pre-commit 钩子失败，修复问题后创建**新提交**，不要使用 `--amend`

---

## 🔧 高级功能（仅部分工具支持）

> **兼容性说明**：
> - ✅ **Claude Code**：支持所有高级功能
> - ⚠️ **Codex/Gemini/Copilot**：仅支持基础功能，会自动忽略高级特性

### Pre-commit 验证（仅 Claude Code）

如果你使用的是 Claude Code，可以添加 Hooks 进行自动验证：

**在 frontmatter 中添加**（已注释，需要时取消注释）：
```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-commit.sh"
```

**验证脚本示例** (`scripts/validate-commit.sh`)：
```bash
#!/bin/bash
# 检测提交信息是否符合规范
COMMIT_MSG=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 检查是否包含敏感文件
if echo "$COMMIT_MSG" | grep -iE '\.(env|secret|key|pem)' > /dev/null; then
  echo "❌ 警告：可能包含敏感文件" >&2
  exit 2
fi

exit 0
```

### 工具限制（仅 Claude Code）

在 frontmatter 中取消注释以启用：
```yaml
allowed-tools: Read, Grep, Bash  # 限制只能使用这些工具
```

---

## 🔌 集成的 Skills

### 通用代码质量检查

本 Skill 已集成 `code-quality-check`，在提交代码前自动执行质量检查。

**工作流程**：
1. 用户说："帮我提交代码"
2. 自动检测项目类型（Obsidian、React、Vue、Electron 等）
3. 根据项目类型执行对应的检查规则
4. **检查失败**：停止提交，显示问题和修复建议
5. **检查通过**：继续正常的提交流程

**支持的项目类型**：
- **Obsidian 插件**：通用规则 + 前端规则 + Obsidian 特定规则
- **浏览器扩展**：通用规则 + 前端规则 + 浏览器扩展规则
- **Electron 应用**：通用规则 + 前端规则
- **React/Vue/Angular**：通用规则 + 前端规则
- **通用项目**：仅通用规则

**检查规则示例**：
- ✅ **通用规则**（所有项目）：
  - 硬编码的敏感信息（API key、password）
  - 正则表达式控制字符
  - 未使用的变量（ESLint）

- ✅ **前端规则**（前端项目）：
  - innerHTML/outerHTML 使用（XSS 风险）
  - dangerouslySetInnerHTML 使用（React）
  - console.log 残留

- ✅ **Obsidian 规则**（Obsidian 插件）：
  - 禁止直接创建 style 元素
  - 禁止导入 Node.js 模块（fs, path）

**用户体验**：
- 🎯 智能识别：自动检测项目类型，无需手动配置
- ⚡ 快速反馈：检查在几秒内完成
- 💡 清晰提示：发现问题时给出具体修复建议
- 🔧 模块化设计：易于扩展新的平台规则

