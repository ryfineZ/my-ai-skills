---
name: ui-core
disable-model-invocation: true
description: Use when you need the non-negotiable ui-polish rules for UI direction, color, copy, spacing, readability, button feedback, and layout restraint before making interface decisions.
---

# UI Core

这些是硬约束，不是建议。拿不准时，删掉多余部分，不要再继续加。

- 先定平台、界面类型、主任务、视觉方向，再做 UI。
- 用 token 管颜色、间距、圆角、阴影、边框和动效，不要散落原始值。
- 无明确品牌或现有设计系统依据时，不要默认使用蓝紫/紫粉渐变、蓝紫玻璃、紫白 SaaS、黑底霓虹青、祖母绿/翡翠绿、银灰、雾绿、橙红/焦橙渐变这类常见 AI 惯用配色。
- 主任务、主按钮、主信息必须最先被看见，不要让装饰层压过内容层。
- 文案必须站在使用者视角；禁止自我解释、抽象空话、提示词残留、没信息价值的大标题，以及重复的小标题、眉标题、分组标题。
- 默认不写区域标题、眉标题、解释型标题。
- 能靠内容本身、位置关系、状态变化看懂的，就不要标题。
- 结构必须克制：尺寸匹配内容，间距只够分组，不要无意义外框、内框，不要空耗空间。
- 间距必须表达关系：同组标题、工具条、按钮和内容要贴近；只有跨组、跨区块时才拉开，不要让标题层和内容层脱节。
- 透明感必须靠底层反差成立：底层和上层要有可见的明度/色相差异，不要用同色半透明假装玻璃。
- 可读性必须过关：小字、辅助文案、半透明层文字都要清晰；低对比度、发灰、发虚直接算失败。
- 需要补充说明时，优先用 hover / focus 浮层承载，不要把界面塞满解释文字；浮层要轻、透明、小，不要盖住底层视线。
- 按钮必须有明确反馈；点击后要立刻让用户知道是否生效、是否处理中、结果如何。
- 按钮必须收敛；同层只保留必要操作，重复、近义、同权重按钮要合并或删除。
- 必须补齐 `hover`、`active`、`focus`、`disabled`、`loading`、`empty`、`error`。
- 动效只服务反馈和层级切换；优先 `transform` 和 `opacity`，不要堆无意义特效。
- 高频交互默认按性能敏感场景实现：减少每帧测量和 DOM 工作量，能缓存就缓存，能按帧合并就不要在每次事件里硬算。

按需补充：

- 文案细化：`../ui-copy/SKILL.md`
- 反馈细化：`../ui-feedback/SKILL.md`
- 规则细节：`references/hard-rules.md`
- token 与密度：`references/tokens-and-density.md`
