# Style Presets

常用风格不要再让用户重复写防翻车约束。优先用内置 preset。

## 规则

- 先用 preset 名，再让 agent 自动带出隐藏约束。
- 只有真的全新、自定义风格，才额外补充说明。
- preset 解决的是“默认怎么不翻车”，不是替代审美判断。
- 如果用户说“想看不同配色效果”或“切几个主题看看”，默认理解为：背景场景 + 配色关系一起变化，不是只改整页色相。
- 如果 preset 带玻璃/透明材质，agent 应默认先做场景层，再做玻璃层，而不是只堆半透明蒙版。
- 玻璃、Tahoe、场景化主题切换等高视觉风险 preset，默认强制走视觉复审，不允许只靠静态检查签收。

## 可用 Presets

- `tooling`
- `editorial`
- `data-panel`
- `brand-display`
- `calm-utility`
- `focused-utility`
- `native-utility`
- `tahoe-glass`
- `liquid-glass-cyber-dark`
- `sky-glass`
- `trisolaris`
- `matrix-code`
- `dark-editorial`

## 例子

不要再这样：

```text
风格：液态玻璃 + 赛博朋克 + 暗黑神秘系
约束：不要蓝紫/紫粉、黑底霓虹青、祖母绿、银灰、雾绿、橙红渐变，玻璃只做承载层……
```

直接这样：

```text
风格：liquid-glass-cyber-dark
```

`ui_workflow.py` 会自动展开这类 preset 的隐藏约束、reference query 和 review 重点。

如果用户要“切几种明显不同的主题效果”，优先直接用场景化 preset：

- `sky-glass`
- `trisolaris`
- `matrix-code`
