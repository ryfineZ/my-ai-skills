---
name: skill-security-guard
description: 对本地或 GitHub 上的 AI skill 执行安装前安全审计，检测提示词劫持、下载执行、凭证窃取、数据外传、持久化与提权风险，并输出可拦截的风险结论（SAFE/CAUTION/REVIEW/BLOCK）。当用户提到“skill 安全检测”“安装前审计”“scan skill security”“恶意 skill”“prompt injection 检查”时使用。
argument-hint: "[local|github] <path-or-owner/repo>"
disable-model-invocation: false

compatibility:
  claude-code: full
  codex: full
  gemini: basic
---

# Skill Security Guard

## 执行目标

对 skill 包进行两阶段审计：
1. 远程预审（GitHub 仓库）
2. 本地深扫（已下载或已安装 skill 目录）

优先给出可执行结论：
- `SAFE`: 未发现风险
- `CAUTION`: 仅低/中风险，建议人工复核
- `REVIEW`: 存在高风险，需要人工确认
- `BLOCK`: 存在严重风险，建议阻断安装/入库

## 工作流

### 1) 识别审计模式

- 用户给的是仓库 URL / `owner/repo`：先用 `github` 模式
- 用户给的是本地路径：用 `local` 模式
- 中央仓库入库前：先 `github`，再 `local`

### 2) 运行扫描脚本

使用内置脚本：

```bash
python3 "$HOME/.agents/skills/skill-security-guard/scripts/skill_security_guard.py" local --path /path/to/skill
```

```bash
python3 "$HOME/.agents/skills/skill-security-guard/scripts/skill_security_guard.py" github --repo owner/repo
```

常用参数：

```bash
# 仅输出高风险以上
python3 "$HOME/.agents/skills/skill-security-guard/scripts/skill_security_guard.py" \
  --min-severity high local --path /path/to/skill

# JSON 输出（用于 CI / 中央仓库闸门）
python3 "$HOME/.agents/skills/skill-security-guard/scripts/skill_security_guard.py" github \
  --repo owner/repo --json
```

### 3) 解释结果并给处置建议

按以下格式汇报：

```text
## Skill 安全审计结论
- Target: <path-or-repo>
- Files Scanned: <N>
- Summary: CRITICAL=<N> HIGH=<N> MEDIUM=<N> LOW=<N>
- Verdict: <SAFE/CAUTION/REVIEW/BLOCK>

## 关键风险
- [SEVERITY] <rule_id> @ <file:line>
  - 风险说明
  - 建议动作（删除、隔离、人工复核、凭证轮转等）
```

### 4) 中央仓库闸门策略

- `CRITICAL >= 1`：`BLOCK`（阻断安装/入库）
- `HIGH >= 1`：`REVIEW`（必须人工审批）
- 仅 `MEDIUM/LOW`：`CAUTION`（允许但保留审计记录）
- 无发现：`SAFE`

## 检测覆盖（内置规则）

- Prompt Injection / 指令覆盖
- Download-and-Execute（`curl|bash` / `wget|sh` / `IEX`）
- Credential Access（SSH/AWS/.env/Keychain 等）
- Data Exfiltration Chain（敏感读取 + 网络发送）
- Supply Chain Hook（`postinstall`、`setup.py cmdclass`）
- Persistence（crontab、launchd、shell profile 写入）
- Privilege Escalation（`sudo`、`chmod +s`、`setuid`）
- Obfuscation（长 Base64、高熵、隐藏 Unicode）

## 参考策略

需要更细粒度解释时，读取：
- `references/detection-policy.md`
