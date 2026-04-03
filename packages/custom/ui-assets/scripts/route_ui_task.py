#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys


PLATFORM_SKILLS = {
    "web": "../ui-web/SKILL.md",
    "mobile": "../ui-mobile/SKILL.md",
    "mini": "../ui-mini/SKILL.md",
    "ext": "../ui-ext/SKILL.md",
    "desktop": "../ui-desktop/SKILL.md",
}

PLATFORM_LABELS = {
    "web": "Web / 浏览器页面",
    "mobile": "Mobile App / H5",
    "mini": "小程序",
    "ext": "Chrome 扩展",
    "desktop": "桌面 App",
}

REFERENCE_NEEDED_STYLES = {
    "unclear",
    "exploratory",
    "new direction",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Route a UI task through the ui-polish bundle.")
    parser.add_argument("--platform", required=True, choices=sorted(PLATFORM_SKILLS.keys()))
    parser.add_argument("--surface", required=True, help="Interface type, such as popup, dashboard, form, settings.")
    parser.add_argument("--goal", required=True, help="Primary user task for the interface.")
    parser.add_argument("--style", default="tooling", help="Visual direction. Use 'unclear' if not decided yet.")
    parser.add_argument("--stack", help="Optional stack hint, such as react, vue, tailwind, react-native.")
    parser.add_argument("--needs-copy", action="store_true", help="Route through ui-copy.")
    parser.add_argument("--needs-feedback", action="store_true", help="Route through ui-feedback.")
    parser.add_argument("--needs-pencil", action="store_true", help="Route through ui-pencil for visual co-editing.")
    parser.add_argument("--needs-reference", action="store_true", help="Explicitly allow ui-ux-pro-max reference lookup.")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    route = [
        "ui-polish",
        "using-ui-polish",
        "ui-core",
        PLATFORM_SKILLS[args.platform],
    ]
    optional = []

    if args.needs_copy:
        optional.append("../ui-copy/SKILL.md")
    if args.needs_feedback:
        optional.append("../ui-feedback/SKILL.md")
    if args.needs_pencil:
        optional.append("../ui-pencil/SKILL.md")

    allow_reference = args.needs_reference or args.style.strip().lower() in REFERENCE_NEEDED_STYLES
    if allow_reference:
        optional.append("ui-ux-pro-max (reference only)")

    route.append("../ui-review/SKILL.md")

    payload = {
        "platform": args.platform,
        "platform_label": PLATFORM_LABELS[args.platform],
        "surface": args.surface,
        "goal": args.goal,
        "style": args.style,
        "stack": args.stack,
        "route": route,
        "optional": optional,
        "allow_reference": allow_reference,
        "constraints": [
            "没有品牌依据时，不要默认回到蓝紫、银灰、雾绿安全配色。",
            "先收结构和层级，再补材质和装饰。",
            "输出前必须走 ui-review。",
        ],
    }

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0

    lines = []
    lines.append("## UI Polish Route")
    lines.append(f"- 平台: {PLATFORM_LABELS[args.platform]}")
    lines.append(f"- 界面类型: {args.surface}")
    lines.append(f"- 主任务: {args.goal}")
    lines.append(f"- 视觉方向: {args.style}")
    if args.stack:
        lines.append(f"- 技术栈: {args.stack}")

    lines.append("")
    lines.append("## 必经顺序")
    for index, item in enumerate(route, start=1):
        lines.append(f"{index}. {item}")

    if optional:
        lines.append("")
        lines.append("## 按需补充")
        for item in optional:
            lines.append(f"- {item}")

    lines.append("")
    lines.append("## 约束提醒")
    lines.append("- 没有品牌依据时，不要默认回到蓝紫、银灰、雾绿安全配色。")
    lines.append("- 先收结构和层级，再补材质和装饰。")
    lines.append("- 输出前必须走 ui-review。")

    if allow_reference:
        query = f"{args.surface} {args.goal}"
        lines.append("")
        lines.append("## 受控参考命令")
        lines.append(
            "python3 ~/.agents/skills/ui-assets/scripts/query_ui_reference.py "
            f"--query \"{query}\" --platform {args.platform} --surface \"{args.surface}\" "
            f"--style \"{args.style}\""
            + (f" --stack {args.stack}" if args.stack else "")
        )

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
