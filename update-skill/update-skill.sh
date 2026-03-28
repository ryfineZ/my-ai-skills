#!/bin/bash
# update-skill - 基于 .skill-source.json 更新已安装 skill

set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
INSTALL_SCRIPT="$SKILLS_DIR/install-skill/install-skill.sh"
PUBLISH_SCRIPT="$SKILLS_DIR/shared/scripts/install.sh"
UPDATE_LIST_SCRIPT="$SKILLS_DIR/shared/scripts/update-skills-list.sh"

usage() {
    cat <<'EOF'
用法:
  update-skill.sh --list
  update-skill.sh --skill <skill-name>
  update-skill.sh --group <update-group>
  update-skill.sh --all [--prune-missing]

说明:
  - 只处理带有 .skill-source.json 的已安装 skill
  - source=custom 的 skill 会自动跳过
  - source_type=bundle 的 skill 会按 update_group 去重后整包更新
  - --prune-missing 会在 bundle 更新后删除“上游已不存在但本地仍保留”的 skill
EOF
}

MODE=""
TARGET_SKILL=""
TARGET_GROUP=""
PRUNE_MISSING=false

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
        --all)
            MODE="all"
            shift
            ;;
        --prune-missing)
            PRUNE_MISSING=true
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

if [[ -z "$MODE" ]]; then
    usage
    exit 1
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "❌ 中央仓库不存在: $SKILLS_DIR" >&2
    exit 1
fi

if [[ ! -x "$INSTALL_SCRIPT" ]]; then
    echo "❌ 未找到 install-skill 脚本: $INSTALL_SCRIPT" >&2
    exit 1
fi

collect_rows() {
    python3 - "$SKILLS_DIR" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1]).expanduser().resolve()

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

for entry in sorted(skills_dir.iterdir()):
    if not entry.exists():
        continue
    skill_md = entry / "SKILL.md"
    if not skill_md.is_file():
        continue
    skill_name = extract_name(skill_md, entry.name)
    meta_path = entry / ".skill-source.json"
    if not meta_path.is_file():
        continue
    try:
        data = json.loads(meta_path.read_text(encoding="utf-8"))
    except Exception:
        continue
    source = str(data.get("source") or "").strip()
    if source == "custom":
        continue
    source_type = str(data.get("source_type") or "single").strip()
    source_repo = str(data.get("source_repo") or "").strip()
    source_path = str(data.get("source_path") or skill_name).strip()
    bundle_root = str(data.get("bundle_root") or "").strip()
    update_group = str(data.get("update_group") or source_repo).strip()
    row = [
        skill_name,
        source,
        source_type,
        source_repo,
        source_path,
        bundle_root,
        update_group,
    ]
    print("\x1f".join(row))
PY
}

contains_skill() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

ROWS=()
INCOMPLETE_ROWS=()
while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    IFS=$'\x1f' read -r _skill_name _source _source_type source_repo _source_path _bundle_root _update_group <<< "$row"
    if [[ -z "$source_repo" ]]; then
        INCOMPLETE_ROWS+=("$row")
    else
        ROWS+=("$row")
    fi
done < <(collect_rows)

if [[ "${#ROWS[@]}" -eq 0 && "${#INCOMPLETE_ROWS[@]}" -eq 0 ]]; then
    echo "ℹ️  没有找到带来源元数据的已安装 skill"
    exit 0
fi

if [[ "$MODE" == "list" ]]; then
    if [[ "${#ROWS[@]}" -gt 0 ]]; then
        printf '可更新 skill:\n'
        for row in "${ROWS[@]}"; do
            IFS=$'\x1f' read -r skill_name source source_type source_repo source_path bundle_root update_group <<< "$row"
            printf ' - %s | type=%s | repo=%s | group=%s\n' "$skill_name" "$source_type" "$source_repo" "$update_group"
        done
    else
        printf '可更新 skill:\n'
        printf ' - （当前没有）\n'
    fi
    if [[ "${#INCOMPLETE_ROWS[@]}" -gt 0 ]]; then
        printf '\n缺少来源信息，暂不可更新:\n'
        for row in "${INCOMPLETE_ROWS[@]}"; do
            IFS=$'\x1f' read -r skill_name source source_type source_repo source_path bundle_root update_group <<< "$row"
            printf ' - %s | type=%s | source_path=%s\n' "$skill_name" "$source_type" "$source_path"
        done
    fi
    exit 0
fi

GROUP_DONE=()
UPDATED_COUNT=0
ADDED_COUNT=0
PRUNED_COUNT=0

refresh_global_state() {
    if [[ -x "$PUBLISH_SCRIPT" ]]; then
        SKILLS_DIR="$SKILLS_DIR" bash "$PUBLISH_SCRIPT" >/dev/null
    fi
    if [[ -x "$UPDATE_LIST_SCRIPT" ]]; then
        SKILLS_DIR="$SKILLS_DIR" bash "$UPDATE_LIST_SCRIPT" >/dev/null
    fi
}

collect_group_skill_names() {
    local group="$1"
    local row=""
    for row in "${ROWS[@]}"; do
        IFS=$'\x1f' read -r skill_name _source _source_type _source_repo _source_path _bundle_root update_group <<< "$row"
        if [[ "$update_group" == "$group" ]]; then
            printf '%s\n' "$skill_name"
        fi
    done
}

collect_remote_bundle_skill_names() {
    local repo="$1"
    local bundle_root="${2:-skills}"
    local temp_dir=""
    temp_dir="$(mktemp -d)"
    git clone --depth 1 "$repo" "$temp_dir/repo" >/dev/null 2>&1
    python3 - "$temp_dir/repo" "$bundle_root" <<'PY'
import re
import sys
from pathlib import Path

repo_dir = Path(sys.argv[1])
bundle_root = sys.argv[2]
root = repo_dir / bundle_root
if not root.is_dir():
    raise SystemExit(1)

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

for entry in sorted(root.iterdir()):
    skill_md = entry / "SKILL.md"
    if entry.is_dir() and skill_md.is_file():
        print(extract_name(skill_md, entry.name))
PY
    local rc=$?
    rm -rf "$temp_dir"
    return "$rc"
}

update_row() {
    local row="$1"
    local skill_name source source_type source_repo source_path bundle_root update_group
    local before_names=()
    local remote_names=()
    local removed_names=()
    local added_names=()
    local item=""
    IFS=$'\x1f' read -r skill_name source source_type source_repo source_path bundle_root update_group <<< "$row"

    if [[ -z "$source_repo" ]]; then
        echo "⚠️  跳过 $skill_name：缺少 source_repo"
        return 0
    fi

    if [[ "$source_type" == "bundle" ]]; then
        if contains_skill "$update_group" "${GROUP_DONE[@]-}"; then
            return 0
        fi
        GROUP_DONE+=("$update_group")
        echo "⏳ 更新 bundle: $update_group"

        while IFS= read -r item; do
            [[ -n "$item" ]] || continue
            before_names+=("$item")
        done < <(collect_group_skill_names "$update_group")

        while IFS= read -r item; do
            [[ -n "$item" ]] || continue
            remote_names+=("$item")
        done < <(collect_remote_bundle_skill_names "$source_repo" "${bundle_root:-skills}" || true)

        if [[ "${#remote_names[@]}" -gt 0 ]]; then
            for item in "${remote_names[@]}"; do
                if ! contains_skill "$item" "${before_names[@]-}"; then
                    added_names+=("$item")
                fi
            done
            for item in "${before_names[@]}"; do
                if ! contains_skill "$item" "${remote_names[@]-}"; then
                    removed_names+=("$item")
                fi
            done
        fi

        bash "$INSTALL_SCRIPT" "$source_repo" --all-skills --bundle-root "${bundle_root:-skills}" --global

        if [[ "${#added_names[@]}" -gt 0 ]]; then
            echo "   新增 skill:"
            printf '   + %s\n' "${added_names[@]}"
            ADDED_COUNT=$((ADDED_COUNT + ${#added_names[@]}))
        fi

        if [[ "${#removed_names[@]}" -gt 0 ]]; then
            echo "   上游已不存在的 skill:"
            printf '   - %s\n' "${removed_names[@]}"
            if [[ "$PRUNE_MISSING" == true ]]; then
                for item in "${removed_names[@]}"; do
                    rm -rf "$SKILLS_DIR/$item"
                done
                refresh_global_state
                echo "   已按 --prune-missing 删除本地残留"
                PRUNED_COUNT=$((PRUNED_COUNT + ${#removed_names[@]}))
            fi
        fi

        UPDATED_COUNT=$((UPDATED_COUNT + 1))
        return 0
    fi

    echo "⏳ 更新 skill: $skill_name"
    bash "$INSTALL_SCRIPT" "$source_repo" --skill "$skill_name" --global
    UPDATED_COUNT=$((UPDATED_COUNT + 1))
}

case "$MODE" in
    skill)
        if [[ -z "$TARGET_SKILL" ]]; then
            echo "❌ --skill 需要 skill 名称" >&2
            exit 1
        fi
        matched=0
        for row in "${ROWS[@]}"; do
            IFS=$'\x1f' read -r skill_name _rest <<< "$row"
            if [[ "$skill_name" == "$TARGET_SKILL" ]]; then
                update_row "$row"
                matched=1
                break
            fi
        done
        if [[ "$matched" -ne 1 ]]; then
            echo "❌ 未找到可更新 skill: $TARGET_SKILL" >&2
            exit 1
        fi
        ;;
    group)
        if [[ -z "$TARGET_GROUP" ]]; then
            echo "❌ --group 需要 update_group" >&2
            exit 1
        fi
        matched=0
        for row in "${ROWS[@]}"; do
            IFS=$'\x1f' read -r _skill_name _source _source_type _source_repo _source_path _bundle_root update_group <<< "$row"
            if [[ "$update_group" == "$TARGET_GROUP" ]]; then
                update_row "$row"
                matched=1
            fi
        done
        if [[ "$matched" -ne 1 ]]; then
            echo "❌ 未找到可更新分组: $TARGET_GROUP" >&2
            exit 1
        fi
        ;;
    all)
        for row in "${ROWS[@]}"; do
            update_row "$row"
        done
        ;;
esac

echo "✅ 更新完成: $UPDATED_COUNT 个更新动作"
if [[ "$ADDED_COUNT" -gt 0 ]]; then
    echo "   新增 skill: $ADDED_COUNT 个"
fi
if [[ "$PRUNED_COUNT" -gt 0 ]]; then
    echo "   已清理过期 skill: $PRUNED_COUNT 个"
fi
