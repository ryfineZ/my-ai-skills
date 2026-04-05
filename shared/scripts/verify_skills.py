#!/usr/bin/env python3
"""Single-process skills verifier for the central skills repository."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class ToolDir:
    path: Path
    platform_key: str
    label: str


@dataclass
class SkillRecord:
    name: str
    description: str
    skill_file: Path
    skill_dir: Path
    meta_file: Path
    meta_exists: bool
    meta_valid: bool
    meta_error: str | None
    has_embedded_git: bool
    source: str
    source_type: str
    source_repo: str
    update_group: str
    source_path: str
    bundle_root: str
    platform_policies: dict[str, Any]


FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---", re.DOTALL)
TOOL_DIRS_RELATIVE = [
    (".claude/skills", "claude_code", "~/.claude/skills"),
    (".codex/skills", "codex", "~/.codex/skills"),
    (".cursor/skills", "cursor", "~/.cursor/skills"),
    (".gemini/skills", "gemini", "~/.gemini/skills"),
    (".antigravity/skills", "antigravity", "~/.antigravity/skills"),
    (".gemini/antigravity/skills", "antigravity", "~/.gemini/antigravity/skills"),
    (".windsurf/skills", "windsurf", "~/.windsurf/skills"),
    (".cline/skills", "cline", "~/.cline/skills"),
    (".goose/skills", "goose", "~/.goose/skills"),
]


class Verifier:
    def __init__(self, *, skills_dir: Path, agents_skills_dir: Path, source_skills_dir: Path | None) -> None:
        self.skills_dir = skills_dir
        self.agents_skills_dir = agents_skills_dir
        self.source_skills_dir = source_skills_dir
        self.tool_dirs = [
            ToolDir(path=(Path.home() / rel), platform_key=platform_key, label=label)
            for rel, platform_key, label in TOOL_DIRS_RELATIVE
        ]
        self.errors = 0
        self.warnings = 0
        self.issues: list[dict[str, str]] = []
        self.logs: list[str] = []

    def log(self, line: str = "") -> None:
        self.logs.append(line)

    def add_issue(self, severity: str, issue_type: str, path: Path | str, detail: str) -> None:
        if severity == "error":
            self.errors += 1
        else:
            self.warnings += 1
        self.issues.append(
            {
                "severity": severity,
                "type": issue_type,
                "path": str(path),
                "detail": detail.replace("\n", " "),
            }
        )
        prefix = "❌" if severity == "error" else "⚠️ "
        self.log(f"{prefix} {detail}")

    @staticmethod
    def resolve_dir(path: Path) -> str | None:
        try:
            return str(path.expanduser().resolve(strict=True))
        except FileNotFoundError:
            return None
        except OSError:
            return None

    @staticmethod
    def find_repo_root(start: Path) -> Path | None:
        current = start.expanduser().resolve()
        if current.is_file():
            current = current.parent
        for candidate in (current, *current.parents):
            if (candidate / "shared/scripts").is_dir() and (candidate / "packages").is_dir():
                return candidate
        return None

    @staticmethod
    def parse_frontmatter(path: Path) -> tuple[str | None, str | None]:
        try:
            content = path.read_text(encoding="utf-8")
        except Exception:
            return None, None
        match = FRONTMATTER_RE.match(content)
        if not match:
            return None, None
        data: dict[str, str] = {}
        for raw_line in match.group(1).splitlines():
            line = raw_line.strip()
            if not line or ":" not in line:
                continue
            key, value = line.split(":", 1)
            data[key.strip().lower()] = value.strip().strip('"').strip("'")
        return data.get("name"), data.get("description")

    @staticmethod
    def load_skill_meta(meta_file: Path) -> tuple[bool, bool, str | None, dict[str, Any]]:
        if not meta_file.is_file():
            return False, True, None, {}
        try:
            raw = json.loads(meta_file.read_text(encoding="utf-8"))
        except Exception as exc:
            return True, False, str(exc), {}
        return True, isinstance(raw, dict), None if isinstance(raw, dict) else "metadata is not an object", raw if isinstance(raw, dict) else {}

    def discover_skill_files(self) -> list[Path]:
        if self.source_skills_dir and (self.source_skills_dir / "packages").is_dir():
            return sorted((self.source_skills_dir / "packages").rglob("SKILL.md"))
        if self.source_skills_dir and self.source_skills_dir.is_dir():
            if self.source_skills_dir.resolve() == self.skills_dir.resolve():
                entries: list[Path] = []
                for child in sorted(self.source_skills_dir.iterdir(), key=lambda p: p.name):
                    if not (child.is_dir() or child.is_symlink()):
                        continue
                    skill_file = child / "SKILL.md"
                    if skill_file.is_file():
                        entries.append(skill_file)
                return entries
            return sorted(self.source_skills_dir.rglob("SKILL.md"))
        if self.skills_dir.is_dir():
            entries = []
            for child in sorted(self.skills_dir.iterdir(), key=lambda p: p.name):
                if not (child.is_dir() or child.is_symlink()):
                    continue
                skill_file = child / "SKILL.md"
                if skill_file.is_file():
                    entries.append(skill_file)
            return entries
        return []

    def load_skills(self) -> list[SkillRecord]:
        records: list[SkillRecord] = []
        for skill_file in self.discover_skill_files():
            skill_dir = skill_file.parent
            fallback_name = skill_dir.name
            skill_name, description = self.parse_frontmatter(skill_file)
            meta_file = skill_dir / ".skill-source.json"
            meta_exists, meta_valid, meta_error, meta = self.load_skill_meta(meta_file)
            policies = meta.get("platform_policies") if isinstance(meta.get("platform_policies"), dict) else {}
            records.append(
                SkillRecord(
                    name=skill_name or fallback_name,
                    description=description or "无描述",
                    skill_file=skill_file,
                    skill_dir=skill_dir,
                    meta_file=meta_file,
                    meta_exists=meta_exists,
                    meta_valid=meta_valid,
                    meta_error=meta_error,
                    has_embedded_git=(skill_dir / ".git").exists(),
                    source=str(meta.get("source") or "").strip(),
                    source_type=str(meta.get("source_type") or "").strip(),
                    source_repo=str(meta.get("source_repo") or "").strip(),
                    update_group=str(meta.get("update_group") or "").strip(),
                    source_path=str(meta.get("source_path") or "").strip(),
                    bundle_root=str(meta.get("bundle_root") or "").strip(),
                    platform_policies=policies,
                )
            )
        return records

    def should_expect_tool_link(self, skill: SkillRecord, platform_key: str) -> bool:
        platform = skill.platform_policies.get(platform_key)
        if not isinstance(platform, dict):
            return True
        return platform.get("publish") is not False

    def is_managed_symlink(self, link_path: Path) -> bool:
        if link_path.parent == self.agents_skills_dir:
            return True
        try:
            target = os.readlink(link_path)
        except OSError:
            target = ""
        agents_prefix = f"{self.agents_skills_dir}{os.sep}"
        if target.startswith(agents_prefix) or ".agents/skills/" in target:
            return True
        resolved = self.resolve_dir(link_path)
        return bool(resolved and resolved.startswith(agents_prefix))

    def check_stale_links(self, directory: Path, label: str, expected_names: set[str]) -> None:
        if not directory.is_dir():
            return
        for entry in sorted(directory.iterdir(), key=lambda p: p.name):
            if not entry.is_symlink():
                continue
            if entry.name in expected_names:
                if not entry.exists():
                    self.add_issue("warning", "broken_link", entry, f"{label} 中存在损坏链接: {entry}")
                continue
            if not self.is_managed_symlink(entry):
                continue
            self.add_issue("warning", "stale_link", entry, f"{label} 中存在过期链接: {entry}")

    def verify(self) -> dict[str, Any]:
        self.log("🔍 验证 AI Skills 配置...")
        self.log()

        configured_skills_dir = self.skills_dir
        skills_dir_real = self.resolve_dir(self.skills_dir)
        if skills_dir_real:
            self.skills_dir = Path(skills_dir_real)
            self.log(f"✅ 中央仓库: {self.skills_dir}")
            if str(configured_skills_dir) != skills_dir_real:
                self.log(f"   (配置路径: {configured_skills_dir})")
        else:
            self.add_issue("error", "missing_skills_dir", configured_skills_dir, f"中央仓库不存在: {configured_skills_dir}")

        if self.source_skills_dir is not None:
            self.log()
            self.log("🧭 源码层状态：")
            configured_source = self.source_skills_dir
            source_real = self.resolve_dir(self.source_skills_dir)
            if source_real:
                self.source_skills_dir = Path(source_real)
                self.log(f"✅ Source Skills 目录: {self.source_skills_dir}")
                if str(configured_source) != source_real:
                    self.log(f"   (配置路径: {configured_source})")
            else:
                self.add_issue("error", "missing_source_skills_dir", configured_source, f"Source Skills 目录不存在: {configured_source}")

        skills = self.load_skills() if self.skills_dir.is_dir() else []
        skill_names = {skill.name for skill in skills}
        self.log(f"   Skills 数量: {len(skills)}")

        self.log()
        self.log(f"🔗 {self.agents_skills_dir} 状态：")
        agents_real: str | None = None
        if self.agents_skills_dir.is_symlink():
            self.add_issue("warning", "agents_dir_is_symlink", self.agents_skills_dir, f"{self.agents_skills_dir} 是软链接（建议改为目录以匹配 npx skills add 行为）")
        elif self.agents_skills_dir.is_dir():
            self.log(f"✅ {self.agents_skills_dir} (目录)")
            agents_real = self.resolve_dir(self.agents_skills_dir)
        else:
            self.add_issue("error", "missing_agents_dir", self.agents_skills_dir, f"{self.agents_skills_dir} 不存在")

        self.log()
        self.log("🔗 工具链接状态：")
        for tool_dir in self.tool_dirs:
            if tool_dir.path.is_symlink():
                self.add_issue("warning", "tool_dir_is_symlink", tool_dir.path, f"{tool_dir.path} 是软链接（建议使用 per-skill 目录）")
            elif tool_dir.path.is_dir():
                self.log(f"✅ {tool_dir.path} (目录)")
            elif tool_dir.path.exists():
                self.add_issue("warning", "tool_dir_not_directory", tool_dir.path, f"{tool_dir.path} 存在但不是目录")
            else:
                self.log(f"ℹ️  {tool_dir.path} (不存在，可忽略)")

        self.log()
        self.log("📋 可用 Skills：")
        for skill in skills:
            self.log(f"  - {skill.name}: {skill.description}")

            agents_entry = self.agents_skills_dir / skill.name
            if agents_real and self.skills_dir == Path(agents_real):
                if agents_entry.is_dir():
                    pass
                elif agents_entry.exists() or agents_entry.is_symlink():
                    self.add_issue("warning", "invalid_agents_entry", agents_entry, f"中央目录条目异常：{agents_entry} 不是目录")
                else:
                    self.add_issue("error", "missing_agents_entry", agents_entry, f"缺少中央目录条目：{agents_entry}")
            elif agents_entry.is_symlink():
                expected_real = self.resolve_dir(skill.skill_dir)
                actual_real = self.resolve_dir(agents_entry)
                if not actual_real or actual_real != expected_real:
                    self.add_issue("warning", "agents_link_mismatch", agents_entry, f"中央目录链接指向异常：{agents_entry}")
            elif agents_entry.exists():
                self.add_issue("warning", "agents_entry_not_symlink", agents_entry, f"{agents_entry} 不是软链接")
            else:
                self.add_issue("error", "missing_agents_entry", agents_entry, f"缺少中央目录条目：{agents_entry}")

            for tool_dir in self.tool_dirs:
                tool_entry = tool_dir.path / skill.name
                if not self.should_expect_tool_link(skill, tool_dir.platform_key):
                    if tool_entry.exists() or tool_entry.is_symlink():
                        self.add_issue("warning", "unexpected_tool_link", tool_entry, f"该平台不应发布但仍存在链接：{tool_entry}")
                    continue
                if tool_entry.is_symlink():
                    if not tool_entry.exists():
                        self.add_issue("warning", "broken_tool_link", tool_entry, f"损坏链接：{tool_entry}")
                elif tool_entry.exists():
                    self.add_issue("warning", "tool_entry_not_symlink", tool_entry, f"{tool_entry} 不是软链接")
                elif tool_dir.path.is_dir():
                    self.add_issue("error", "missing_tool_link", tool_entry, f"缺少工具链接：{tool_entry}")

        self.check_stale_links(self.agents_skills_dir, "~/.agents/skills", skill_names)
        for tool_dir in self.tool_dirs:
            self.check_stale_links(tool_dir.path, tool_dir.label, skill_names)

        status = "OK"
        if self.errors > 0:
            status = "ERROR"
        elif self.warnings > 0:
            status = "WARN"

        result = {
            "generated_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
            "status": status,
            "skills_dir": str(self.skills_dir),
            "agents_skills_dir": str(self.agents_skills_dir),
            "source_skills_dir": str(self.source_skills_dir) if self.source_skills_dir else None,
            "skills_count": len(skills),
            "counts": {"errors": self.errors, "warnings": self.warnings},
            "skills": [
                {
                    "name": skill.name,
                    "description": skill.description,
                    "skill_file": str(skill.skill_file),
                    "skill_dir": str(skill.skill_dir),
                    "meta_file": str(skill.meta_file),
                    "meta_exists": skill.meta_exists,
                    "meta_valid": skill.meta_valid,
                    "meta_error": skill.meta_error,
                    "has_embedded_git": skill.has_embedded_git,
                    "source": skill.source,
                    "source_type": skill.source_type,
                    "source_repo": skill.source_repo,
                    "update_group": skill.update_group,
                    "source_path": skill.source_path,
                    "bundle_root": skill.bundle_root,
                    "published_platforms": sorted(
                        tool.platform_key
                        for tool in self.tool_dirs
                        if self.should_expect_tool_link(skill, tool.platform_key)
                    ),
                }
                for skill in skills
            ],
            "issues": self.issues,
        }
        return result


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Verify central skills repository state.")
    parser.add_argument("--json", action="store_true", dest="json_stdout", help="输出 JSON 到 stdout")
    parser.add_argument("--json-out", dest="json_out", help="将 JSON 结果写入文件")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    script_dir = Path(__file__).resolve().parent
    repo_root = Verifier.find_repo_root(script_dir)

    skills_dir = Path(os.environ.get("SKILLS_DIR", str(Path.home() / ".agents/skills"))).expanduser()
    source_env = os.environ.get("SOURCE_SKILLS_DIR")
    if source_env:
        source_skills_dir = Path(source_env).expanduser()
    elif repo_root:
        source_skills_dir = repo_root
    else:
        source_skills_dir = None

    verifier = Verifier(
        skills_dir=skills_dir,
        agents_skills_dir=(Path.home() / ".agents/skills"),
        source_skills_dir=source_skills_dir,
    )
    result = verifier.verify()

    if args.json_out:
        Path(args.json_out).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if args.json_stdout:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for line in verifier.logs:
            print(line)
        if args.json_out:
            print()
            print(f"📄 JSON 报告: {args.json_out}")
        print()
        print(f"📊 检查结果：errors={result['counts']['errors']} warnings={result['counts']['warnings']}")
        print("✅ 验证完成！" if result["counts"]["errors"] == 0 else "❌ 验证完成（存在错误）")

    return 1 if result["counts"]["errors"] > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
