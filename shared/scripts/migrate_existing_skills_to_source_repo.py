#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path


CURRENT_REPO_ROOT = Path("/Users/zhangyufan/.agents/skills")
DEFAULT_SOURCE_ROOT = Path("/Users/zhangyufan/Workspace/skills-central")
CORE_SKILLS = {
    "agent-rules-sync",
    "create-skill",
    "doctor-skills",
    "install-skill",
    "skill-security-guard",
    "uninstall-skill",
    "update-skill",
}
SKIP_DIRS = {
    ".git",
    ".github",
    "docs",
    "shared",
}


def safe_rmtree(path: Path) -> None:
    if path.exists() or path.is_symlink():
        shutil.rmtree(path)


def safe_copytree(src: Path, dst: Path) -> None:
    safe_rmtree(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, dst, ignore=shutil.ignore_patterns("__pycache__", ".DS_Store", "*.pyc", ".git"))


def load_metadata(skill_dir: Path) -> dict:
    meta_file = skill_dir / ".skill-source.json"
    if not meta_file.is_file():
        return {}
    try:
        return json.loads(meta_file.read_text(encoding="utf-8"))
    except Exception:
        return {}


def sanitize_group(raw: str) -> str:
    raw = raw.strip()
    raw = raw.replace("https://github.com/", "")
    raw = raw.replace("http://github.com/", "")
    raw = raw.replace("git@github.com:", "")
    raw = raw.rstrip("/")
    raw = raw.removesuffix(".git")
    raw = raw.replace("/", "__")
    raw = re.sub(r"[^A-Za-z0-9._-]+", "-", raw)
    return raw or "unknown-source"


def clean_source_path(raw: str, fallback: str) -> Path:
    value = (raw or fallback).strip()
    value = value.lstrip("./")
    return Path(value or fallback)


def find_skill_dirs(repo_root: Path) -> list[Path]:
    skill_dirs: list[Path] = []
    for entry in sorted(repo_root.iterdir()):
        if not entry.is_dir():
            continue
        if entry.name in SKIP_DIRS:
            continue
        if (entry / "SKILL.md").is_file():
            skill_dirs.append(entry)
    return skill_dirs


def classify_target(skill_dir: Path) -> Path:
    metadata = load_metadata(skill_dir)
    source = str(metadata.get("source") or "").strip()

    if skill_dir.name in CORE_SKILLS:
        return Path("packages/core") / skill_dir.name

    if source == "community":
        update_group = str(metadata.get("update_group") or metadata.get("source_repo") or metadata.get("package_name") or skill_dir.name)
        source_path = clean_source_path(str(metadata.get("source_path") or ""), skill_dir.name)
        return Path("packages/community") / sanitize_group(update_group) / source_path

    return Path("packages/custom") / skill_dir.name


def main() -> int:
    source_root = DEFAULT_SOURCE_ROOT
    source_root.mkdir(parents=True, exist_ok=True)
    (source_root / "packages/core").mkdir(parents=True, exist_ok=True)
    (source_root / "packages/custom").mkdir(parents=True, exist_ok=True)
    (source_root / "packages/community").mkdir(parents=True, exist_ok=True)

    copied: list[tuple[str, Path]] = []
    for rel_dir in ("docs", "shared"):
        src = CURRENT_REPO_ROOT / rel_dir
        dst = source_root / rel_dir
        if src.is_dir():
            safe_copytree(src, dst)

    for skill_dir in find_skill_dirs(CURRENT_REPO_ROOT):
        rel_target = classify_target(skill_dir)
        target = source_root / rel_target
        safe_copytree(skill_dir, target)
        copied.append((skill_dir.name, rel_target))

    print(f"migrated skills: {len(copied)}")
    for name, rel_target in copied:
        print(f"{name} -> {rel_target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
