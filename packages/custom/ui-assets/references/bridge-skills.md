# Bridge Skills

## With Superpowers

- `superpowers` 负责流程。
- `ui-polish` 负责 UI 领域判断。
- 进入 UI 任务后，流程可以继续沿用 `superpowers`，但审美和审查规则服从 `ui-polish`。

## With Existing UI Skills

- `frontend-design`
  - 用于生成阶段
  - 不拥有最终审美判断权

- `web-design-guidelines`
  - 用于补充审查
  - 由 `ui-review` 阶段按需补充

- `vercel-react-best-practices`
  - 只在 React / Next 场景补充性能和实现习惯

## With ui-ux-pro-max

调用顺序：

1. `ui-polish`
2. `ui-core`
3. 平台 skill
4. 按需 `ui-ux-pro-max`
5. 回到 `ui-review`

只在这些场景调用 `ui-ux-pro-max`：

- 风格方向还不清楚
- 要查某个单点维度，如 typography / palette / product type
- 要查栈相关建议

不要在这些场景调用：

- 用户已经给了明确风格禁区
- 只是修按钮反馈、对比度、冗余标题、空间浪费
- 已有设计系统，不需要再找方向

冲突规则：

- 跟 `ui-core` 冲突，`ui-polish` 赢
- 跟 `ui-review` 冲突，`ui-polish` 赢
