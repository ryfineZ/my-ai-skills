#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
from pathlib import Path


SAFE_BRIDGE_REASONS = (
    "风格方向还不清楚",
    "需要查单点维度",
    "需要查栈相关建议",
)

PLATFORM_LABELS = {
    "web": "Web / 浏览器页面",
    "mobile": "Mobile App / H5",
    "mini": "小程序",
    "ext": "Chrome 扩展",
    "desktop": "桌面 App",
}

BANNED_DEFAULTS = (
    "蓝紫渐变",
    "蓝紫玻璃",
    "紫白 SaaS",
    "银灰",
    "雾绿",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Controlled ui-ux-pro-max bridge for ui-polish.")
    parser.add_argument("--query", required=True, help="Reference query sent to ui-ux-pro-max.")
    parser.add_argument("--platform", required=True, choices=["web", "mobile", "mini", "ext", "desktop"])
    parser.add_argument("--surface", required=True, help="Surface type, such as popup, dashboard, form.")
    parser.add_argument("--style", required=True, help="Current visual direction or 'unclear'.")
    parser.add_argument("--stack", help="Optional implementation stack.")
    parser.add_argument("--domain", choices=["style", "color", "typography", "ux", "product", "landing"])
    parser.add_argument("--design-system", action="store_true", help="Use design-system mode instead of simple search.")
    parser.add_argument("--project-name", default="UI Polish Ref", help="Project name for design-system mode.")
    parser.add_argument("--max-results", type=int, default=3)
    return parser.parse_args()


def build_command(args: argparse.Namespace) -> list[str]:
    search_script = Path("~/.agents/skills/ui-ux-pro-max/scripts/search.py").expanduser().resolve()
    cmd = ["python3", str(search_script), args.query]
    if args.design_system:
        cmd.extend(["--design-system", "-p", args.project_name])
    elif args.domain:
        cmd.extend(["--domain", args.domain])
    if args.stack:
        cmd.extend(["--stack", args.stack])
    cmd.extend(["--max-results", str(args.max_results)])
    return cmd


def main() -> int:
    args = parse_args()
    cmd = build_command(args)

    print("## UI Polish Controlled Reference")
    print(f"- 平台: {PLATFORM_LABELS[args.platform]}")
    print(f"- 界面类型: {args.surface}")
    print(f"- 当前方向: {args.style}")
    if args.stack:
        print(f"- 技术栈: {args.stack}")
    print("- 这一步只拿参考，不拍板。")
    print(f"- 允许调用原因: {' / '.join(SAFE_BRIDGE_REASONS)}")
    print(f"- 仍然禁止默认落回: {' / '.join(BANNED_DEFAULTS)}")
    print("")
    print("## Command")
    print("```bash")
    print(" ".join(shlex.quote(part) for part in cmd))
    print("```")
    print("")
    print("## Output")

    completed = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if completed.stdout:
        print(completed.stdout.strip())
    if completed.returncode != 0:
        if completed.stderr:
            print("\n## Error")
            print(completed.stderr.strip())
        return completed.returncode

    print("")
    print("## UI Polish Filter")
    print("- 只吸收结构、排版、组件节奏、状态建议。")
    print("- 颜色建议必须经过 ui-core 和 ui-review 过滤。")
    print("- 如果输出看起来模板味太重，直接丢弃，不强行采用。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
