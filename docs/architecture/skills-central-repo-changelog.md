# Skills 中央仓库改造更新记录

> 状态：持续维护  
> 最后更新：2026-03-29

## 2026-03-29

### 已完成

1. 收紧全局规则，明确安装 / 更新 / 卸载 skill 的默认目标始终是中央仓库 `~/.agents/skills`，只有用户显式要求时才允许项目级安装。
2. 收紧全局规则，明确对 Claude 官方建议插件安装的包，流程终点必须是实际完成插件安装 / 启用，而不是仅输出提示。
3. 扩展 `install-skill` 的 Claude 插件策略检测：
   - 从上游仓库文档中提取 `/plugin marketplace add ...`
   - 提取 `/plugin install ...`
   - 回填 `plugin_marketplace` 与 `plugin_marketplace_source`
4. 改造 `install-skill` 的单 skill / bundle 安装流程，使全局安装在可用 Claude 环境中自动完成插件市场添加与插件安装 / 启用。
5. 修正 `superpowers` 的 Claude 插件元数据来源，统一改为 `superpowers-marketplace`，不再错误指向 `claude-plugins-official`。
6. 联动更新 `README`、`SETUP-SUMMARY`、`install-skill/SKILL.md`、设计文档和 schema，明确“中央仓库安装 + Claude 插件自动安装”的新约定。

## 2026-03-28

### 已完成

1. 识别并确认 [`commandcode-skills`](/Users/zhangyufan/.agents/skills/commandcode-skills) 与 `superpowers` 存在大面积能力重叠。
2. 移除 [`commandcode-skills`](/Users/zhangyufan/.agents/skills/commandcode-skills) 及其重复 skill 暴露。
3. 接入 `superpowers`，并确认 Codex 当前可用的 `superpowers` skill 集合。
4. 修复中央仓库脚本对 nested skill 的发现、列表更新和验证逻辑。
5. 将 `superpowers` 发布逻辑改为“跟随上游仓库内容”，不再使用本地 `enabled` 白名单。
6. 删除 [`humanizer`](/Users/zhangyufan/.agents/skills/humanizer) 并清理各平台残留链接。
7. 明确中央仓库改造方向：
   - 统一来源真相到 `.skill-source.json`
   - 安装即扁平化
   - 平台差异化发布
   - Claude Code 对插件推荐包执行排除
8. 正式建立架构文档体系：
   - 需求
   - 设计
   - 遗留问题
   - 更新记录
9. 新增 [`.skill-source.json` schema 文档](/Users/zhangyufan/.agents/skills/docs/architecture/skill-source-schema.md)。
10. 扩展 `install-skill` 的元数据写入逻辑，为后续统一来源真相打基础。
11. 更新 `set_skill_meta.py`，使 AI 后处理元数据继续兼容旧字段并补默认新字段。
12. 扩展 `install-skill`，新增 bundle 安装模式：
   - `--all-skills`
   - `--bundle-root`
13. 在平台发布脚本中加入 Claude Code 的基础过滤逻辑，开始识别 `platform_policies.claude_code.publish=false`。
14. 新增 [`update-skill`](/Users/zhangyufan/.agents/skills/update-skill/SKILL.md) 的第一版可用入口，支持：
   - 列出可更新 skill
   - 单 skill 更新
   - 按 `update_group` 更新
   - 全量更新入口
15. 移除仓库级 [`THIRD_PARTY_SKILLS.toml`](/Users/zhangyufan/.agents/skills/THIRD_PARTY_SKILLS.toml) 与 [`publish-third-party-skills.sh`](/Users/zhangyufan/.agents/skills/shared/scripts/publish-third-party-skills.sh) 依赖。
16. 重构 [`update-skills-list.sh`](/Users/zhangyufan/.agents/skills/shared/scripts/update-skills-list.sh)，来源展示改为优先读取每个 skill 自带的 `.skill-source.json`。
17. 新增 [`generate-claude-plugin-recommendations.sh`](/Users/zhangyufan/.agents/skills/shared/scripts/generate-claude-plugin-recommendations.sh)，开始生成 Claude Code 插件安装建议文档。
18. 更新 `README`、`SETUP-SUMMARY` 与 `setup-universal-skills.sh`，将仓库说明切换到“安装即扁平化 + 元数据驱动发布”的新模型。
19. 修复 [`install.sh`](/Users/zhangyufan/.agents/skills/shared/scripts/install.sh) 的平台清理逻辑，使 Claude 被排除发布的 skill 不会残留旧链接。
20. 修复 [`install-skill.sh`](/Users/zhangyufan/.agents/skills/install-skill/install-skill.sh) 的 GitHub 仓库地址归一化，远程安全预审支持完整 GitHub URL。
21. 收窄 [`skill_security_guard.py`](/Users/zhangyufan/.agents/skills/skill-security-guard/scripts/skill_security_guard.py) 中对 `exec(` 的误报规则，避免将 `regex.exec(...)` 误判为动态执行。
22. 为 `install-skill` 的 GitHub 远程预审增加一次瞬时网络错误重试。
23. 删除历史 `superpowers` 顶层软链接和旧来源目录，并使用新框架重新安装 `superpowers` 全部 14 个 skill。
24. 修复 [`verify.sh`](/Users/zhangyufan/.agents/skills/shared/scripts/verify.sh) 的平台假设，使其按 `.skill-source.json.platform_policies` 判断是否应该存在平台链接。
25. 补齐 [`gh-address-comments/.skill-source.json`](/Users/zhangyufan/.agents/skills/gh-address-comments/.skill-source.json)，使其重新进入可更新集合。
26. 新增 [`uninstall-skill`](/Users/zhangyufan/.agents/skills/uninstall-skill/SKILL.md)，支持按 skill 或 `update_group` 删除并自动刷新平台发布与列表。
27. 新增 [`doctor-skills`](/Users/zhangyufan/.agents/skills/doctor-skills/SKILL.md)，支持组合 `verify.sh` 与元数据健康检查，并提供轻量修复入口。
28. 新增 [`normalize-skill-source-metadata.py`](/Users/zhangyufan/.agents/skills/shared/scripts/normalize-skill-source-metadata.py)，对历史元数据执行一次安全字段标准化。
29. 增强 [`update-skill.sh`](/Users/zhangyufan/.agents/skills/update-skill/update-skill.sh)，支持识别 bundle 上游新增/删除，并提供 `--prune-missing` 显式清理。
30. 为 `clawfeed` 与 `deep-research` 补录 `.skill-source.json`，将历史缺口收敛到 `tavily-search` 单项。
31. 修复 [`quick_validate.py`](/Users/zhangyufan/.agents/skills/create-skill/scripts/quick_validate.py) 对 `PyYAML` 的硬依赖，未安装时回退到轻量 frontmatter 解析。
32. 修正 [`update-skills-list.sh`](/Users/zhangyufan/.agents/skills/shared/scripts/update-skills-list.sh) 的启发式用途识别，使 `doctor-skills`、`uninstall-skill`、`update-skill`、`deep-research`、`tavily-search` 的文档描述更贴近真实职责。
33. 清理 [`.skillsrc`](/Users/zhangyufan/.agents/skills/.skillsrc) 中已失效的第三方源码缓存目录配置，避免与新架构冲突。
34. 使用 [`uninstall-skill`](/Users/zhangyufan/.agents/skills/uninstall-skill/SKILL.md) 删除 `tavily-search`，并同步清理所有平台链接与 `INSTALLED_SKILLS.md`，使仓库体检重新回到 `0 warning`。

### 已确认的设计决策

1. 不再为了“客户端可能不支持 bundle”而扁平化；扁平化是为了统一管理模型。
2. 中央仓库改造后不长期保留第三方源码缓存目录。
3. `superpowers` 这类 bundle 应通过新框架重新安装，不做旧数据原位迁移。
4. Claude Code 不能同时吃官方插件版和中央仓库 standalone 版同能力 skill。
5. 对官方明确建议插件安装的 skill 包，中央仓库应对 Claude 执行排除发布并给出提示。
6. 基础能力层最终收敛为 `install-skill`、`update-skill`、`uninstall-skill`、`doctor-skills`，共同支撑中央仓库的安装、更新、卸载与诊断闭环。

### 当前尚未完成

1. `update-skill` 已支持 `--prune-missing`，但更新结果报告还可以继续增强。
2. 远程安全预审已增加 URL 归一化与重试，但长期稳定性还需要继续观察。
