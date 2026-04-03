---
name: ui-pencil
disable-model-invocation: true
description: Use when UI work benefits from live visual co-editing in Pencil so the user can see, review, and modify structure or layout directly on a .pen canvas.
---

# UI Pencil

Pencil 用于可视化共改，不替代真实实现预览。

## Use When

- 需要先定结构和视觉方向，再写代码
- 用户希望直接看到你的设计过程
- 用户想在画布里一起改布局、组件和层级

## Workflow

1. `get_editor_state` 确认当前 `.pen` 文档和画布
2. `batch_get` 读现有节点
3. `batch_design` 做结构化修改
4. `get_screenshot` 及时复查
5. 定稿后再回到代码实现或浏览器预览

## Notes

- Pencil 的布局和字体语义与浏览器 CSS 不完全相同，不能直接等同。
- Pencil 负责设计过程可视化，浏览器负责最终实现验证。
- 当前环境已验证可连接、可读、可写、可截图。
- 工作流细节：`references/pencil-workflow.md`
- 使用红线：`references/pencil-rules.md`
