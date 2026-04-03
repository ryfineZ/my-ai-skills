# Review Workflow

## Default Flow

1. 先跑静态规则检查，抓 token、文案、配色和状态硬伤
2. 再跑运行时检查，抓标题密度、按钮重复、容器层级
3. 最后只在关键节点看图，不把截图当默认主流程

## Commands

```bash
python3 ~/.agents/skills/ui-assets/scripts/check_ui_rules.py <path>
python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --file <html>
python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --url <url>
python3 ~/.agents/skills/ui-polish/scripts/capture_ui.py --file <html> --out /tmp/ui-shot.png
```

## When Screenshot Is Required

- 玻璃、材质、强层级、复杂阴影
- 文字可读性存在风险
- 多区域并排布局
- 需要给用户直接看效果
