# Style Presets

常用风格不要再让用户重复写防翻车约束。优先用内置 preset。

## 规则

- 先用 preset 名，再让 agent 自动带出隐藏约束。
- 只有真的全新、自定义风格，才额外补充说明。
- preset 解决的是“默认怎么不翻车”，不是替代审美判断。

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
- `dark-editorial`

## 例子

不要再这样：

```text
风格：液态玻璃 + 赛博朋克 + 暗黑神秘系
约束：不要蓝紫霓虹，不要银灰，不要雾绿，玻璃只做承载层……
```

直接这样：

```text
风格：liquid-glass-cyber-dark
```

`ui_workflow.py` 会自动展开这类 preset 的隐藏约束、reference query 和 review 重点。
