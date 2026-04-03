---
name: using-ui-polish
disable-model-invocation: true
description: Use when a task is changing how an interface looks, feels, or is interacted with and you need ui-polish to route core rules, platform guidance, visual collaboration, and final review.
---

# Using UI Polish

这是 `ui-polish` 的运行入口。新 UI 任务默认先跑 `../ui-assets/scripts/ui_workflow.py`，先拿起手包，再动手。

## Route In Order

1. 新 UI 任务优先跑 `../ui-assets/scripts/ui_workflow.py`
2. 先读 `../ui-core/SKILL.md`
3. 先定四件事：平台、界面类型、主任务、视觉方向
   - 不知道怎么定时，读 `../ui-assets/references/platform-briefs.md`
   - 视觉方向优先用 `../ui-assets/references/style-presets.md` 里的 preset 名
   - 用户若直接用自然语言描述交互，先让 `ui_workflow.py` 自动提取；交互预设读 `../ui-assets/references/interaction-presets.md`
   - 一个请求可同时命中多个交互预设，比如 `hover-explain` + `click-feedback`
4. 只选一个平台 skill：`../ui-web/SKILL.md` / `../ui-mobile/SKILL.md` / `../ui-mini/SKILL.md` / `../ui-ext/SKILL.md` / `../ui-desktop/SKILL.md`
5. 需要文案或按钮状态细化时，再补 `../ui-copy/SKILL.md` / `../ui-feedback/SKILL.md`
6. 需要结构先行或用户共改时，再读 `../ui-pencil/SKILL.md`
7. 只有方向不清或要查单点资料时，才桥接 `ui-ux-pro-max`
   - 先跑 `../ui-assets/scripts/route_ui_task.py`
   - 或直接跑 `../ui-assets/scripts/ui_workflow.py`
   - 再按需跑 `../ui-assets/scripts/query_ui_reference.py`
8. 输出前必须读 `../ui-review/SKILL.md`

## With Other Skills

- `superpowers` 继续负责 brainstorming / planning / execution / verification。
- `frontend-design` 可用于生成，但最后仍由 `ui-polish` 裁决。
- `web-design-guidelines` 和 `vercel-react-best-practices` 只作为补充。
- 详细协作关系：读 `../ui-assets/references/bridge-skills.md`

## Bridge Rules

- `ui-polish` 先调用，`ui-ux-pro-max` 后调用。
- `ui-ux-pro-max` 只负责补资料，不负责拍板。
- 若 `ui-ux-pro-max` 与 `ui-core` 或 `ui-review` 冲突，永远服从 `ui-polish`。
- 用户已经说出“按住拖动”“像手机图标一样换位”这类自然语言需求时，不要逼他再补工程术语。
- 详细桥接流程：读 `../ui-assets/references/controlled-bridge.md`
