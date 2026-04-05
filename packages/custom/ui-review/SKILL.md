---
name: ui-review
disable-model-invocation: true
description: Use before claiming a UI is done, polished, or good-looking to run the ui-polish blocking checks, lightweight validation, and final visual review.
---

# UI Review

先查规则，再查运行时，最后才少量看图。没有过审，不要说“已经好看了”。

## Default Review Order

1. 跑 `python3 ../ui-assets/scripts/check_ui_rules.py <path>`
2. 有本地页面或 URL 时，跑 `python3 ../ui-assets/scripts/inspect_runtime.py --file <html>` 或 `--url <url>`
3. 若第 2 步提示 `visual-review`，必须先跑 `../ui-polish/scripts/capture_ui.py` 或 Pencil 看图
4. 视觉复审完成后，再用 `python3 ../ui-assets/scripts/inspect_runtime.py --file <html> --visual-reviewed` 或 `--url <url> --visual-reviewed` 复跑

## Blocking

- 默认安全配色
- 冗余标题或重复块
- 低对比度、发灰、发虚
- 无意义外框、内框、容器套娃
- 该有补充说明的交互入口没有 hover / focus 浮层或等效提示
- 悬浮层太厚、太大、文字太多，体量压过触发源
- 按钮点下后无明确反馈
- 高频交互明显掉帧、拖影、卡顿，或实现方式存在明显每帧重算问题
- 同层按钮重复且同权重
- 明显模板味
- 玻璃/材质/图表等高视觉风险场景没有完成强制视觉复审

详细流程：`references/review-workflow.md`
详细阻断项：`references/blocking-checks.md`
