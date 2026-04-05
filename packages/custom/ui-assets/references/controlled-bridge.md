# Controlled Bridge

`ui-ux-pro-max` 在 `ui-polish` 里只能做参考，不做裁判。

## 什么时候允许桥接

- 风格方向不清楚
- 需要查单点维度：style / typography / ux / product type
- 需要查技术栈相关建议

## 什么时候不要桥接

- 用户已经给了明确禁区
- 只是修按钮反馈、对比度、冗余标题、空间浪费
- 已有成熟设计系统

## 命令

先路由：

```bash
python3 ~/.agents/skills/ui-assets/scripts/route_ui_task.py \
  --platform ext \
  --surface popup \
  --goal "3 秒内完成当前站点检查" \
  --style "focused utility" \
  --needs-feedback
```

再按需桥接：

```bash
python3 ~/.agents/skills/ui-assets/scripts/query_ui_reference.py \
  --query "extension popup current page status" \
  --platform ext \
  --surface popup \
  --style "focused utility" \
  --domain ux
```

## 过滤原则

- 保留：结构、节奏、状态、少量组件策略
- 慎用：风格名词、配色建议、泛化文案
- 丢弃：模板味太重、回到安全配色、与 ui-core 冲突的内容
