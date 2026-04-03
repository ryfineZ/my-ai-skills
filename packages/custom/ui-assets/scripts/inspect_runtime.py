#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
import urllib.request
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path


HEADING_TAGS = {"h1", "h2", "h3", "h4", "h5", "h6"}
GENERIC_TAGS = {"div", "section"}
BUTTON_TAGS = {"button"}
TEXT_CAPTURE_TAGS = HEADING_TAGS | BUTTON_TAGS | {"a", "label"}
SMELL_WORDS = ("智能", "高效", "一站式", "在这里", "用于", "当前账号", "账号池")


class RuntimeInspector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[tuple[str, dict[str, str], int]] = []
        self.capture_stack: list[tuple[str, int, list[str]]] = []
        self.headings: list[tuple[str, int, str]] = []
        self.buttons: list[tuple[int, str, dict[str, str]]] = []
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

    def handle_data(self, data: str) -> None:
        if self.capture_stack:
            self.capture_stack[-1][2].append(data)

    def handle_endtag(self, tag: str) -> None:
        if self.capture_stack and self.capture_stack[-1][0] == tag:
            capture_tag, line_no, parts = self.capture_stack.pop()
            text = " ".join(part.strip() for part in parts if part.strip()).strip()
            if capture_tag in HEADING_TAGS and text:
                self.headings.append((capture_tag, line_no, text))
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Runtime HTML inspection for ui-polish review.")
    parser.add_argument("--url", help="URL to inspect.")
    parser.add_argument("--file", help="Local HTML file to inspect.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    html = load_html(args.url, args.file)
    parser = RuntimeInspector()
    parser.feed(html)

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

    if parser.max_generic_depth >= 8:
        findings.append(f"BLOCK container-depth  通用容器深度达到 {parser.max_generic_depth}，疑似存在无意义套娃。")
    elif parser.max_generic_depth >= 6:
        findings.append(f"WARN  container-depth  通用容器深度达到 {parser.max_generic_depth}，建议检查是否能减层。")

    if parser.generic_count >= 20 and parser.buttons and len(parser.headings) <= 3:
        findings.append("WARN  wrapper-volume   容器数量偏多，检查是否有多余外框/内框。")

    for _, _, text in parser.headings:
        if any(word in text for word in SMELL_WORDS):
            findings.append(f"WARN  heading-copy     标题“{text}”可能偏 AI 味或系统视角。")

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
