#!/bin/bash
# install.sh - 在新电脑上自动配置 Skills（按每个 skill 建立软链接）

set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
BACKUP_DIR=""
CLEANED_STALE_COUNT=0
CLAUDE_PLUGIN_DOC_SCRIPT=""

# 加载中央配置文件（如果存在）
if [ -f "$SKILLS_DIR/.skillsrc" ]; then
    source "$SKILLS_DIR/.skillsrc"
fi

resolve_dir() {
    local dir="$1"
    (cd "$dir" 2>/dev/null && pwd -P)
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

# 统一支持：传统目录 + Gemini/Antigravity 嵌套目录
skill_links=(
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

ensure_backup_dir() {
    if [ -z "$BACKUP_DIR" ]; then
        BACKUP_DIR="$HOME/skills-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
    fi
}

backup_path() {
    local path="$1"
    local name="$2"
    ensure_backup_dir
    mv "$path" "$BACKUP_DIR/$name"
    echo "📦 备份: $BACKUP_DIR/$name"
}

safe_link() {
    local src="$1"
    local dest="$2"
    local dest_name="$3"
    local src_real=""
    local dest_real=""
    local current_target=""

    src_real=$(resolve_dir "$src" || true)

    if [ -e "$dest" ]; then
        dest_real=$(resolve_dir "$dest" || true)
        if [ -n "$src_real" ] && [ -n "$dest_real" ] && [ "$src_real" = "$dest_real" ]; then
            return 0
        fi
    fi

    if [ -L "$dest" ]; then
        current_target=$(readlink "$dest" || true)
        if [ "$current_target" = "$src" ]; then
            return 0
        fi
        rm "$dest"
    elif [ -e "$dest" ]; then
        backup_path "$dest" "$dest_name"
    fi

    ln -s "$src" "$dest"
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

cleanup_stale_links_in_dir() {
    local dir="$1"
    local label="$2"
    shift 2
    local expected_skills=("$@")
    local link_path=""
    local link_name=""

    [[ -d "$dir" ]] || return 0

    while IFS= read -r link_path; do
        [[ -z "$link_path" ]] && continue
        link_name="$(basename "$link_path")"

        if contains_skill "$link_name" "${expected_skills[@]-}"; then
            continue
        fi

        if ! is_managed_symlink "$link_path"; then
            continue
        fi

        rm "$link_path"
        CLEANED_STALE_COUNT=$((CLEANED_STALE_COUNT + 1))
        echo "🧹 清理过期链接($label): $link_path"
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type l | sort)
}

read_claude_publish_policy() {
    local skill_dir="$1"
    local meta_file="$skill_dir/.skill-source.json"

    if [[ ! -f "$meta_file" ]]; then
        printf 'true\x1f\x1f\x1f\n'
        return 0
    fi

    python3 - "$meta_file" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    data = json.load(open(path, "r", encoding="utf-8"))
except Exception:
    print("true\x1f\x1f\x1f")
    raise SystemExit(0)

policies = data.get("platform_policies") or {}
if not isinstance(policies, dict):
    policies = {}
claude = policies.get("claude_code") or {}
if not isinstance(claude, dict):
    claude = {}

publish = claude.get("publish")
if publish is None:
    publish = True

install_hint = claude.get("install_hint") or ""
install_mode = claude.get("install") or ""
plugin_name = claude.get("plugin_name") or ""

print(f"{str(bool(publish)).lower()}\x1f{install_mode}\x1f{plugin_name}\x1f{install_hint}")
PY
}

echo "🚀 开始配置 AI Skills..."
echo "Skills 目录: $SKILLS_DIR"
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
    echo "❌ 中央仓库不存在: $SKILLS_DIR"
    exit 1
fi

SKILLS_DIR="$(resolve_dir "$SKILLS_DIR")"
if [ -z "$SKILLS_DIR" ]; then
    echo "❌ 无法解析中央仓库路径"
    exit 1
fi

# 1) 确保 ~/.agents/skills 为真实目录（不是软链接）
if [ -L "$AGENTS_SKILLS_DIR" ]; then
    echo "⚠️  发现 ~/.agents/skills 是软链接，转换为目录以匹配 npx skills add 行为..."
    rm "$AGENTS_SKILLS_DIR"
    mkdir -p "$AGENTS_SKILLS_DIR"
elif [ -e "$AGENTS_SKILLS_DIR" ] && [ ! -d "$AGENTS_SKILLS_DIR" ]; then
    backup_path "$AGENTS_SKILLS_DIR" "agents-skills-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$AGENTS_SKILLS_DIR"
else
    mkdir -p "$AGENTS_SKILLS_DIR"
fi

# 2) 扫描中央仓库并为 ~/.agents/skills 创建每个 skill 的软链接
skill_names=()
duplicate_count=0
while IFS= read -r skill_md; do
    if [ -z "$skill_md" ]; then
        continue
    fi
    skill_dir="$(dirname "$skill_md")"
    skill_name="$(extract_skill_name "$skill_md" "$(basename "$skill_dir")")"

    if contains_skill "$skill_name" "${skill_names[@]-}"; then
        duplicate_count=$((duplicate_count + 1))
        echo "⚠️  跳过重复 skill 名称: $skill_name ($skill_dir)"
        continue
    fi

    skill_names+=("$skill_name")

    safe_link "$skill_dir" "$AGENTS_SKILLS_DIR/$skill_name" "agents-$skill_name"
done < <(discover_skill_files)

if [ "${#skill_names[@]}" -eq 0 ]; then
    echo "⚠️  未发现任何 SKILL.md，跳过软链接创建"
    exit 0
fi

# 2.1) 清理 ~/.agents/skills 中与当前 skill 集合不一致的旧链接
cleanup_stale_links_in_dir "$AGENTS_SKILLS_DIR" "agents" "${skill_names[@]-}"

# 3) 为各个 AI 工具创建软链接（指向 ~/.agents/skills/<skill>）
for tool_dir in "${skill_links[@]}"; do
    published_skill_names=()
    if [ -L "$tool_dir" ]; then
        echo "⚠️  发现 $tool_dir 是软链接，转换为目录以匹配 per-skill 结构..."
        rm "$tool_dir"
        mkdir -p "$tool_dir"
    elif [ -e "$tool_dir" ] && [ ! -d "$tool_dir" ]; then
        backup_path "$tool_dir" "$(basename "$(dirname "$tool_dir")")-skills-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$tool_dir"
    else
        mkdir -p "$tool_dir"
    fi
    tool_name="$(basename "$(dirname "$tool_dir")")"
    for skill_name in "${skill_names[@]}"; do
        skill_dir="$AGENTS_SKILLS_DIR/$skill_name"
        if [[ "$tool_dir" == "$HOME/.claude/skills" ]]; then
            claude_policy="$(read_claude_publish_policy "$skill_dir")"
            IFS=$'\x1f' read -r claude_publish claude_install claude_plugin_name claude_install_hint <<< "$claude_policy"
            if [[ "$claude_publish" != "true" ]]; then
                echo "⏭️  跳过发布到 Claude Code: $skill_name"
                if [[ -n "$claude_install" ]]; then
                    echo "   原因: Claude Code 安装方式为 $claude_install"
                fi
                if [[ -n "$claude_plugin_name" ]]; then
                    echo "   插件: $claude_plugin_name"
                fi
                if [[ -n "$claude_install_hint" ]]; then
                    echo "   建议命令: $claude_install_hint"
                fi
                continue
            fi
        fi
        safe_link "$skill_dir" "$tool_dir/$skill_name" "$tool_name-$skill_name"
        published_skill_names+=("$skill_name")
    done
    cleanup_stale_links_in_dir "$tool_dir" "$tool_name" "${published_skill_names[@]-}"
done

CLAUDE_PLUGIN_DOC_SCRIPT="$SKILLS_DIR/shared/scripts/generate-claude-plugin-recommendations.sh"
if [[ -x "$CLAUDE_PLUGIN_DOC_SCRIPT" ]]; then
    SKILLS_DIR="$SKILLS_DIR" bash "$CLAUDE_PLUGIN_DOC_SCRIPT"
    echo ""
fi

echo ""
echo "✅ 配置完成！"
echo "🧹 清理过期链接: $CLEANED_STALE_COUNT 个"
echo "⚠️  跳过重复 skill: $duplicate_count 个"
echo ""
echo "📊 验证："
echo "  ✅ $AGENTS_SKILLS_DIR (目录)"
for tool_dir in "${skill_links[@]}"; do
    if [ -d "$tool_dir" ]; then
        echo "  ✅ $tool_dir"
    fi
done
