# UI Workflow

`ui_workflow.py` 是一个很薄的一键起手脚本，不负责生成 UI，只负责把这次任务的起手包吐出来。对 agent 来说，它应该是新 UI 任务的默认起点。

## 作用

一次输出四样东西：

- brief
- route
- 可选 reference 命令
- review 命令模板

支持两种输出：

- 默认文本：适合直接读
- `--json`：适合 agent 继续消费

风格优先用 preset 名：

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

命中 preset 后，agent 不应该再让用户重复写同一类风格约束。

交互也支持 preset：

- `hover-explain`
- `click-feedback`
- `drag-reorder-grid`

命中用户自然语言里的交互意图后，agent 应默认带出隐藏约束和 review 重点，不要再逼用户补实现术语。多个交互 preset 可以同时命中。

## 用法

```bash
python3 ~/.agents/skills/ui-assets/scripts/ui_workflow.py \
  --platform ext \
  --surface popup \
  --goal "3 秒内完成当前站点检查" \
  --style "focused utility" \
  --request "按住拖动换位置，像手机图标一样" \
  --needs-feedback \
  --html /abs/path/demo.html \
  --code-path /abs/path/src
```

## 什么时候适合用

- 新开一个 UI 任务
- 想避免漏掉 brief / route / review
- 需要给未来自己或别的 agent 一个统一起手动作

## 什么时候不必用

- 只是极小的局部改字、改间距
- 当前任务已经在 `ui-polish` 流程中间，不需要重新起手
