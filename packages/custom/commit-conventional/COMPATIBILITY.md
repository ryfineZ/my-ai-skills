# 兼容性说明

本 Skill 遵循 Agent Skills 标准，支持多个 AI 编码工具。

## 支持的工具

| 工具 | 兼容级别 | 说明 |
|------|---------|------|
| **Claude Code CLI** | ✅ 完整 | 支持所有功能，包括 Hooks |
| **Codex CLI** | ⚠️ 基础 | 支持核心功能，忽略 Hooks |
| **Gemini CLI** | ⚠️ 基础 | 支持核心功能，忽略 Hooks |
| **GitHub Copilot** | ⚠️ 基础 | 支持核心功能 |
| **VS Code 插件** | ⚠️ 基础 | 取决于插件实现 |

## 功能对照表

| 功能 | Claude Code | Codex | Gemini | 说明 |
|------|-------------|-------|--------|------|
| 基础提交流程 | ✅ | ✅ | ✅ | 所有工具都支持 |
| 约定式提交格式 | ✅ | ✅ | ✅ | 所有工具都支持 |
| 安全检查（手动） | ✅ | ✅ | ✅ | 通过指令实现 |
| Hooks 自动验证 | ✅ | ❌ | ❌ | 仅 Claude Code |
| allowed-tools 限制 | ✅ | ❌ | ❌ | 仅 Claude Code |
| context: fork | ✅ | ❌ | ❌ | 仅 Claude Code |

## 降级策略

### 在 Claude Code 中
- 使用完整功能
- 可以启用 Hooks 进行自动验证
- 可以设置工具限制

### 在 Codex/Gemini 中
- 使用核心提交流程
- 依赖 AI 判断进行安全检查
- Frontmatter 中的高级字段会被自动忽略

## 启用高级功能（仅 Claude Code）

如果你确认使用的是 Claude Code，可以在 frontmatter 中取消注释：

```yaml
---
name: commit-conventional
description: ...

# 取消注释以启用高级功能
allowed-tools: Read, Grep, Bash
model: sonnet

# 添加 Hooks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-commit.sh"
---
```

## 测试兼容性

运行以下命令测试 Skill 是否正常工作：

```bash
# 在各个 CLI 中测试
claude "列出可用的 skills"
codex "列出可用的 skills"
gemini "列出可用的 skills"

# 手动调用测试
/commit-conventional
```

## 最佳实践

1. **保持核心功能通用**：确保基础流程在所有工具中都能工作
2. **高级功能可选**：将 Claude 特有功能作为增强，而非必需
3. **清晰标注**：在文档中说明哪些功能是工具特定的
4. **优雅降级**：不支持的功能应该静默忽略，不影响基础使用
