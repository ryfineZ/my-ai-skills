# Skills 中央仓库改造遗留问题

> 状态：持续维护  
> 最后更新：2026-03-28

## OI-001 Claude Code 插件与 standalone skill 重复暴露

- 状态：已通过 `superpowers` 重装验收
- 影响范围：Claude Code、官方建议插件安装的 skill 包
- 现状：`superpowers` 已重装为顶层真实目录，Claude standalone 链接已被正确排除，插件建议文档已生成
- 风险：后续接入新的 Claude 插件推荐包时，仍需复用同样策略
- 建议：后续新包安装后继续用 `verify.sh` 和 `claude-plugin-recommendations.md` 做回归验证

## OI-002 旧版 `superpowers` 仍以历史发布形态存在

- 状态：已解决
- 影响范围：`superpowers` 全部 14 个 skill
- 现状：历史软链接已删除，`superpowers` 已通过新框架重装并写入 `.skill-source.json`
- 风险：无
- 建议：保持当前模式，后续只允许通过新框架更新

## OI-003 来源真相不唯一

- 状态：主体已收敛，待存量补录
- 影响范围：第三方 bundle skill 管理
- 现状：仓库级 `THIRD_PARTY_SKILLS.toml` 已移除，但部分历史 skill 仍缺少完整 `.skill-source.json`
- 风险：更新、平台过滤、来源展示仍可能在个别旧 skill 上不一致
- 建议：统一补录元数据，并用新框架重装关键 bundle

## OI-004 缺少 `update-skill`

- 状态：已实现，待继续增强
- 影响范围：所有第三方 skill
- 现状：已支持单 skill 更新、bundle 分组更新、缺失来源提示，以及 bundle 上游新增/删除识别；`--prune-missing` 已可显式清理本地残留
- 风险：更新结果汇总仍较轻量，缺少更完整的变更报告沉淀
- 建议：后续补强更新报告和更多边界场景回归

## OI-005 缺少 `uninstall-skill`

- 状态：已解决
- 影响范围：所有已安装 skill
- 现状：已新增 [`uninstall-skill`](/Users/zhangyufan/.agents/skills/uninstall-skill/SKILL.md)，支持按 skill / update_group 删除并自动刷新平台链接与列表
- 风险：无
- 建议：后续仅继续补充更多回归测试

## OI-006 缺少 `doctor-skills`

- 状态：已解决
- 影响范围：仓库维护和故障排查
- 现状：已新增 [`doctor-skills`](/Users/zhangyufan/.agents/skills/doctor-skills/SKILL.md)，可组合 `verify.sh` 与元数据检查，并支持轻量修复
- 风险：无
- 建议：后续按需补充更细粒度自动修复

## OI-007 历史 skill 的 `.skill-source.json` 覆盖不完整

- 状态：已解决
- 影响范围：历史社区安装 skill
- 现状：`clawfeed` 与 `deep-research` 已补录来源元数据；`tavily-search` 因来源不可确认且功能简单，已从中央仓库移除
- 风险：无
- 建议：后续若重新引入类似历史 skill，仍应先确认可靠来源再写入 `.skill-source.json`

## OI-011 `create-skill` 的本机校验器依赖外部 Python 包

- 状态：已解决
- 影响范围：新建 skill 的本地校验体验
- 现状：`quick_validate.py` 已支持在未安装 `PyYAML` 时回退到轻量 frontmatter 解析，不再因为环境缺包而直接失败
- 风险：回退解析器不做完整 YAML 语义验证，复杂 frontmatter 仍建议在有 `PyYAML` 的环境下复检
- 建议：保留当前降级策略，后续如需更严格校验再补充可选依赖说明

## OI-008 bundle 更新后的新增/删除策略尚未实装

- 状态：已部分实现
- 影响范围：bundle 类 skill 包
- 现状：`update-skill` 已能识别 bundle 上游新增/删除，并支持 `--prune-missing` 显式删除本地残留
- 风险：当前删除仍是显式模式，默认不会自动清理
- 建议：继续观察默认策略是否需要进一步自动化

## OI-009 Claude 插件推荐信息与自动安装需要统一

- 状态：已解决
- 影响范围：Claude Code 用户体验、插件推荐包安装流程
- 现状：Claude 插件信息已自动落地到 [`claude-plugin-recommendations.md`](/Users/zhangyufan/.agents/skills/docs/architecture/claude-plugin-recommendations.md)，并且全局安装时会在可用环境中自动执行插件市场添加与插件安装 / 启用
- 风险：若上游仓库文档中的插件市场或安装命令变化，自动提取逻辑需要继续回归验证
- 建议：后续新包接入时，同时验证元数据中的 `plugin_marketplace` / `plugin_marketplace_source`

## OI-010 README 与目标架构存在时间差

- 状态：已识别，需持续维护
- 影响范围：仓库使用者
- 现状：README 既要描述当前可运行状态，又要给出目标架构方向
- 风险：容易把“设计目标”误写成“当前已实现”
- 建议：明确区分“当前状态”和“目标架构”，避免文档失真
