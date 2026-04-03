# Skills 重叠审计

> 状态：当前结论
> 最后更新：2026-04-03

本文档只记录当前中央仓库中已经确认的 skill 重叠情况，以及后续处理建议。

## 结论摘要

当前 skill 体系中，真正值得关注的重叠主要有三类：

1. 高度重叠，后续可考虑收敛
2. 部分重叠，但定位不同
3. 名字相近，但实际上属于正常分层

---

## 一、高度重叠

### 1. `de-ai-zh-optimized` / `de-ai-zh-stable`

- 重叠点：
  - 都用于中文去 AI 痕迹改写
  - 输入输出形态相同
  - 底层脚本一致，只是 variant 不同
- 差异点：
  - `optimized` 更激进，允许更强的结构重排和收口
  - `stable` 更保守，尽量保留已验证方法
- 处理建议：
  - 短期保留
  - 认知上视为同一能力的两个档位
  - 默认优先使用 `de-ai-zh-optimized`
  - 后续若要精简，优先从这组开始

### 2. `gh-address-comments` / `github:gh-address-comments`

- 重叠点：
  - 都用于处理 GitHub PR review comments
- 差异点：
  - 中央仓库里的 `gh-address-comments` 更轻量，主要依赖 `gh`
  - GitHub plugin 提供的 `github:gh-address-comments` 能处理更完整的 PR / thread 上下文
- 处理建议：
  - 在 Codex 中优先使用 `github:gh-address-comments`
  - 中央仓库里的同名 skill 暂时保留，用于非 plugin 场景
  - 后续如果确认中央仓库版本长期没有使用价值，可考虑移除

### 3. `create-skill` / 系统 `skill-creator`

- 重叠点：
  - 都与 skill 创建有关
- 差异点：
  - `create-skill` 绑定中央仓库架构、校验、打包、导出流程
  - 系统 `skill-creator` 是通用版能力
- 处理建议：
  - 保留
  - 在当前中央仓库体系中，继续只把 `create-skill` 作为唯一权威入口

### 4. `install-skill` / 系统 `skill-installer`

- 重叠点：
  - 都用于安装 skill
- 差异点：
  - `install-skill` 负责中央仓库安装、安全审计、元数据写回、平台策略收敛
  - 系统 `skill-installer` 只覆盖通用安装流程
- 处理建议：
  - 保留
  - 在当前中央仓库体系中，继续只把 `install-skill` 作为唯一权威入口

---

## 二、部分重叠，但定位不同

### 1. `planning-with-files` / `writing-plans` / `executing-plans`

- 重叠点：
  - 都涉及复杂任务的计划与推进
- 差异点：
  - `planning-with-files` 偏外置工作记忆、跨会话恢复、研究型任务管理
  - `writing-plans` 偏把 spec 写成实现计划
  - `executing-plans` 偏按既有计划执行
- 处理建议：
  - 保留
  - 在文档和使用心智中明确边界：
    - 长任务、研究、跨会话恢复：`planning-with-files`
    - 明确开发计划与执行：`writing-plans` / `executing-plans`

### 2. `ui-polish` / `frontend-design` / `ui-ux-pro-max`

- 重叠点：
  - 都能影响 UI 设计与前端界面实现
- 差异点：
  - `ui-polish` 是主流程和审美闸门
  - `frontend-design` 偏创意实现
  - `ui-ux-pro-max` 偏大型 UI/UX 参考库
- 处理建议：
  - 保留
  - 默认由 `ui-polish` 统一路由
  - `frontend-design` 和 `ui-ux-pro-max` 只按需桥接

### 3. `create-skill` / `writing-skills`

- 重叠点：
  - 都与“做 skill”有关
- 差异点：
  - `create-skill` 偏中央仓库落地流程
  - `writing-skills` 偏 skill 设计与验证方法论
- 处理建议：
  - 保留
  - 继续把 `create-skill` 作为实际创建入口
  - 把 `writing-skills` 视为方法论补充，而不是主入口

### 4. `agent-browser` / `chrome-cdp`

- 重叠点：
  - 都能操作浏览器
- 差异点：
  - `agent-browser` 是通用浏览器自动化
  - `chrome-cdp` 是接管本机已打开的 Chrome 会话
- 处理建议：
  - 保留
  - 默认网页自动化走 `agent-browser`
  - 只有用户明确要接管当前本机 Chrome 页面时才走 `chrome-cdp`

---

## 三、看起来相近，但不算重复

### 1. `using-superpowers`

- 说明：
  - 它是 `superpowers` 的总入口与总纪律
  - 不等于计划执行器
- 结论：
  - 不应把它视为 `planning-with-files` 的重复项

### 2. `doctor-skills`

- 说明：
  - 它负责中央仓库体检与轻量修复编排
  - 不替代安装、更新、卸载
- 结论：
  - 不算重复

### 3. `using-ui-polish` / `ui-web` / `ui-review`

- 说明：
  - 这组是路由层、平台层、复审层拆分
- 结论：
  - 属于正常分层，不算重复

---

## 四、平台专用 skill 的实现结论

当前中央仓库已经支持平台专用 skill，不需要为每个平台单独再做一套架构。

当前做法是：

1. 在 `.skill-source.json` 中写入 `platform_policies`
2. 安装和导出时按平台策略决定是否发布到对应客户端入口目录
3. 验证脚本按同样策略判断是否应存在平台链接

例如 `CTF-Sandbox-Orchestrator` 当前就是：

- `codex.publish = true`
- `claude_code.publish = false`
- `claude_code.install = "disabled"`

这意味着它是 Codex 专用 skill，当前实现符合预期。

---

## 五、当前建议优先级

如果后续只做最有价值的收敛，建议顺序如下：

1. 补清 `planning-with-files` 与 `writing-plans` / `executing-plans` 的边界说明
2. 将 `de-ai-zh-optimized` / `de-ai-zh-stable` 明确为默认档与保守档
3. 在 Codex 场景中明确 `github:gh-address-comments` 优先于中央仓库旧版
