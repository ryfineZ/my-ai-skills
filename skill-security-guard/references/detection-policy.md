# Skill Security Guard 检测策略

## 1. 风险级别定义

- `CRITICAL`: 直接可利用的高危模式（如下载执行、凭证窃取）
- `HIGH`: 明显危险行为（如持久化、提权、敏感数据外传链）
- `MEDIUM`: 可疑模式（如外部网络访问、混淆痕迹、广权限）
- `LOW`: 信息性提醒（当前版本较少使用）

## 2. 默认闸门规则

- `CRITICAL >= 1`：`BLOCK`（阻断）
- `HIGH >= 1`：`REVIEW`（人工审批）
- 仅 `MEDIUM/LOW`：`CAUTION`（允许但记录）
- 无发现：`SAFE`

## 3. 主要检测族

- Prompt Injection
- Download and Execute
- Credential Access
- Data Exfiltration Chain
- Supply Chain Hook
- Persistence
- Privilege Escalation
- Obfuscation / Hidden Unicode

## 4. 误报处理建议

对 `MEDIUM` 或上下文不明确的告警，按以下顺序复核：

1. 该行为是否与 skill 声称功能一致
2. 是否具备最小权限、最小数据访问范围
3. 是否存在可追溯日志与用户可见提示
4. 是否可改为固定版本、哈希校验、白名单域名

## 5. 输出落库建议

中央仓库建议保存 JSON 报告字段：

- `target`
- `files_scanned`
- `severity_counts`
- `verdict`
- `findings[]`（rule_id / file / line / detail / recommendation）

