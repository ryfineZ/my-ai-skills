#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import shlex
import subprocess
import sys
from pathlib import Path


PLATFORM_LABELS = {
    "web": "Web / 浏览器页面",
    "mobile": "Mobile App / H5",
    "mini": "小程序",
    "ext": "Chrome 扩展",
    "desktop": "桌面 App",
}

PRESETS_PATH = Path("~/.agents/skills/ui-assets/assets/style-presets.json").expanduser().resolve()
INTERACTION_PRESETS_PATH = Path("~/.agents/skills/ui-assets/assets/interaction-presets.json").expanduser().resolve()


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_style_presets() -> dict:
    return load_json(PRESETS_PATH)


def load_interaction_presets() -> dict:
    return load_json(INTERACTION_PRESETS_PATH)


def normalize_text(value: str) -> str:
    cleaned = re.sub(r"[\+\-_/,，。；：:!！?？()（）]+", " ", value.strip().lower())
    return " ".join(cleaned.split())


def resolve_preset(value: str, presets: dict) -> tuple[str, dict | None]:
    normalized = normalize_text(value)
    best_match: tuple[str, dict, int] | None = None
    for key, preset in presets.items():
        aliases = [key, *preset.get("aliases", [])]
        normalized_aliases = {normalize_text(item) for item in aliases}
        if normalized in normalized_aliases:
            return key, preset
        for alias in normalized_aliases:
            if alias and alias in normalized:
                score = len(alias)
                if not best_match or score > best_match[2]:
                    best_match = (key, preset, score)
    if best_match:
        return best_match[0], best_match[1]
    return value, None


def resolve_style_preset(style: str) -> tuple[str, dict | None]:
    return resolve_preset(style, load_style_presets())


def resolve_interaction_preset(interaction: str) -> tuple[str, dict | None]:
    return resolve_preset(interaction, load_interaction_presets())


def match_preset_from_text(text: str, presets: dict) -> tuple[str | None, dict | None]:
    normalized = normalize_text(text)
    if not normalized:
        return None, None
    best_match: tuple[str, dict, int] | None = None
    for key, preset in presets.items():
        aliases = [key, *preset.get("aliases", [])]
        normalized_aliases = [normalize_text(alias) for alias in aliases]
        for alias in normalized_aliases:
            if alias and alias in normalized:
                score = len(alias)
                if not best_match or score > best_match[2]:
                    best_match = (key, preset, score)
    if best_match:
        return best_match[0], best_match[1]
    return None, None


def match_all_presets_from_text(text: str, presets: dict) -> list[tuple[str, dict]]:
    normalized = normalize_text(text)
    if not normalized:
        return []
    matches: list[tuple[str, dict, int]] = []
    for key, preset in presets.items():
        aliases = [key, *preset.get("aliases", [])]
        best_score = 0
        for alias in aliases:
            normalized_alias = normalize_text(alias)
            if normalized_alias and normalized_alias in normalized:
                best_score = max(best_score, len(normalized_alias))
        if best_score:
            matches.append((key, preset, best_score))
    matches.sort(key=lambda item: item[2], reverse=True)
    return [(key, preset) for key, preset, _score in matches]


def collect_request_hints(request: str | None) -> dict:
    text = (request or "").strip()
    style_key, style_preset = match_preset_from_text(text, load_style_presets())
    interaction_matches = match_all_presets_from_text(text, load_interaction_presets())
    interaction_key = interaction_matches[0][0] if interaction_matches else None
    interaction_preset = interaction_matches[0][1] if interaction_matches else None
    lowered = text.lower()
    copy_keywords = ("文案", "copy", "标题", "按钮文案", "描述语")
    feedback_keywords = ("反馈", "加载", "处理中", "状态", "hover", "active", "focus", "disabled", "error", "empty")
    needs_copy = any(keyword in lowered for keyword in copy_keywords)
    needs_feedback = bool(interaction_preset) or any(keyword in lowered for keyword in feedback_keywords)
    return {
        "style_key": style_key,
        "style_preset": style_preset,
        "interaction_key": interaction_key,
        "interaction_preset": interaction_preset,
        "interaction_keys": [key for key, _preset in interaction_matches],
        "interaction_presets": [preset for _key, preset in interaction_matches],
        "needs_copy": needs_copy,
        "needs_feedback": needs_feedback,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a minimal ui-polish workflow pack.")
    parser.add_argument("--platform", required=True, choices=sorted(PLATFORM_LABELS.keys()))
    parser.add_argument("--surface", required=True, help="Interface type, such as popup, dashboard, form.")
    parser.add_argument("--goal", required=True, help="Primary user task for this interface.")
    parser.add_argument("--style", default="tooling", help="Visual direction. Use 'unclear' if not decided.")
    parser.add_argument("--interaction", help="Behavior direction, such as drag reorder or long press sort.")
    parser.add_argument("--request", help="Optional raw natural-language request. Used to infer style and interaction hints.")
    parser.add_argument("--stack", help="Optional implementation stack.")
    parser.add_argument("--constraints", default="保持现有组件库与技术栈不变", help="Known constraints.")
    parser.add_argument("--needs-copy", action="store_true")
    parser.add_argument("--needs-feedback", action="store_true")
    parser.add_argument("--needs-pencil", action="store_true")
    parser.add_argument("--needs-reference", action="store_true")
    parser.add_argument("--html", help="Optional local HTML file for review command templates.")
    parser.add_argument("--url", help="Optional local or remote URL for review command templates.")
    parser.add_argument("--code-path", help="Optional file or directory for static checks.")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output for agents.")
    return parser.parse_args()


def run_route(
    args: argparse.Namespace,
    *,
    resolved_style: str,
    needs_copy: bool,
    needs_feedback: bool,
) -> dict:
    script = Path("~/.agents/skills/ui-assets/scripts/route_ui_task.py").expanduser().resolve()
    cmd = [
        "python3",
        str(script),
        "--platform",
        args.platform,
        "--surface",
        args.surface,
        "--goal",
        args.goal,
        "--style",
        resolved_style,
    ]
    if args.stack:
        cmd.extend(["--stack", args.stack])
    if needs_copy:
        cmd.append("--needs-copy")
    if needs_feedback:
        cmd.append("--needs-feedback")
    if args.needs_pencil:
        cmd.append("--needs-pencil")
    if args.needs_reference:
        cmd.append("--needs-reference")
    cmd.append("--json")

    completed = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        raise SystemExit(completed.stderr.strip() or "route_ui_task.py 执行失败")
    return json.loads(completed.stdout)


def build_reference_command(args: argparse.Namespace, style_value: str) -> str | None:
    _, preset = resolve_style_preset(style_value)
    if not args.needs_reference and style_value.strip().lower() != "unclear":
        return None
    script = Path("~/.agents/skills/ui-assets/scripts/query_ui_reference.py").expanduser().resolve()
    query = preset.get("reference_query") if preset else f"{args.surface} {args.goal}"
    cmd = [
        "python3",
        str(script),
        "--query",
        query,
        "--platform",
        args.platform,
        "--surface",
        args.surface,
        "--style",
        preset["label"] if preset else style_value,
    ]
    if args.stack:
        cmd.extend(["--stack", args.stack])
    return " ".join(shlex.quote(part) for part in cmd)


def build_review_commands(args: argparse.Namespace) -> list[str]:
    commands: list[str] = []
    if args.code_path:
        commands.append(
            "python3 ~/.agents/skills/ui-assets/scripts/check_ui_rules.py "
            + shlex.quote(args.code_path)
        )
    else:
        commands.append("python3 ~/.agents/skills/ui-assets/scripts/check_ui_rules.py <code-path>")

    if args.html:
        commands.append(
            "python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --file "
            + shlex.quote(args.html)
        )
        commands.append(
            "python3 ~/.agents/skills/ui-polish/scripts/capture_ui.py --file "
            + shlex.quote(args.html)
            + " --out /tmp/ui-shot.png"
        )
    elif args.url:
        commands.append(
            "python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --url "
            + shlex.quote(args.url)
        )
        commands.append(
            "python3 ~/.agents/skills/ui-polish/scripts/capture_ui.py --url "
            + shlex.quote(args.url)
            + " --out /tmp/ui-shot.png"
        )
    else:
        commands.append("python3 ~/.agents/skills/ui-assets/scripts/inspect_runtime.py --file <html-file>")
        commands.append("python3 ~/.agents/skills/ui-polish/scripts/capture_ui.py --file <html-file> --out /tmp/ui-shot.png")
    return commands


def main() -> int:
    args = parse_args()
    request_hints = collect_request_hints(args.request)
    requested_style = args.style
    if (
        requested_style == "tooling"
        and request_hints["style_key"]
        and request_hints["style_key"] != "tooling"
    ):
        requested_style = request_hints["style_key"]
    style_key, style_preset = resolve_style_preset(requested_style)
    interaction_value = args.interaction or request_hints["interaction_key"]
    interaction_matches: list[tuple[str, dict]] = []
    if args.interaction:
        resolved_key, resolved_preset = resolve_interaction_preset(args.interaction)
        if resolved_preset:
            interaction_matches.append((resolved_key, resolved_preset))
    else:
        interaction_matches = list(zip(request_hints["interaction_keys"], request_hints["interaction_presets"]))
    interaction_key = interaction_matches[0][0] if interaction_matches else None
    interaction_preset = interaction_matches[0][1] if interaction_matches else None
    interaction_keys = [key for key, _preset in interaction_matches]
    interaction_presets = [preset for _key, preset in interaction_matches]
    interaction_labels = [preset["label"] for preset in interaction_presets]

    needs_copy = args.needs_copy or request_hints["needs_copy"]
    needs_feedback = args.needs_feedback or request_hints["needs_feedback"] or bool(interaction_presets)
    route_payload = run_route(
        args,
        resolved_style=style_preset["label"] if style_preset else requested_style,
        needs_copy=needs_copy,
        needs_feedback=needs_feedback,
    )
    reference_command = build_reference_command(args, style_key if style_preset else requested_style)
    review_commands = build_review_commands(args)
    brief_constraints = [args.constraints]
    if style_preset:
        brief_constraints.extend(style_preset.get("hidden_constraints", []))
    for preset in interaction_presets:
        brief_constraints.extend(preset.get("hidden_constraints", []))
    workflow_payload = {
        "brief": {
            "platform": args.platform,
            "platform_label": PLATFORM_LABELS[args.platform],
            "surface": args.surface,
            "goal": args.goal,
            "request": args.request,
            "style": style_preset["label"] if style_preset else requested_style,
            "style_key": style_key,
            "style_summary": style_preset.get("summary") if style_preset else None,
            "interaction": interaction_preset["label"] if interaction_preset else interaction_value,
            "interaction_key": interaction_key,
            "interaction_summary": interaction_preset.get("summary") if interaction_preset else None,
            "interactions": interaction_labels,
            "interaction_keys": interaction_keys,
            "stack": args.stack,
            "needs_copy": needs_copy,
            "needs_feedback": needs_feedback,
            "constraints": brief_constraints,
        },
        "route": route_payload,
        "reference_command": reference_command,
        "review_commands": review_commands,
        "style_preset": style_preset,
        "interaction_preset": interaction_preset,
        "interaction_presets": interaction_presets,
        "notes": [
            "这只是起手包，不负责生成 UI。",
            "先 brief，再 route，再实现，最后 review。",
            "如果用户用了自然语言描述交互，默认先提取行为意图，不要反过来逼用户补实现细节。",
            "如果结果开始模板味变重，回到 ui-core，不要继续堆参考。",
        ],
    }

    if args.json:
        print(json.dumps(workflow_payload, ensure_ascii=False, indent=2))
        return 0

    lines: list[str] = []
    lines.append("## UI Workflow")
    lines.append("")
    lines.append("### Brief")
    lines.append(f"- 平台: {PLATFORM_LABELS[args.platform]}")
    lines.append(f"- 界面类型: {args.surface}")
    lines.append(f"- 主任务: {args.goal}")
    if args.request:
        lines.append(f"- 原始描述: {args.request}")
    lines.append(f"- 视觉方向: {style_preset['label'] if style_preset else requested_style}")
    if interaction_presets or interaction_value:
        if len(interaction_labels) > 1:
            lines.append(f"- 交互方向: {', '.join(interaction_labels)}")
        else:
            lines.append(f"- 交互方向: {interaction_preset['label'] if interaction_preset else interaction_value}")
    if args.stack:
        lines.append(f"- 技术栈: {args.stack}")
    if style_preset:
        lines.append(f"- 风格预设: {style_key}")
        lines.append(f"- 风格摘要: {style_preset['summary']}")
    if interaction_preset:
        lines.append(f"- 交互预设: {interaction_key}")
        lines.append(f"- 交互摘要: {interaction_preset['summary']}")
    if len(interaction_keys) > 1:
        lines.append(f"- 已命中交互预设: {', '.join(interaction_keys)}")
    lines.append(f"- 已知约束: {args.constraints}")
    lines.append(f"- 自动判定: needs-copy={str(needs_copy).lower()}, needs-feedback={str(needs_feedback).lower()}")
    if style_preset:
        lines.append("- 自动带出的隐藏约束:")
        for item in style_preset.get("hidden_constraints", []):
            lines.append(f"  - {item}")
    if interaction_presets:
        if not style_preset:
            lines.append("- 自动带出的隐藏约束:")
        for preset in interaction_presets:
            for item in preset.get("hidden_constraints", []):
                lines.append(f"  - {item}")
    review_focus: list[str] = []
    if style_preset and style_preset.get("review_focus"):
        review_focus.extend(style_preset["review_focus"])
    for preset in interaction_presets:
        if preset.get("review_focus"):
            review_focus.extend(preset["review_focus"])
    if review_focus:
        lines.append("- review 重点:")
        for item in review_focus:
            lines.append(f"  - {item}")
    lines.append("")
    lines.append("### Route")
    lines.append("## UI Polish Route")
    lines.append(f"- 平台: {route_payload['platform_label']}")
    lines.append(f"- 界面类型: {route_payload['surface']}")
    lines.append(f"- 主任务: {route_payload['goal']}")
    lines.append(f"- 视觉方向: {route_payload['style']}")
    if route_payload.get("stack"):
        lines.append(f"- 技术栈: {route_payload['stack']}")
    lines.append("")
    lines.append("## 必经顺序")
    for index, item in enumerate(route_payload["route"], start=1):
        lines.append(f"{index}. {item}")
    if route_payload["optional"]:
        lines.append("")
        lines.append("## 按需补充")
        for item in route_payload["optional"]:
            lines.append(f"- {item}")
    lines.append("")
    lines.append("## 约束提醒")
    for item in route_payload["constraints"]:
        lines.append(f"- {item}")
    lines.append("")
    lines.append("### Commands")
    if reference_command:
        lines.append("- 参考查询")
        lines.append(f"  `{reference_command}`")
    else:
        lines.append("- 参考查询")
        lines.append("  `当前方向明确，可先不查参考。`")
    lines.append("- Review")
    for command in review_commands:
        lines.append(f"  `{command}`")
    lines.append("")
    lines.append("### Notes")
    lines.append("- 这只是起手包，不负责生成 UI。")
    lines.append("- 先 brief，再 route，再实现，最后 review。")
    lines.append("- 用户若已用自然语言说明交互，默认视为有效需求，不要再逼他补实现术语。")
    lines.append("- 如果结果开始模板味变重，回到 ui-core，不要继续堆参考。")

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
