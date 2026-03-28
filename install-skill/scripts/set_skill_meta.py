#!/usr/bin/env python3
"""Write AI-generated zh metadata into <skill_dir>/.skill-source.json."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
from typing import Any, Dict, List


def now_utc() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def clean_text(text: str) -> str:
    text = re.sub(r"\s+", " ", text or "")
    return text.strip()


def parse_keywords(raw: str) -> List[str]:
    items = re.split(r"[，,;；/|、]+", raw or "")
    out: List[str] = []
    for item in items:
        kw = clean_text(item).strip("。.;；")
        if not kw:
            continue
        if len(kw) > 24:
            continue
        if kw not in out:
            out.append(kw)
    return out[:10]


def load_json(path: str) -> Dict[str, Any]:
    if not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    return {}


def dump_json(path: str, data: Dict[str, Any]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Set AI-generated skill metadata")
    parser.add_argument("--skill-dir", required=True, help="Skill directory path")
    parser.add_argument("--usage-zh", required=True, help="Chinese purpose sentence")
    parser.add_argument(
        "--keywords",
        required=True,
        help="Trigger keywords, separated by comma/、/; etc.",
    )
    parser.add_argument("--repo", default="", help="Optional owner/repo source")
    parser.add_argument(
        "--generated-by",
        default="current-ai",
        help="Who generated metadata (default: current-ai)",
    )
    args = parser.parse_args()

    skill_dir = os.path.abspath(args.skill_dir)
    meta_path = os.path.join(skill_dir, ".skill-source.json")

    usage_zh = clean_text(args.usage_zh)
    keywords = parse_keywords(args.keywords)
    if not usage_zh:
        raise SystemExit("usage_zh 不能为空")
    if len(keywords) < 3:
        raise SystemExit("关键词至少需要 3 个")

    data = load_json(meta_path)
    ts = now_utc()
    if "source" not in data and args.repo:
        data["source"] = "community"
    if "source_type" not in data and args.repo:
        data["source_type"] = "single"
    if "package_name" not in data and args.repo:
        data["package_name"] = args.repo.rstrip("/").split("/")[-1]
    if args.repo:
        data["source_repo"] = args.repo
        data.setdefault("source_ref", "")
        data.setdefault("install_mode", "flattened-copy")
        data.setdefault("update_group", args.repo)
        data.setdefault("platform_policies", {})
    data["usage_zh"] = usage_zh
    data["trigger_keywords"] = keywords
    data["meta_generated_by"] = args.generated_by
    data["meta_generation"] = "current_ai"
    data["meta_language"] = "zh-CN"
    data["meta_updated_at"] = ts
    data["updated_at"] = ts

    dump_json(meta_path, data)
    print("✅ 已写入 AI 元数据")
    print(f"   用途: {usage_zh}")
    print(f"   触发关键词: {'、'.join(keywords)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
