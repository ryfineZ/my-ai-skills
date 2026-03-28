#!/usr/bin/env python3
"""Normalize existing .skill-source.json files to the current central-repo schema."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def derive_package_name(repo: str) -> str:
    repo = repo.rstrip("/")
    repo = repo.removeprefix("https://github.com/")
    repo = repo.removeprefix("http://github.com/")
    repo = repo.removeprefix("git@github.com:")
    repo = repo.removesuffix(".git")
    return repo.split("/")[-1] if repo else ""


def normalize_skill_meta(skill_dir: Path, write: bool) -> tuple[bool, list[str]]:
    meta_path = skill_dir / ".skill-source.json"
    if not meta_path.is_file():
        return False, []

    try:
        data = json.loads(meta_path.read_text(encoding="utf-8"))
    except Exception:
        return False, []

    if not isinstance(data, dict):
        return False, []

    changed: list[str] = []
    source = str(data.get("source") or "").strip()
    source_type = str(data.get("source_type") or "").strip()
    source_repo = str(data.get("source_repo") or "").strip()

    if source == "custom" and not source_type:
        data["source_type"] = "custom"
        changed.append("source_type=custom")

    if source == "community" and source_repo:
        if not source_type:
            data["source_type"] = "single"
            source_type = "single"
            changed.append("source_type=single")
        if not data.get("package_name"):
            package_name = derive_package_name(source_repo)
            if package_name:
                data["package_name"] = package_name
                changed.append("package_name")
        if not data.get("install_mode"):
            data["install_mode"] = "flattened-copy"
            changed.append("install_mode")
        if not data.get("update_group"):
            data["update_group"] = source_repo
            changed.append("update_group")
        if source_type == "single" and not data.get("source_path"):
            data["source_path"] = skill_dir.name
            changed.append("source_path")
        if not isinstance(data.get("platform_policies"), dict):
            data["platform_policies"] = {}
            changed.append("platform_policies")

    if changed and write:
        meta_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    return bool(changed), changed


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalize .skill-source.json files")
    parser.add_argument("--skills-dir", default="~/.agents/skills", help="Central skills directory")
    parser.add_argument("--write", action="store_true", help="Write changes back to disk")
    args = parser.parse_args()

    skills_dir = Path(args.skills_dir).expanduser().resolve()
    if not skills_dir.is_dir():
        raise SystemExit(f"skills dir not found: {skills_dir}")

    changed_count = 0
    for entry in sorted(skills_dir.iterdir()):
        if not entry.is_dir():
            continue
        if not (entry / "SKILL.md").is_file():
            continue
        changed, fields = normalize_skill_meta(entry, args.write)
        if changed:
            changed_count += 1
            print(f"{entry.name}: {', '.join(fields)}")

    print(f"changed={changed_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
