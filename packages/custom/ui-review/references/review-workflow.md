# Review Workflow

## Default Flow

1. 先跑静态规则检查，抓 token、文案、配色和状态硬伤
2. 再跑运行时检查，抓标题密度、按钮重复、解释型文案、按钮按下反馈和容器层级
3. 若第 2 步命中 `visual-review`，先截图复审，再带 `--visual-reviewed` 复跑运行时检查
4. 非高视觉风险场景不把截图当默认主流程

## Commands

```bash
python3 ~/.agents/skills/ui-assets/scripts/check_ui_rules.py <path>
python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --file <html>
python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --url <url>
python3 ~/.agents/skills/ui-polish/scripts/capture_ui.py --file <html> --out /tmp/ui-shot.png
python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --file <html> --visual-reviewed
```

## When Screenshot Is Required

- 玻璃、材质、强层级、复杂阴影
- 图表 hover、探针点、跟随竖线、数据浮层
- 文字可读性存在风险
- 多区域并排布局
- 大留白里的标题、角标数字、时间、金额、计数等需要看视觉对齐而不是只看代码对齐
- 需要给用户直接看效果
