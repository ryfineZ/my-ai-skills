#!/bin/bash
# doctor-skills - 诊断中央 skills 仓库状态，并可执行轻量修复

set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
VERIFY_SCRIPT="$SKILLS_DIR/shared/scripts/verify.sh"
INSTALL_SCRIPT="$SKILLS_DIR/shared/scripts/install.sh"
UPDATE_LIST_SCRIPT="$SKILLS_DIR/shared/scripts/update-skills-list.sh"

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
        SKILLS_DIR="$SKILLS_DIR" bash "$INSTALL_SCRIPT" >/dev/null
    fi
    if [[ -x "$UPDATE_LIST_SCRIPT" ]]; then
        SKILLS_DIR="$SKILLS_DIR" bash "$UPDATE_LIST_SCRIPT" >/dev/null
    fi
fi

VERIFY_JSON_FILE="$(mktemp)"
cleanup() {
    rm -f "$VERIFY_JSON_FILE"
}
trap cleanup EXIT

if [[ -x "$VERIFY_SCRIPT" ]]; then
    SKILLS_DIR="$SKILLS_DIR" bash "$VERIFY_SCRIPT" --json-out "$VERIFY_JSON_FILE" >/dev/null || true
else
    python3 - <<'PY' > "$VERIFY_JSON_FILE"
import json
print(json.dumps({"status": "ERROR", "counts": {"errors": 1, "warnings": 0}, "issues": [{"type": "missing_verify_script", "detail": "verify.sh 不存在"}]}, ensure_ascii=False))
PY
fi

python3 - "$SKILLS_DIR" "$VERIFY_JSON_FILE" "$JSON_OUTPUT" "$REPAIR" <<'PY'
import json
import re
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1]).expanduser().resolve()
verify_path = Path(sys.argv[2])
json_output = sys.argv[3].lower() == "true"
repair = sys.argv[4].lower() == "true"


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

for entry in sorted(skills_dir.iterdir()):
    if not entry.is_dir():
        continue
    skill_file = entry / "SKILL.md"
    if not skill_file.is_file():
        continue
    skill_name = extract_name(skill_file, entry.name)
    if entry.is_symlink():
        issues.append(
            {
                "severity": "error",
                "type": "skill_dir_is_symlink",
                "path": str(entry),
                "detail": f"顶层 skill 不应为软链接：{skill_name}",
            }
        )
        continue

    meta_file = entry / ".skill-source.json"
    if not meta_file.is_file():
        issues.append(
            {
                "severity": "warning",
                "type": "missing_skill_source_meta",
                "path": str(meta_file),
                "detail": f"缺少 .skill-source.json：{skill_name}",
            }
        )
        continue

    try:
        data = json.loads(meta_file.read_text(encoding="utf-8"))
    except Exception:
        issues.append(
            {
                "severity": "error",
                "type": "invalid_skill_source_meta",
                "path": str(meta_file),
                "detail": f".skill-source.json 无法解析：{skill_name}",
            }
        )
        continue

    source = str(data.get("source") or "").strip()
    source_type = str(data.get("source_type") or "").strip()
    source_repo = str(data.get("source_repo") or "").strip()
    update_group = str(data.get("update_group") or "").strip()
    source_path = str(data.get("source_path") or "").strip()
    bundle_root = str(data.get("bundle_root") or "").strip()

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
        issues.append(
            {
                "severity": "warning",
                "type": "missing_custom_source_type",
                "path": str(meta_file),
                "detail": f"自定义 skill 缺少 source_type=custom：{skill_name}",
            }
        )

error_count = sum(1 for item in issues if item.get("severity") == "error")
warning_count = sum(1 for item in issues if item.get("severity") != "error")
status = "OK" if error_count == 0 else "ERROR"

result = {
    "status": status,
    "skills_dir": str(skills_dir),
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
