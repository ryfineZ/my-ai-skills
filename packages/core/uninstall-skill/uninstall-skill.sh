#!/bin/bash
# uninstall-skill - 从中央仓库删除已安装 skill，并刷新平台发布结果

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
if [[ -z "$REPO_ROOT" ]]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
fi
DEFAULT_SOURCE_SKILLS_DIR="$HOME/Workspace/skills-central"
if [[ -n "${SOURCE_SKILLS_DIR:-}" ]]; then
    SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR"
elif [[ -d "$DEFAULT_SOURCE_SKILLS_DIR/packages" ]] && find "$DEFAULT_SOURCE_SKILLS_DIR/packages" -type f -name SKILL.md | read -r _; then
    SOURCE_SKILLS_DIR="$DEFAULT_SOURCE_SKILLS_DIR"
else
    SOURCE_SKILLS_DIR="$SKILLS_DIR"
fi
INSTALL_SCRIPT="$REPO_ROOT/shared/scripts/install.sh"
UPDATE_LIST_SCRIPT="$REPO_ROOT/shared/scripts/update-skills-list.sh"

prune_empty_parents() {
    local path="$1"
    local stop_dir="$2"
    local current=""

    current="$(dirname "$path")"
    while [[ "$current" != "$stop_dir" && "$current" != "/" ]]; do
        if find "$current" -mindepth 1 -maxdepth 1 | read -r _; then
            break
        fi
        rmdir "$current"
        current="$(dirname "$current")"
    done
}

usage() {
    cat <<'EOF'
用法:
  uninstall-skill.sh --list
  uninstall-skill.sh --skill <skill-name>
  uninstall-skill.sh --group <update-group>

说明:
  - 只处理中央仓库顶层已安装 skill
  - 删除后会自动刷新平台链接和 INSTALLED_SKILLS.md
  - 对 bundle 更推荐按 update_group 整组删除
EOF
}

MODE=""
TARGET_SKILL=""
TARGET_GROUP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)
            MODE="list"
            shift
            ;;
        --skill)
            MODE="skill"
            TARGET_SKILL="${2:-}"
            shift 2
            ;;
        --group)
            MODE="group"
            TARGET_GROUP="${2:-}"
            shift 2
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

if [[ -z "$MODE" ]]; then
    usage
    exit 1
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "❌ 中央仓库不存在: $SKILLS_DIR" >&2
    exit 1
fi

collect_rows() {
    python3 - "$SOURCE_SKILLS_DIR" <<'PY'
import json
import re
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1]).expanduser().resolve()
search_root = skills_dir / "packages" if (skills_dir / "packages").is_dir() else skills_dir


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

for skill_file in sorted(search_root.rglob("SKILL.md")):
    if not skill_file.is_file():
        continue
    entry = skill_file.parent
    skill_name = extract_name(skill_file, entry.name)
    meta_file = entry / ".skill-source.json"
    source = ""
    source_type = ""
    source_repo = ""
    update_group = ""
    if meta_file.is_file():
        try:
            data = json.loads(meta_file.read_text(encoding="utf-8"))
        except Exception:
            data = {}
        source = str(data.get("source") or "").strip()
        source_type = str(data.get("source_type") or "").strip()
        source_repo = str(data.get("source_repo") or "").strip()
        update_group = str(data.get("update_group") or "").strip()
    print("\x1f".join([skill_name, str(entry), source, source_type, source_repo, update_group]))
PY
}

ROWS=()
while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    ROWS+=("$row")
done < <(collect_rows)

if [[ "${#ROWS[@]}" -eq 0 ]]; then
    echo "ℹ️  没有发现可处理的已安装 skill"
    exit 0
fi

if [[ "$MODE" == "list" ]]; then
    echo "已安装 skill:"
    for row in "${ROWS[@]}"; do
        IFS=$'\x1f' read -r skill_name skill_path source source_type source_repo update_group <<< "$row"
        printf ' - %s | source=%s | type=%s | group=%s\n' \
            "$skill_name" "${source:-unknown}" "${source_type:-unknown}" "${update_group:-}"
    done
    exit 0
fi

REMOVE_ROWS=()

case "$MODE" in
    skill)
        if [[ -z "$TARGET_SKILL" ]]; then
            echo "❌ --skill 需要 skill 名称" >&2
            exit 1
        fi
        for row in "${ROWS[@]}"; do
            IFS=$'\x1f' read -r skill_name _rest <<< "$row"
            if [[ "$skill_name" == "$TARGET_SKILL" ]]; then
                REMOVE_ROWS+=("$row")
                break
            fi
        done
        if [[ "${#REMOVE_ROWS[@]}" -eq 0 ]]; then
            echo "❌ 未找到 skill: $TARGET_SKILL" >&2
            exit 1
        fi
        ;;
    group)
        if [[ -z "$TARGET_GROUP" ]]; then
            echo "❌ --group 需要 update_group" >&2
            exit 1
        fi
        for row in "${ROWS[@]}"; do
            IFS=$'\x1f' read -r _skill_name _skill_path _source _source_type _source_repo update_group <<< "$row"
            if [[ "$update_group" == "$TARGET_GROUP" ]]; then
                REMOVE_ROWS+=("$row")
            fi
        done
        if [[ "${#REMOVE_ROWS[@]}" -eq 0 ]]; then
            echo "❌ 未找到来源分组: $TARGET_GROUP" >&2
            exit 1
        fi
        ;;
esac

REMOVED=()
for row in "${REMOVE_ROWS[@]}"; do
    IFS=$'\x1f' read -r skill_name skill_path source source_type source_repo update_group <<< "$row"
    if [[ ! -d "$skill_path" ]]; then
        echo "⚠️ 跳过不存在目录: $skill_path"
        continue
    fi
    rm -rf "$skill_path"
    prune_empty_parents "$skill_path" "$SOURCE_SKILLS_DIR"
    REMOVED+=("$skill_name")
    echo "🗑️ 已删除: $skill_name"
    if [[ "$MODE" == "skill" && "$source_type" == "bundle" && -n "$update_group" ]]; then
        echo "   提示: 该 skill 属于 bundle 分组 $update_group，后续按组更新时可能会重新装回"
    fi
done

if [[ "${#REMOVED[@]}" -eq 0 ]]; then
    echo "ℹ️ 没有执行任何删除"
    exit 0
fi

if [[ -x "$INSTALL_SCRIPT" ]]; then
    SKILLS_DIR="$SKILLS_DIR" SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR" bash "$INSTALL_SCRIPT"
fi

if [[ -x "$UPDATE_LIST_SCRIPT" ]]; then
    SKILLS_DIR="$SOURCE_SKILLS_DIR" SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR" bash "$UPDATE_LIST_SCRIPT"
fi

echo "✅ 卸载完成: ${#REMOVED[@]} 个"
printf '   - %s\n' "${REMOVED[@]}"
