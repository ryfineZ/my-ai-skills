#!/bin/bash
# generate-claude-plugin-recommendations.sh - 生成 Claude Code 插件安装说明文档

set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
DOC_PATH="${DOC_PATH:-$SKILLS_DIR/docs/architecture/claude-plugin-recommendations.md}"

if [[ -f "$SKILLS_DIR/.skillsrc" ]]; then
    # shellcheck disable=SC1090
    source "$SKILLS_DIR/.skillsrc"
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "❌ 中央仓库不存在: $SKILLS_DIR" >&2
    exit 1
fi

mkdir -p "$(dirname "$DOC_PATH")"

python3 - "$SKILLS_DIR" "$DOC_PATH" <<'PY'
import json
import re
import sys
from collections import OrderedDict
from datetime import datetime
from pathlib import Path

skills_dir = Path(sys.argv[1]).expanduser().resolve()
doc_path = Path(sys.argv[2]).expanduser()
search_root = skills_dir / "packages" if (skills_dir / "packages").is_dir() else skills_dir


def extract_skill_name(skill_dir: Path) -> str:
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.is_file():
        return skill_dir.name
    try:
        content = skill_file.read_text(encoding="utf-8")
    except Exception:
        return skill_dir.name
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    frontmatter = match.group(1) if match else ""
    for raw_line in frontmatter.splitlines():
        line = raw_line.strip()
        if not line or ":" not in line:
            continue
        key, value = line.split(":", 1)
        if key.strip().lower() == "name":
            name = value.strip().strip('"').strip("'")
            if name:
                return name
    return skill_dir.name


groups: "OrderedDict[str, dict]" = OrderedDict()

for entry in sorted(search_root.rglob("*"), key=lambda item: str(item)):
    if not entry.is_dir():
        continue
    skill_file = entry / "SKILL.md"
    meta_file = entry / ".skill-source.json"
    if not skill_file.is_file() or not meta_file.is_file():
        continue
    try:
        data = json.loads(meta_file.read_text(encoding="utf-8"))
    except Exception:
        continue

    policies = data.get("platform_policies") or {}
    if not isinstance(policies, dict):
        policies = {}
    claude = policies.get("claude_code") or {}
    if not isinstance(claude, dict):
        claude = {}

    publish = claude.get("publish")
    install_mode = str(claude.get("install") or "").strip()
    if publish is not False and install_mode != "plugin":
        continue

    skill_name = extract_skill_name(entry)
    package_name = str(data.get("package_name") or "").strip()
    plugin_name = str(claude.get("plugin_name") or "").strip()
    source_repo = str(data.get("source_repo") or "").strip()
    update_group = str(data.get("update_group") or "").strip()
    install_hint = str(claude.get("install_hint") or "").strip()
    plugin_marketplace = str(claude.get("plugin_marketplace") or "").strip()
    plugin_marketplace_source = str(claude.get("plugin_marketplace_source") or "").strip()
    reason = "官方建议通过 Claude Code 插件安装，中央仓库不发布到 ~/.claude/skills"

    group_key = plugin_name or package_name or update_group or source_repo or skill_name
    record = groups.setdefault(
        group_key,
        {
            "package_name": package_name or group_key,
            "plugin_name": plugin_name or package_name or group_key,
            "source_repo": source_repo,
            "install_mode": install_mode or "plugin",
            "install_hint": install_hint,
            "plugin_marketplace": plugin_marketplace,
            "plugin_marketplace_source": plugin_marketplace_source,
            "reason": reason,
            "skills": [],
        },
    )
    record["skills"].append(skill_name)
    if not record["source_repo"] and source_repo:
        record["source_repo"] = source_repo
    if not record["install_hint"] and install_hint:
        record["install_hint"] = install_hint
    if not record["plugin_marketplace"] and plugin_marketplace:
        record["plugin_marketplace"] = plugin_marketplace
    if not record["plugin_marketplace_source"] and plugin_marketplace_source:
        record["plugin_marketplace_source"] = plugin_marketplace_source

lines = [
    "# Claude Code 插件安装说明",
    "",
    "> 本文档由 `shared/scripts/generate-claude-plugin-recommendations.sh` 自动生成。",
    f"> 最后更新：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
    "",
]

if not groups:
    lines.extend(
        [
            "当前没有检测到需要以 Claude Code 插件方式安装的 skill 包。",
            "",
            "说明：只有当某个 skill 的 `.skill-source.json` 中明确标记了",
            "`platform_policies.claude_code.publish=false` 或 `install=plugin` 时，才会出现在这里。",
            "",
        ]
    )
else:
    lines.extend(
        [
            "以下 skill 包不会发布到 `~/.claude/skills`，以避免与 Claude Code 官方插件能力重复暴露。",
            "当本机存在可用的 Claude CLI 和 `~/.claude` 环境时，中央仓库全局安装流程会自动尝试完成插件安装 / 启用。",
            "",
        ]
    )
    for group_name, item in groups.items():
        skills = ", ".join(sorted(set(item["skills"])))
        lines.extend(
            [
                f"## {item['package_name']}",
                "",
                f"- **插件名：** `{item['plugin_name']}`",
                f"- **来源仓库：** {item['source_repo'] or '（未记录）'}",
                f"- **安装方式：** `{item['install_mode']}`",
                f"- **原因：** {item['reason']}",
                f"- **涉及 skills：** {skills or '（未记录）'}",
            ]
        )
        if item["plugin_marketplace"]:
            lines.append(f"- **插件市场：** `{item['plugin_marketplace']}`")
        if item["plugin_marketplace_source"]:
            lines.append(f"- **插件市场来源：** `{item['plugin_marketplace_source']}`")
        if item["install_hint"]:
            lines.append(f"- **目标命令：** `{item['install_hint']}`")
        lines.extend(["", "---", ""])

doc_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY

echo "📝 已生成 Claude 插件建议文档: $DOC_PATH"
