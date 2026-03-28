#!/bin/bash
# verify.sh - 验证 Skills 配置（按每个 skill 软链接）

set -euo pipefail

usage() {
    cat <<'USAGE'
用法:
  shared/scripts/verify.sh [--json] [--json-out <path>]

参数:
  --json              输出 JSON 到 stdout（不输出人类可读日志）
  --json-out <path>   将 JSON 结果写入文件
  -h, --help          显示帮助
USAGE
}

JSON_STDOUT=false
JSON_OUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_STDOUT=true
            shift
            ;;
        --json-out)
            JSON_OUT="$2"
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

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
AGENTS_SKILLS_REAL=""
ERROR_COUNT=0
WARNING_COUNT=0
SKILL_COUNT=0
ISSUES_FILE="$(mktemp)"
SKILL_NAMES=()

cleanup() {
    rm -f "$ISSUES_FILE"
}
trap cleanup EXIT

resolve_dir() {
    local dir="$1"
    (cd "$dir" 2>/dev/null && pwd -P)
}

should_expect_tool_link() {
    local skill_dir="$1"
    local tool_dir="$2"
    local meta_file="$skill_dir/.skill-source.json"

    if [[ "$tool_dir" != "$HOME/.claude/skills" ]]; then
        return 0
    fi

    if [[ ! -f "$meta_file" ]]; then
        return 0
    fi

    python3 - "$meta_file" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    data = json.load(open(path, "r", encoding="utf-8"))
except Exception:
    raise SystemExit(0)

policies = data.get("platform_policies") or {}
if not isinstance(policies, dict):
    raise SystemExit(0)
claude = policies.get("claude_code") or {}
if not isinstance(claude, dict):
    raise SystemExit(0)

publish = claude.get("publish")
if publish is False:
    raise SystemExit(1)
PY
}

discover_skill_files() {
    local entry=""
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        [[ -e "$entry" ]] || continue
        [[ -f "$entry/SKILL.md" ]] || continue
        printf '%s\n' "$entry/SKILL.md"
    done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | sort)
}

extract_skill_name() {
    local skill_file="$1"
    local fallback_name="$2"
    local skill_name=""

    skill_name="$(python3 - "$skill_file" <<'PY'
import re
import sys

path = sys.argv[1]
try:
    content = open(path, "r", encoding="utf-8").read()
except Exception:
    raise SystemExit(0)

match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
frontmatter = match.group(1) if match else ""

for raw_line in frontmatter.splitlines():
    line = raw_line.strip()
    if not line or ":" not in line:
        continue
    key, value = line.split(":", 1)
    if key.strip().lower() == "name":
        print(value.strip().strip('"').strip("'"))
        break
PY
)"

    if [[ -n "$skill_name" ]]; then
        printf '%s\n' "$skill_name"
    else
        printf '%s\n' "$fallback_name"
    fi
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

is_managed_symlink() {
    local link_path="$1"
    local target=""
    local resolved=""

    target="$(readlink "$link_path" 2>/dev/null || true)"
    if [[ "$target" == "$AGENTS_SKILLS_DIR/"* ]] || [[ "$target" == *".agents/skills/"* ]]; then
        return 0
    fi

    resolved="$(resolve_dir "$link_path" || true)"
    if [[ -n "$resolved" ]] && [[ "$resolved" == "$AGENTS_SKILLS_DIR/"* ]]; then
        return 0
    fi

    return 1
}

log() {
    if [[ "$JSON_STDOUT" != true ]]; then
        echo "$@"
    fi
}

add_issue() {
    local severity="$1"
    local issue_type="$2"
    local path="$3"
    local detail="$4"

    detail="${detail//$'\t'/ }"
    detail="${detail//$'\n'/ }"
    printf '%s\t%s\t%s\t%s\n' "$severity" "$issue_type" "$path" "$detail" >> "$ISSUES_FILE"
}

warn_issue() {
    local issue_type="$1"
    local path="$2"
    local detail="$3"
    WARNING_COUNT=$((WARNING_COUNT + 1))
    add_issue "warning" "$issue_type" "$path" "$detail"
    log "⚠️  $detail"
}

error_issue() {
    local issue_type="$1"
    local path="$2"
    local detail="$3"
    ERROR_COUNT=$((ERROR_COUNT + 1))
    add_issue "error" "$issue_type" "$path" "$detail"
    log "❌ $detail"
}

emit_json() {
    python3 - "$ISSUES_FILE" "$SKILLS_DIR" "$AGENTS_SKILLS_DIR" "$SKILL_COUNT" "$ERROR_COUNT" "$WARNING_COUNT" <<'PY'
import datetime as dt
import json
import sys
from pathlib import Path

issues_file = Path(sys.argv[1])
skills_dir = sys.argv[2]
agents_skills_dir = sys.argv[3]
skill_count = int(sys.argv[4])
error_count = int(sys.argv[5])
warning_count = int(sys.argv[6])

issues = []
if issues_file.exists():
    for raw in issues_file.read_text(encoding="utf-8").splitlines():
        if not raw.strip():
            continue
        parts = raw.split("\t", 3)
        if len(parts) < 4:
            continue
        severity, issue_type, path, detail = parts
        issues.append(
            {
                "severity": severity,
                "type": issue_type,
                "path": path,
                "detail": detail,
            }
        )

status = "OK"
if error_count > 0:
    status = "ERROR"
elif warning_count > 0:
    status = "WARN"

out = {
    "generated_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
    "status": status,
    "skills_dir": skills_dir,
    "agents_skills_dir": agents_skills_dir,
    "skills_count": skill_count,
    "counts": {"errors": error_count, "warnings": warning_count},
    "issues": issues,
}
print(json.dumps(out, ensure_ascii=False, indent=2))
PY
}

check_stale_links_in_dir() {
    local dir="$1"
    local label="$2"
    local link_path=""
    local link_name=""

    [[ -d "$dir" ]] || return 0

    while IFS= read -r link_path; do
        [[ -z "$link_path" ]] && continue
        link_name="$(basename "$link_path")"

        if contains_skill "$link_name" "${SKILL_NAMES[@]-}"; then
            if [[ ! -e "$link_path" ]]; then
                warn_issue "broken_link" "$link_path" "$label 中存在损坏链接: $link_path"
            fi
            continue
        fi

        if ! is_managed_symlink "$link_path"; then
            continue
        fi

        warn_issue "stale_link" "$link_path" "$label 中存在过期链接: $link_path"
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type l | sort)
}

log "🔍 验证 AI Skills 配置..."
log ""

if [[ -d "$SKILLS_DIR" ]]; then
    configured_skills_dir="$SKILLS_DIR"
    SKILLS_DIR="$(resolve_dir "$SKILLS_DIR")"
    log "✅ 中央仓库: $SKILLS_DIR"
    if [[ "$configured_skills_dir" != "$SKILLS_DIR" ]]; then
        log "   (配置路径: $configured_skills_dir)"
    fi
else
    error_issue "missing_skills_dir" "$SKILLS_DIR" "中央仓库不存在: $SKILLS_DIR"
fi

SKILL_FILES=()
if [[ -d "$SKILLS_DIR" ]]; then
    while IFS= read -r skill_file; do
        [[ -z "$skill_file" ]] && continue
        skill_name="$(extract_skill_name "$skill_file" "$(basename "$(dirname "$skill_file")")")"
        SKILL_FILES+=("$skill_file")
        SKILL_NAMES+=("$skill_name")
    done < <(discover_skill_files)
fi
SKILL_COUNT=${#SKILL_FILES[@]}
log "   Skills 数量: $SKILL_COUNT"

log ""
log "🔗 ~/.agents/skills 状态："
if [[ -L "$AGENTS_SKILLS_DIR" ]]; then
    warn_issue "agents_dir_is_symlink" "$AGENTS_SKILLS_DIR" "$AGENTS_SKILLS_DIR 是软链接（建议改为目录以匹配 npx skills add 行为）"
elif [[ -d "$AGENTS_SKILLS_DIR" ]]; then
    log "✅ $AGENTS_SKILLS_DIR (目录)"
    AGENTS_SKILLS_REAL="$(resolve_dir "$AGENTS_SKILLS_DIR")"
else
    error_issue "missing_agents_dir" "$AGENTS_SKILLS_DIR" "$AGENTS_SKILLS_DIR 不存在"
fi

log ""
log "🔗 工具链接状态："

links=(
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.cursor/skills"
    "$HOME/.gemini/skills"
    "$HOME/.antigravity/skills"
    "$HOME/.gemini/antigravity/skills"
    "$HOME/.windsurf/skills"
    "$HOME/.cline/skills"
    "$HOME/.goose/skills"
)

for link in "${links[@]}"; do
    if [[ -L "$link" ]]; then
        warn_issue "tool_dir_is_symlink" "$link" "$link 是软链接（建议使用 per-skill 目录）"
    elif [[ -d "$link" ]]; then
        log "✅ $link (目录)"
    elif [[ -e "$link" ]]; then
        warn_issue "tool_dir_not_directory" "$link" "$link 存在但不是目录"
    else
        log "ℹ️  $link (不存在，可忽略)"
    fi
done

log ""
log "📋 可用 Skills："
for skill in "${SKILL_FILES[@]-}"; do
    skill_name="$(extract_skill_name "$skill" "$(basename "$(dirname "$skill")")")"
    skill_dir="$(dirname "$skill")"
    desc="$(grep "^description:" "$skill" 2>/dev/null | head -1 | sed 's/description: *//' || true)"
    [[ -z "$desc" ]] && desc="无描述"
    log "  - $skill_name: $desc"

    if [[ -n "$AGENTS_SKILLS_REAL" ]] && [[ "$SKILLS_DIR" == "$AGENTS_SKILLS_REAL" ]]; then
        if [[ -d "$AGENTS_SKILLS_DIR/$skill_name" ]]; then
            :
        elif [[ -e "$AGENTS_SKILLS_DIR/$skill_name" ]]; then
            warn_issue "invalid_agents_entry" "$AGENTS_SKILLS_DIR/$skill_name" "中央目录条目异常：$AGENTS_SKILLS_DIR/$skill_name 不是目录"
        else
            error_issue "missing_agents_entry" "$AGENTS_SKILLS_DIR/$skill_name" "缺少中央目录条目：$AGENTS_SKILLS_DIR/$skill_name"
        fi
    elif [[ -L "$AGENTS_SKILLS_DIR/$skill_name" ]]; then
        expected="$(dirname "$skill")"
        expected_real="$(resolve_dir "$expected" || true)"
        actual_real="$(resolve_dir "$AGENTS_SKILLS_DIR/$skill_name" || true)"
        if [[ -z "$actual_real" ]] || [[ "$actual_real" != "$expected_real" ]]; then
            warn_issue "agents_link_mismatch" "$AGENTS_SKILLS_DIR/$skill_name" "中央目录链接指向异常：$AGENTS_SKILLS_DIR/$skill_name"
        fi
    elif [[ -e "$AGENTS_SKILLS_DIR/$skill_name" ]]; then
        warn_issue "agents_entry_not_symlink" "$AGENTS_SKILLS_DIR/$skill_name" "$AGENTS_SKILLS_DIR/$skill_name 不是软链接"
    else
        error_issue "missing_agents_entry" "$AGENTS_SKILLS_DIR/$skill_name" "缺少中央目录条目：$AGENTS_SKILLS_DIR/$skill_name"
    fi

    for link in "${links[@]}"; do
        if ! should_expect_tool_link "$skill_dir" "$link"; then
            if [[ -e "$link/$skill_name" || -L "$link/$skill_name" ]]; then
                warn_issue "unexpected_tool_link" "$link/$skill_name" "该平台不应发布但仍存在链接：$link/$skill_name"
            fi
            continue
        fi
        if [[ -L "$link/$skill_name" ]]; then
            if [[ ! -e "$link/$skill_name" ]]; then
                warn_issue "broken_tool_link" "$link/$skill_name" "损坏链接：$link/$skill_name"
            fi
            continue
        elif [[ -e "$link/$skill_name" ]]; then
            warn_issue "tool_entry_not_symlink" "$link/$skill_name" "$link/$skill_name 不是软链接"
        elif [[ -d "$link" ]]; then
            error_issue "missing_tool_link" "$link/$skill_name" "缺少工具链接：$link/$skill_name"
        fi
    done
done

# 反向检查：发现不再属于当前技能集合的旧链接
check_stale_links_in_dir "$AGENTS_SKILLS_DIR" "~/.agents/skills"
for link in "${links[@]}"; do
    check_stale_links_in_dir "$link" "$link"
done

if [[ -n "$JSON_OUT" ]]; then
    emit_json > "$JSON_OUT"
    log ""
    log "📄 JSON 报告: $JSON_OUT"
fi

if [[ "$JSON_STDOUT" == true ]]; then
    emit_json
fi

if [[ "$JSON_STDOUT" != true ]]; then
    log ""
    log "📊 检查结果：errors=$ERROR_COUNT warnings=$WARNING_COUNT"
    if [[ "$ERROR_COUNT" -eq 0 ]]; then
        log "✅ 验证完成！"
    else
        log "❌ 验证完成（存在错误）"
    fi
fi

if [[ "$ERROR_COUNT" -gt 0 ]]; then
    exit 1
fi
exit 0
