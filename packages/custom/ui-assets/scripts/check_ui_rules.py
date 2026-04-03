#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


TEXT_EXTENSIONS = {
    ".css",
    ".scss",
    ".less",
    ".html",
    ".htm",
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".vue",
    ".svelte",
}

IGNORE_PARTS = {
    "node_modules",
    ".git",
    "dist",
    "build",
    ".next",
    ".nuxt",
    "coverage",
}

HEX_RE = re.compile(r"#[0-9a-fA-F]{3,8}\b")
RGB_RE = re.compile(r"\brgba?\([^)]+\)")
HSL_RE = re.compile(r"\bhsla?\([^)]+\)")
BUTTON_RE = re.compile(r"(<button\b|<Button\b|\bbutton\s*[:=]|\bonClick=|\b@click=)", re.I)
STATE_HINT_RE = re.compile(
    r"(loading|pending|submitting|aria-busy|disabled|isLoading|isPending|data-loading|data-state|status)",
    re.I,
)
COPY_BAD_RE = re.compile(
    r"(在这里你可以|用于|帮助你更好|智能|高效|一站式|全方位|AI 驱动|提示词|当前账号|账号池)",
    re.I,
)
PALETTE_BAD_RE = re.compile(
    r"((blue|indigo|violet|purple).{0,40}(blue|indigo|violet|purple)|"
    r"(silver|gray|grey|mist|sage|mint|green).{0,40}(silver|gray|grey|mist|sage|mint|green)|"
    r"(蓝紫|紫白|银灰|雾绿))",
    re.I,
)
TOKEN_LINE_RE = re.compile(r"(--|token|theme|palette|semantic|surface|text-|accent|colors?\s*[:=])", re.I)
RAW_RADIUS_RE = re.compile(r"\b(border-radius|radius)\s*:\s*[0-9.]+(px|rem)")
RAW_SHADOW_RE = re.compile(r"\bbox-shadow\s*:\s*[^;]+")


@dataclass
class Finding:
    severity: str
    rule: str
    path: Path
    line_no: int
    message: str

    def render(self) -> str:
        return f"{self.severity:<7} {self.rule:<20} {self.path}:{self.line_no} {self.message}"


def iter_files(paths: Iterable[Path]) -> Iterable[Path]:
    for path in paths:
        if path.is_file():
            if path.suffix.lower() in TEXT_EXTENSIONS:
                yield path
            continue
        for child in path.rglob("*"):
            if not child.is_file():
                continue
            if any(part in IGNORE_PARTS for part in child.parts):
                continue
            if child.suffix.lower() in TEXT_EXTENSIONS:
                yield child


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="ignore")


def raw_literal_findings(path: Path, lines: list[str]) -> list[Finding]:
    findings: list[Finding] = []
    for idx, line in enumerate(lines, start=1):
        if TOKEN_LINE_RE.search(line):
            continue
        if HEX_RE.search(line) or RGB_RE.search(line) or HSL_RE.search(line):
            if re.search(r"(color|background|border|shadow|fill|stroke|outline|backdrop-filter|filter)", line, re.I):
                findings.append(
                    Finding("BLOCK", "raw-design-literal", path, idx, "原始颜色/视觉值未走 token。")
                )
        if RAW_RADIUS_RE.search(line):
            findings.append(Finding("WARN", "raw-radius", path, idx, "圆角直接写原始值，建议收进 token。"))
        if RAW_SHADOW_RE.search(line) and "var(" not in line and "none" not in line and "inherit" not in line:
            findings.append(Finding("WARN", "raw-shadow", path, idx, "阴影直接写原始值，建议收进 token。"))
    return findings


def palette_findings(path: Path, lines: list[str]) -> list[Finding]:
    findings: list[Finding] = []
    for idx, line in enumerate(lines, start=1):
        if PALETTE_BAD_RE.search(line):
            findings.append(
                Finding("BLOCK", "banned-palette", path, idx, "命中默认安全配色禁区，需人工确认并替换。")
            )
    return findings


def copy_findings(path: Path, lines: list[str]) -> list[Finding]:
    findings: list[Finding] = []
    for idx, line in enumerate(lines, start=1):
        if COPY_BAD_RE.search(line):
            findings.append(
                Finding("WARN", "copy-smell", path, idx, "文案可能偏自我解释、AI 味或重复命名。")
            )
    return findings


def button_findings(path: Path, text: str, lines: list[str]) -> list[Finding]:
    findings: list[Finding] = []
    if path.suffix.lower() in {".css", ".scss", ".less"}:
        return findings
    if not BUTTON_RE.search(text):
        return findings
    if not STATE_HINT_RE.search(text):
        findings.append(
            Finding("WARN", "button-feedback", path, 1, "检测到按钮/点击行为，但未看到 loading 或 disabled 等反馈线索。")
        )
    button_like_lines = [idx for idx, line in enumerate(lines, start=1) if BUTTON_RE.search(line)]
    if len(button_like_lines) >= 5:
        findings.append(
            Finding("WARN", "action-density", path, button_like_lines[0], "同一文件交互入口偏多，检查是否存在重复同权重按钮。")
        )
    return findings


def analyze_file(path: Path) -> list[Finding]:
    text = read_text(path)
    lines = text.splitlines()
    findings: list[Finding] = []
    findings.extend(raw_literal_findings(path, lines))
    findings.extend(palette_findings(path, lines))
    findings.extend(copy_findings(path, lines))
    findings.extend(button_findings(path, text, lines))
    return findings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Static heuristic checks for ui-polish hard rules.")
    parser.add_argument("paths", nargs="+", help="Files or directories to scan.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = [Path(p).expanduser().resolve() for p in args.paths]
    findings: list[Finding] = []
    for path in iter_files(paths):
        findings.extend(analyze_file(path))

    if not findings:
        print("PASS ui-polish static checks: no heuristic issues found.")
        return 0

    findings.sort(key=lambda item: (item.severity != "BLOCK", str(item.path), item.line_no, item.rule))
    for finding in findings:
        print(finding.render())

    blocks = sum(1 for item in findings if item.severity == "BLOCK")
    warns = sum(1 for item in findings if item.severity == "WARN")
    print(f"\nSummary: {blocks} block(s), {warns} warning(s)")
    return 1 if blocks else 0


if __name__ == "__main__":
    sys.exit(main())
