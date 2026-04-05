---
name: agent-rules-sync
description: 统一多平台全局规则管理（AGENTS/CLAUDE/GEMINI）。触发语义包含“新增一条全局规则”“新增全局规则”“把这句话写入全局规则”等明确写入指令；用于新增/修改规则并同步到 Claude/Codex/Gemini/Antigravity。若是讨论性提问（如“要不要写入全局规则？”）则不触发。
---

# Agent Rules Sync

## Scope
本技能仅用于**同步/生成/链接**多平台全局规则文件，不处理一次性初始化工作。

## When to use
- 用户请求新增/修改全局规则并同步到多平台
- 用户要求重新生成各平台规则文件
- 修复或重建全局规则文件的软链接

## Trigger Examples
**触发示例：**
- “新增一条全局规则：每天先检查 git status”
- “新增全局规则：回复尽量简短”
- “把这句话写入全局规则：禁止提交敏感信息”

**不触发（讨论性）：**
- “要不要把这条规则写入全局规则？”
- “我需要把这条规则写入全局规则吗？”

## Rules Hub
- 位置: `~/Workspace/agent-rules`
- 通用规则: `AGENTS.md`
- 平台覆写:
  - `agents/claude.md`
  - `agents/codex.md`
  - `agents/gemini.md`
  - `agents/antigravity.md`
- 生成产物:
  - `generated/CLAUDE.md`
  - `generated/AGENTS.md`
  - `generated/GEMINI.md`

## Workflow
1. 更新通用规则或平台覆写文件（按用户要求）
2. 运行 `~/Workspace/agent-rules/scripts/sync.sh` 生成各平台规则文件
3. 运行 `~/Workspace/agent-rules/scripts/link.sh` 修复/创建软链接
4. 可选：运行 `agent-rules-sync/scripts/verify.sh` 验证当前状态

## Compatibility Rules
- 通用规则中避免出现平台专用工具名或文件名
- 平台差异写入对应覆写文件
- Gemini 与 Antigravity 共用 `~/.gemini/GEMINI.md`

## Notes
- `link.sh` 会为原文件创建带时间戳的 `.bak` 备份
