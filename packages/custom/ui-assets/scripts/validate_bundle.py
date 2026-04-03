#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT_SKILL = "ui-polish"
EXPECTED_NON_ROOT = {
    "using-ui-polish",
    "ui-core",
    "ui-copy",
    "ui-feedback",
    "ui-review",
    "ui-web",
    "ui-mobile",
    "ui-mini",
    "ui-ext",
    "ui-desktop",
    "ui-pencil",
    "ui-assets",
}

LINK_RE = re.compile(r"`((?:\.\.?/)[^`\n]+)`")
FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.S)
NAME_RE = re.compile(r"^name:\s*(.+)$", re.M)
DESC_RE = re.compile(r"^description:\s*(.+)$", re.M)
DISABLE_RE = re.compile(r"^disable-model-invocation:\s*(.+)$", re.M)


@dataclass
class Finding:
    severity: str
    path: Path
    message: str

    def render(self) -> str:
        return f"{self.severity:<5} {self.path} {self.message}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate ui-polish bundle structure and cross-file links.")
    parser.add_argument(
        "--skills-root",
        default="~/.agents/skills",
        help="Skills root directory. Defaults to ~/.agents/skills",
    )
    return parser.parse_args()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def load_frontmatter(path: Path) -> tuple[str | None, str | None, str | None]:
    text = read_text(path)
    match = FRONTMATTER_RE.match(text)
    if not match:
        return None, None, None
    frontmatter = match.group(1)
    name = NAME_RE.search(frontmatter)
    desc = DESC_RE.search(frontmatter)
    disable = DISABLE_RE.search(frontmatter)
    return (
        name.group(1).strip() if name else None,
        desc.group(1).strip() if desc else None,
        disable.group(1).strip().lower() if disable else None,
    )


def validate_skill(skill_dir: Path, findings: list[Finding]) -> None:
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.exists():
        findings.append(Finding("BLOCK", skill_dir, "缺少 SKILL.md"))
        return

    name, description, disable = load_frontmatter(skill_file)
    if not name:
        findings.append(Finding("BLOCK", skill_file, "frontmatter 缺少 name"))
    if not description:
        findings.append(Finding("BLOCK", skill_file, "frontmatter 缺少 description"))

    if skill_dir.name == ROOT_SKILL:
        if disable == "true":
            findings.append(Finding("BLOCK", skill_file, "根入口 ui-polish 不应禁用自动触发"))
    elif skill_dir.name in EXPECTED_NON_ROOT and disable != "true":
        findings.append(Finding("WARN", skill_file, "子 skill 建议设置 disable-model-invocation: true"))

    text = read_text(skill_file)
    for link in LINK_RE.findall(text):
        target = (skill_file.parent / link).resolve()
        if not target.exists():
            findings.append(Finding("BLOCK", skill_file, f"引用不存在: {link}"))


def validate_reference_links(root_dirs: list[Path], findings: list[Finding]) -> None:
    for root in root_dirs:
        for path in root.rglob("*.md"):
            text = read_text(path)
            for link in LINK_RE.findall(text):
                target = (path.parent / link).resolve()
                if not target.exists():
                    findings.append(Finding("BLOCK", path, f"引用不存在: {link}"))


def main() -> int:
    args = parse_args()
    skills_root = Path(args.skills_root).expanduser().resolve()
    skill_dirs = [skills_root / ROOT_SKILL] + [skills_root / name for name in sorted(EXPECTED_NON_ROOT)]
    findings: list[Finding] = []

    for skill_dir in skill_dirs:
        if not skill_dir.exists():
            findings.append(Finding("BLOCK", skill_dir, "技能目录不存在"))
            continue
        validate_skill(skill_dir, findings)

    validate_reference_links(skill_dirs, findings)

    if not findings:
        print("PASS ui-polish bundle validation: structure and links look good.")
        return 0

    findings.sort(key=lambda item: (item.severity != "BLOCK", str(item.path), item.message))
    for finding in findings:
        print(finding.render())
    blocks = sum(1 for item in findings if item.severity == "BLOCK")
    warns = sum(1 for item in findings if item.severity == "WARN")
    print(f"\nSummary: {blocks} block(s), {warns} warning(s)")
    return 1 if blocks else 0


if __name__ == "__main__":
    sys.exit(main())
