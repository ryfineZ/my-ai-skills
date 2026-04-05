#!/bin/bash
# doctor-skills - 诊断中央 skills 仓库状态，并可执行轻量修复

set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

find_repo_root() {
    local current="$1"
    while [[ "$current" != "/" ]]; do
        if [[ -d "$current/shared/scripts" ]] && [[ -d "$current/packages" ]]; then
            printf '%s\n' "$current"
            return 0
        fi
        current="$(dirname "$current")"
    done
    return 1
}

REPO_ROOT="$(find_repo_root "$SCRIPT_DIR" || true)"
DEFAULT_SOURCE_SKILLS_DIR="$HOME/Workspace/skills-central"
if [[ -n "${SOURCE_SKILLS_DIR:-}" ]]; then
    SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR"
elif [[ -n "$REPO_ROOT" ]]; then
    SOURCE_SKILLS_DIR="$REPO_ROOT"
elif [[ -d "$DEFAULT_SOURCE_SKILLS_DIR/packages" ]]; then
    SOURCE_SKILLS_DIR="$DEFAULT_SOURCE_SKILLS_DIR"
else
    SOURCE_SKILLS_DIR="$SKILLS_DIR"
fi

TOOLS_ROOT="$SOURCE_SKILLS_DIR"
if [[ ! -d "$TOOLS_ROOT/shared/scripts" ]] && [[ -n "$REPO_ROOT" ]] && [[ -d "$REPO_ROOT/shared/scripts" ]]; then
    TOOLS_ROOT="$REPO_ROOT"
fi

VERIFY_SCRIPT="$TOOLS_ROOT/shared/scripts/verify.sh"
INSTALL_SCRIPT="$TOOLS_ROOT/shared/scripts/install.sh"
UPDATE_LIST_SCRIPT="$TOOLS_ROOT/shared/scripts/update-skills-list.sh"

JSON_OUTPUT=false
REPAIR=false

usage() {
    cat <<'EOF'
用法:
  doctor-skills.sh
  doctor-skills.sh --json
  doctor-skills.sh --repair
  doctor-skills.sh --repair --json

说明:
  - 默认执行诊断
  - --repair 会先执行轻量修复，再输出诊断结果
  - 轻量修复仅包括刷新平台链接和 INSTALLED_SKILLS.md
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --repair)
            REPAIR=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "❌ 未知参数: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "❌ 中央仓库不存在: $SKILLS_DIR" >&2
    exit 1
fi

if [[ "$REPAIR" == true ]]; then
    if [[ -x "$INSTALL_SCRIPT" ]]; then
        SKILLS_DIR="$SKILLS_DIR" SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR" bash "$INSTALL_SCRIPT" >/dev/null
    fi
    if [[ -x "$UPDATE_LIST_SCRIPT" ]]; then
        SKILLS_DIR="$SOURCE_SKILLS_DIR" SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR" bash "$UPDATE_LIST_SCRIPT" >/dev/null
    fi
fi

VERIFY_JSON_FILE="$(mktemp)"
cleanup() {
    rm -f "$VERIFY_JSON_FILE"
}
trap cleanup EXIT

if [[ -x "$VERIFY_SCRIPT" ]]; then
    SKILLS_DIR="$SKILLS_DIR" SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR" bash "$VERIFY_SCRIPT" --json-out "$VERIFY_JSON_FILE" >/dev/null || true
else
    python3 - <<'PY' > "$VERIFY_JSON_FILE"
import json
print(json.dumps({"status": "ERROR", "counts": {"errors": 1, "warnings": 0}, "issues": [{"type": "missing_verify_script", "detail": "verify.sh 不存在"}]}, ensure_ascii=False))
PY
fi

python3 - "$SKILLS_DIR" "$SOURCE_SKILLS_DIR" "$VERIFY_JSON_FILE" "$JSON_OUTPUT" "$REPAIR" <<'PY'
import json
import re
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1]).expanduser().resolve()
source_skills_dir = Path(sys.argv[2]).expanduser().resolve()
verify_path = Path(sys.argv[3])
json_output = sys.argv[4].lower() == "true"
repair = sys.argv[5].lower() == "true"


def extract_name(skill_file: Path, fallback: str) -> str:
    try:
        content = skill_file.read_text(encoding="utf-8")
    except Exception:
        return fallback
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    frontmatter = match.group(1) if match else ""
    for raw_line in frontmatter.splitlines():
        line = raw_line.strip()
        if not line or ":" not in line:
            continue
        key, value = line.split(":", 1)
        if key.strip().lower() == "name":
            return value.strip().strip('"').strip("'") or fallback
    return fallback


try:
    verify_data = json.loads(verify_path.read_text(encoding="utf-8"))
except Exception:
    verify_data = {
        "status": "ERROR",
        "counts": {"errors": 1, "warnings": 0},
        "issues": [{"type": "invalid_verify_json", "detail": "verify.sh 输出无法解析"}],
    }

issues = list(verify_data.get("issues") or [])
verify_skills = verify_data.get("skills")

if isinstance(verify_skills, list):
    skill_entries = []
    for raw in verify_skills:
        if not isinstance(raw, dict):
            continue
        skill_dir_value = raw.get("skill_dir")
        if not skill_dir_value:
            continue
        entry = Path(skill_dir_value)
        skill_name = raw.get("name") or entry.name
        skill_entries.append(
            {
                "entry": entry,
                "name": skill_name,
                "meta_file": Path(raw.get("meta_file") or (entry / ".skill-source.json")),
                "meta_exists": bool(raw.get("meta_exists")),
                "meta_valid": bool(raw.get("meta_valid", True)),
                "source": str(raw.get("source") or "").strip(),
                "source_type": str(raw.get("source_type") or "").strip(),
                "source_repo": str(raw.get("source_repo") or "").strip(),
                "update_group": str(raw.get("update_group") or "").strip(),
                "source_path": str(raw.get("source_path") or "").strip(),
                "bundle_root": str(raw.get("bundle_root") or "").strip(),
                "has_embedded_git": bool(raw.get("has_embedded_git")),
            }
        )
else:
    search_root = source_skills_dir / "packages" if (source_skills_dir / "packages").is_dir() else source_skills_dir
    skill_entries = []
    for skill_file in sorted(search_root.rglob("SKILL.md")):
        if not skill_file.is_file():
            continue
        entry = skill_file.parent
        skill_name = extract_name(skill_file, entry.name)
        meta_file = entry / ".skill-source.json"
        meta_exists = meta_file.is_file()
        data = {}
        meta_valid = True
        if meta_exists:
            try:
                data = json.loads(meta_file.read_text(encoding="utf-8"))
            except Exception:
                data = {}
                meta_valid = False
        skill_entries.append(
            {
                "entry": entry,
                "name": skill_name,
                "meta_file": meta_file,
                "meta_exists": meta_exists,
                "meta_valid": meta_valid,
                "source": str(data.get("source") or "").strip(),
                "source_type": str(data.get("source_type") or "").strip(),
                "source_repo": str(data.get("source_repo") or "").strip(),
                "update_group": str(data.get("update_group") or "").strip(),
                "source_path": str(data.get("source_path") or "").strip(),
                "bundle_root": str(data.get("bundle_root") or "").strip(),
                "has_embedded_git": (entry / ".git").exists(),
            }
        )

for skill in skill_entries:
    entry = skill["entry"]
    skill_name = skill["name"]
    meta_file = skill["meta_file"]

    if entry.is_symlink():
        issues.append(
            {
                "severity": "error",
                "type": "skill_dir_is_symlink",
                "path": str(entry),
                "detail": f"源码层 skill 不应为软链接：{skill_name}",
            }
        )
        continue

    if not skill["meta_exists"]:
        if skill["has_embedded_git"]:
            continue
        issues.append(
            {
                "severity": "warning",
                "type": "missing_skill_source_meta",
                "path": str(meta_file),
                "detail": f"缺少 .skill-source.json：{skill_name}",
            }
        )
        continue

    if not skill["meta_valid"]:
        issues.append(
            {
                "severity": "error",
                "type": "invalid_skill_source_meta",
                "path": str(meta_file),
                "detail": f".skill-source.json 无法解析：{skill_name}",
            }
        )
        continue

    source = skill["source"]
    source_type = skill["source_type"]
    source_repo = skill["source_repo"]
    update_group = skill["update_group"]
    source_path = skill["source_path"]
    bundle_root = skill["bundle_root"]

    if source != "custom":
        if not source_type:
            issues.append(
                {
                    "severity": "warning",
                    "type": "missing_source_type",
                    "path": str(meta_file),
                    "detail": f"缺少 source_type：{skill_name}",
                }
            )
        if not source_repo:
            issues.append(
                {
                    "severity": "warning",
                    "type": "missing_source_repo",
                    "path": str(meta_file),
                    "detail": f"缺少 source_repo：{skill_name}",
                }
            )
        if not update_group:
            issues.append(
                {
                    "severity": "warning",
                    "type": "missing_update_group",
                    "path": str(meta_file),
                    "detail": f"缺少 update_group：{skill_name}",
                }
            )

        if source_type == "bundle":
            if not source_path:
                issues.append(
                    {
                        "severity": "warning",
                        "type": "missing_bundle_source_path",
                        "path": str(meta_file),
                        "detail": f"bundle skill 缺少 source_path：{skill_name}",
                    }
                )
            if not bundle_root:
                issues.append(
                    {
                        "severity": "warning",
                        "type": "missing_bundle_root",
                        "path": str(meta_file),
                        "detail": f"bundle skill 缺少 bundle_root：{skill_name}",
                    }
                )

    if source == "custom" and not source_type:
        source_type = "custom"

error_count = sum(1 for item in issues if item.get("severity") == "error")
warning_count = sum(1 for item in issues if item.get("severity") != "error")
status = "OK" if error_count == 0 else "ERROR"

result = {
    "status": status,
    "skills_dir": str(skills_dir),
    "source_skills_dir": str(source_skills_dir),
    "repair": repair,
    "counts": {
        "errors": error_count,
        "warnings": warning_count,
    },
    "issues": issues,
}

if json_output:
    print(json.dumps(result, ensure_ascii=False, indent=2))
else:
    print("Skills Doctor 结果:")
    print(f"- 状态: {status}")
    print(f"- errors: {error_count}")
    print(f"- warnings: {warning_count}")
    if repair:
        print("- repair: 已执行轻量修复")
    if issues:
        print("")
        print("问题列表:")
        for item in issues:
            sev = item.get("severity", "warning").upper()
            typ = item.get("type", "unknown")
            detail = item.get("detail", "")
            print(f"- [{sev}] {typ}: {detail}")
    else:
        print("- 未发现问题")

sys.exit(0 if error_count == 0 else 1)
PY
