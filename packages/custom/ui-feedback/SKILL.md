---
name: ui-feedback
disable-model-invocation: true
description: Use when buttons, actions, forms, or state transitions need clearer interaction feedback and tighter action hierarchy.
---

# UI Feedback

- 用户点下后必须立刻知道有没有生效。
- 需要补充说明时，优先用 hover / focus tooltip 或小浮层，不要把解释硬摊在版面上。
- 至少考虑：按下、处理中、成功、失败、不可点。
- 主按钮尽量唯一，次按钮数量受控。
- 同层重复、近义、同权重按钮要合并或删除。
- 不要只做 hover，不做点击后的真实反馈。
- 用户若用自然语言说明行为诉求，先保留用户视角的交互目标，再补状态设计。
- 需要状态矩阵时读 `references/state-matrix.md`
