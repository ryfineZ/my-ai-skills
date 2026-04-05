#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
import urllib.request
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path


HEADING_TAGS = {"h1", "h2", "h3", "h4", "h5", "h6"}
GENERIC_TAGS = {"div", "section"}
BUTTON_TAGS = {"button"}
TEXT_CAPTURE_TAGS = HEADING_TAGS | BUTTON_TAGS | {"a", "label", "p", "span"}
SMELL_WORDS = ("智能", "高效", "一站式", "在这里", "用于", "当前账号", "账号池")
EXPLANATORY_LABELS = (
    "what changed",
    "current direction",
    "interaction states",
    "design rule",
    "layout pass",
    "approved sources",
    "material details",
    "sample interface",
    "generated under the new rules",
    "static beauty is not enough",
    "ready now",
    "fix first",
    "当前方向",
    "交互状态",
    "设计规则",
    "变更内容",
    "材质细节",
    "主链路",
    "终端带",
    "关键节点会提亮",
    "高危行会直接抬亮",
    "关键节点会压亮，不会满屏闪",
)

LABELISH_CLASS_TOKENS = (
    "eyebrow",
    "section-title",
    "tag",
    "terminaltag",
    "label",
)
VISUAL_REVIEW_MARKERS = (
    "backdrop-filter",
    "data-theme=\"sky-glass\"",
    "data-theme=\"trisolaris\"",
    "data-theme=\"matrix-code\"",
    "tahoe",
    "liquid-glass",
    "glass",
    "chart",
    "probe",
)
CSS_BLOCK_RE = re.compile(r"(?P<selector>[^{]+)\{(?P<body>[^{}]+)\}", re.S)
MUTED_COLOR_TOKENS = (
    "--ink-secondary",
    "--ink-tertiary",
    "--ink-soft",
    "--summary-label",
    "--control-note",
    "--text-dim",
    "--text-muted",
)
RISKY_TEXT_SELECTORS = (
    "span",
    "small",
    "note",
    "label",
    "meta",
    "brief",
    "subtitle",
    "caption",
)


class RuntimeInspector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[tuple[str, dict[str, str], int]] = []
        self.capture_stack: list[tuple[str, int, list[str]]] = []
        self.headings: list[tuple[str, int, str]] = []
        self.labelish_texts: list[tuple[str, int, str]] = []
        self.buttons: list[tuple[int, str, dict[str, str]]] = []
        self.stylesheets: list[str] = []
        self.max_generic_depth = 0
        self.generic_count = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_map = {key: value or "" for key, value in attrs}
        line_no, _ = self.getpos()
        self.stack.append((tag, attr_map, line_no))
        generic_depth = sum(1 for item, _, _ in self.stack if item in GENERIC_TAGS)
        self.max_generic_depth = max(self.max_generic_depth, generic_depth)
        if tag in GENERIC_TAGS:
            self.generic_count += 1
        if tag in TEXT_CAPTURE_TAGS:
            self.capture_stack.append((tag, line_no, []))
        if tag == "link" and attr_map.get("rel") == "stylesheet" and attr_map.get("href"):
            self.stylesheets.append(attr_map["href"])

    def handle_data(self, data: str) -> None:
        if self.capture_stack:
            self.capture_stack[-1][2].append(data)

    def handle_endtag(self, tag: str) -> None:
        if self.capture_stack and self.capture_stack[-1][0] == tag:
            capture_tag, line_no, parts = self.capture_stack.pop()
            text = " ".join(part.strip() for part in parts if part.strip()).strip()
            if capture_tag in HEADING_TAGS and text:
                self.headings.append((capture_tag, line_no, text))
            if capture_tag in {"p", "span"} and text:
                attrs = {}
                for item_tag, item_attrs, item_line in reversed(self.stack):
                    if item_tag == capture_tag and item_line == line_no:
                        attrs = item_attrs
                        break
                class_id_blob = f"{attrs.get('class', '')} {attrs.get('id', '')}".replace("-", "").replace("_", "").lower()
                if any(token.replace("-", "").replace("_", "") in class_id_blob for token in LABELISH_CLASS_TOKENS):
                    self.labelish_texts.append((capture_tag, line_no, text))
            if capture_tag in BUTTON_TAGS and text:
                attrs = {}
                for item_tag, item_attrs, item_line in reversed(self.stack):
                    if item_tag == capture_tag and item_line == line_no:
                        attrs = item_attrs
                        break
                self.buttons.append((line_no, text, attrs))
        while self.stack:
            item_tag, _, _ = self.stack.pop()
            if item_tag == tag:
                break


def load_html(url: str | None, file_path: str | None) -> str:
    if bool(url) == bool(file_path):
        raise SystemExit("必须二选一：传 --url 或 --file。")
    if url:
        with urllib.request.urlopen(url) as response:
            return response.read().decode("utf-8", errors="ignore")
    path = Path(file_path).expanduser().resolve()
    return path.read_text(encoding="utf-8", errors="ignore")


def load_local_css_bundle(html_path: Path, hrefs: list[str]) -> str:
    chunks: list[str] = []
    for href in hrefs:
        if not href or href.startswith(("http://", "https://", "//")):
            continue
        css_path = (html_path.parent / href).resolve()
        if not css_path.is_file():
            continue
        chunks.append(css_path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(chunks)


def needs_visual_review(html: str, css_text: str) -> bool:
    bundle = f"{html}\n{css_text}".lower()
    return any(marker.lower() in bundle for marker in VISUAL_REVIEW_MARKERS)


def has_active_feedback_style(css_text: str, attrs: dict[str, str]) -> bool:
    classes = [item for item in attrs.get("class", "").split() if item]
    selectors = ["button", *[f".{item}" for item in classes]]
    for selector in selectors:
        if any(
            token in css_text
            for token in (
                f"{selector}:active",
                f"{selector}.active",
                f"{selector}.is-active",
                f"{selector}[aria-pressed",
                f"{selector}[data-state",
                f"{selector}:has(",
            )
        ):
            return True
    return False


def parse_numeric_px(value: str) -> float | None:
    match = re.search(r"([0-9]+(?:\.[0-9]+)?)px", value)
    if not match:
        return None
    return float(match.group(1))


def parse_opacity_value(value: str) -> float | None:
    match = re.search(r"([0-9]+(?:\.[0-9]+)?)", value)
    if not match:
        return None
    return float(match.group(1))


def css_line_no(css_text: str, offset: int) -> int:
    return css_text.count("\n", 0, offset) + 1


def readability_findings(css_text: str) -> list[str]:
    findings: list[str] = []
    for match in CSS_BLOCK_RE.finditer(css_text):
        selector = " ".join(match.group("selector").split())
        body = match.group("body")
        body_lower = body.lower()
        selector_lower = selector.lower()

        if "color:" not in body_lower:
            continue

        uses_muted_token = any(token in body for token in MUTED_COLOR_TOKENS)
        has_small_text = False
        has_low_opacity = False

        for raw_line in body.split(";"):
            line = raw_line.strip()
            if not line:
                continue
            lower = line.lower()
            if lower.startswith("font-size"):
                size = parse_numeric_px(line)
                if size is not None and size <= 13:
                    has_small_text = True
            if lower.startswith("opacity"):
                opacity = parse_opacity_value(line)
                if opacity is not None and opacity < 0.9:
                    has_low_opacity = True

        selector_risky = any(token in selector_lower for token in RISKY_TEXT_SELECTORS)

        if uses_muted_token and (has_small_text or has_low_opacity or selector_risky):
            line_no = css_line_no(css_text, match.start())
            findings.append(
                f"BLOCK readability-risk  CSS 第 {line_no} 行附近的“{selector}”对小字/辅助字使用了弱色 token，需人工确认对比度。"
            )

        if ("backdrop-filter" in body_lower or "filter:" in body_lower) and uses_muted_token and has_small_text:
            line_no = css_line_no(css_text, match.start())
            findings.append(
                f"BLOCK glass-copy-risk  CSS 第 {line_no} 行附近的“{selector}”在材质/滤镜层上给小字使用弱色，读不清风险高。"
            )
    return findings


def button_feedback_findings(buttons: list[tuple[int, str, dict[str, str]]], css_text: str) -> list[str]:
    findings: list[str] = []
    missing: list[str] = []
    for _line, text, attrs in buttons:
        if "disabled" in attrs:
            continue
        if has_active_feedback_style(css_text, attrs):
            continue
        class_name = attrs.get("class", "").strip() or "<button>"
        missing.append(f"{text or '未命名按钮'} ({class_name})")
    if missing:
        preview = ", ".join(missing[:4])
        findings.append(f"BLOCK button-active   以下按钮缺少明确按下/选中反馈样式：{preview}")
    return findings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Runtime HTML inspection for ui-polish review.")
    parser.add_argument("--url", help="URL to inspect.")
    parser.add_argument("--file", help="Local HTML file to inspect.")
    parser.add_argument("--visual-reviewed", action="store_true", help="Mark that a required screenshot review was completed.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    html = load_html(args.url, args.file)
    parser = RuntimeInspector()
    parser.feed(html)
    css_text = ""
    if args.file:
      html_path = Path(args.file).expanduser().resolve()
      css_text = load_local_css_bundle(html_path, parser.stylesheets)

    findings: list[str] = []

    short_headings = [item for item in parser.headings if len(item[2]) <= 12]
    heading_counter = Counter(text for _, _, text in short_headings)
    repeated_headings = [text for text, count in heading_counter.items() if count > 1]
    if len(parser.headings) >= 5:
        findings.append(f"WARN  heading-density   标题总数 {len(parser.headings)}，检查是否存在冗余小标题。")
    if repeated_headings:
        findings.append(f"BLOCK repeated-heading 检测到重复短标题：{', '.join(repeated_headings[:5])}")

    button_counter = Counter(text for _, text, _ in parser.buttons)
    repeated_buttons = [text for text, count in button_counter.items() if count > 1]
    if repeated_buttons:
        findings.append(f"BLOCK repeated-button  检测到重复按钮文案：{', '.join(repeated_buttons[:5])}")
    if len(parser.buttons) >= 5:
        findings.append(f"WARN  action-density   按钮数量 {len(parser.buttons)}，检查是否存在同层重复操作。")
    if parser.buttons and not any(
        any(key in attrs for key in ("disabled", "aria-busy", "data-loading", "data-state")) for _, _, attrs in parser.buttons
    ):
        findings.append("WARN  button-feedback  DOM 未看到 disabled / aria-busy / data-state 等反馈痕迹。")
    findings.extend(button_feedback_findings(parser.buttons, css_text))
    findings.extend(readability_findings(css_text))

    if parser.max_generic_depth >= 8:
        findings.append(f"BLOCK container-depth  通用容器深度达到 {parser.max_generic_depth}，疑似存在无意义套娃。")
    elif parser.max_generic_depth >= 6:
        findings.append(f"WARN  container-depth  通用容器深度达到 {parser.max_generic_depth}，建议检查是否能减层。")

    if parser.generic_count >= 20 and parser.buttons and len(parser.headings) <= 3:
        findings.append("WARN  wrapper-volume   容器数量偏多，检查是否有多余外框/内框。")

    for _, _, text in parser.headings:
        if any(word in text for word in SMELL_WORDS):
            findings.append(f"WARN  heading-copy     标题“{text}”可能偏 AI 味或系统视角。")
        if any(label in text.lower() for label in EXPLANATORY_LABELS):
            findings.append(f"BLOCK heading-copy    标题“{text}”偏解释型/系统视角，需改成任务表达。")

    for _, line_no, text in parser.labelish_texts:
        if any(label in text.lower() for label in EXPLANATORY_LABELS):
            findings.append(f"BLOCK label-copy      第 {line_no} 行附近的标签“{text}”偏解释型/系统视角，需删除或改成任务表达。")

    if needs_visual_review(html, css_text) and not args.visual_reviewed:
        findings.append("BLOCK visual-review   命中玻璃/材质/图表等高视觉风险场景，必须先截图复审，再以 --visual-reviewed 复跑。")

    if not findings:
        print("PASS runtime inspection: no heuristic issues found.")
        return 0

    for item in findings:
        print(item)
    blocks = sum(1 for item in findings if item.startswith("BLOCK"))
    warns = sum(1 for item in findings if item.startswith("WARN"))
    print(f"\nSummary: {blocks} block(s), {warns} warning(s)")
    return 1 if blocks else 0


if __name__ == "__main__":
    sys.exit(main())
