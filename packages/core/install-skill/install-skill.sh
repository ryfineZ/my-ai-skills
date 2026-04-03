#!/bin/bash
# install-skill - 安装 skills（支持全局和项目级）

set -euo pipefail

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
RUNTIME_SKILLS_DIR="${RUNTIME_SKILLS_DIR:-$HOME/.agents/skills}"
SOURCE_SKILLS_DIR="${SOURCE_SKILLS_DIR:-$HOME/Workspace/skills-central}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "用法: $0 <owner/repo> (--skill <skill-name> | --all-skills) [--bundle-root <dir>] [--global] [--codex-only]"
    echo ""
    echo "示例:"
    echo "  $0 vercel-labs/agent-skills --skill frontend-design --global"
    echo "  $0 anthropics/skills --skill planning"
    echo "  $0 https://github.com/obra/superpowers.git --all-skills --bundle-root skills --global"
    echo ""
    echo "参数:"
    echo "  --global, -g    全局安装（写入 ~/Workspace/skills-central，并导出到 ~/.agents/skills）"
    echo "  --all-skills    安装 bundle 仓库中的全部 skills"
    echo "  --bundle-root   bundle 的 skill 根目录（默认自动识别，常见值为 skills）"
    echo "  --codex-only    仅发布到 Codex，不同步到其他客户端"
    echo "  不带 -g         项目级安装（到 ./.agents/skills，仅当前项目）"
    echo "  --rollback-on-fail      本地深扫失败时自动回滚（默认开启）"
    echo "  --no-rollback-on-fail   关闭自动回滚"
    echo ""
    echo "说明:"
    echo "  安装和更新都会强制执行安全检查（临时副本预审 + 本地深扫）"
    exit 1
}

resolve_security_guard_script() {
    if [[ -n "${SECURITY_GUARD_SCRIPT:-}" && -f "${SECURITY_GUARD_SCRIPT:-}" ]]; then
        echo "$SECURITY_GUARD_SCRIPT"
        return 0
    fi
    local candidates=(
        "$REPO_ROOT/skill-security-guard/scripts/skill_security_guard.py"
        "$HOME/.agents/skills/skill-security-guard/scripts/skill_security_guard.py"
        "$HOME/Workspace/skills-central/packages/core/skill-security-guard/scripts/skill_security_guard.py"
    )
    local script
    for script in "${candidates[@]}"; do
        if [[ -f "$script" ]]; then
            echo "$script"
            return 0
        fi
    done
    return 1
}

ensure_source_repo_layout() {
    mkdir -p \
        "$SOURCE_SKILLS_DIR/packages/core" \
        "$SOURCE_SKILLS_DIR/packages/custom" \
        "$SOURCE_SKILLS_DIR/packages/community"
}

source_skill_files() {
    [[ -d "$SOURCE_SKILLS_DIR/packages" ]] || return 0
    find "$SOURCE_SKILLS_DIR/packages" -type f -name SKILL.md | sort
}

assert_no_export_name_conflict() {
    local skill_name="$1"
    local allowed_path="${2:-}"
    local skill_md=""
    local skill_dir=""
    local existing_name=""
    local existing_dir=""

    while IFS= read -r skill_md; do
        [[ -n "$skill_md" ]] || continue
        existing_dir="$(dirname "$skill_md")"
        existing_name="$(extract_skill_name "$skill_md" "$(basename "$existing_dir")")"
        if [[ "$existing_name" != "$skill_name" ]]; then
            continue
        fi
        if [[ -n "$allowed_path" && "$existing_dir" == "$allowed_path" ]]; then
            continue
        fi
        echo -e "${RED}❌ 导出名冲突: ${skill_name}${NC}"
        echo -e "${RED}   已存在: ${existing_dir}${NC}"
        echo -e "${RED}   当前目标: ${allowed_path:-<new>}${NC}"
        exit 1
    done < <(source_skill_files)
}

find_skill_dir_in_repo() {
    local repo_dir="$1"
    local skill_name="$2"
    python3 - "$repo_dir" "$skill_name" <<'PY'
import re
import sys
from pathlib import Path

repo_dir = Path(sys.argv[1]).resolve()
skill_name = sys.argv[2]
matches = []

for skill_md in sorted(repo_dir.rglob("SKILL.md")):
    skill_dir = skill_md.parent
    fallback = skill_dir.name
    try:
        content = skill_md.read_text(encoding="utf-8")
    except Exception:
        continue
    match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    frontmatter = match.group(1) if match else ""
    actual_name = fallback
    for raw_line in frontmatter.splitlines():
        line = raw_line.strip()
        if not line or ":" not in line:
            continue
        key, value = line.split(":", 1)
        if key.strip().lower() == "name":
            actual_name = value.strip().strip('"').strip("'") or fallback
            break
    if actual_name == skill_name or fallback == skill_name:
        matches.append(str(skill_dir))

if len(matches) == 1:
    print(matches[0])
    raise SystemExit(0)

if len(matches) == 0:
    raise SystemExit(1)

print("\n".join(matches), file=sys.stderr)
raise SystemExit(2)
PY
}

copy_skill_dir() {
    local source_dir="$1"
    local target_dir="$2"
    mkdir -p "$(dirname "$target_dir")"
    rm -rf "$target_dir"
    cp -a "$source_dir" "$target_dir"
}

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

print_guard_summary() {
    local report_file="$1"
    python3 - "$report_file" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    data = json.load(open(path, "r", encoding="utf-8"))
except Exception:
    print("    无法解析安全报告。")
    raise SystemExit(0)

summary = data.get("summary", {})
counts = summary.get("severity_counts", {})
print(f"    Verdict: {summary.get('verdict', 'UNKNOWN')}")
print(
    "    Summary: "
    f"CRITICAL={counts.get('CRITICAL', 0)} "
    f"HIGH={counts.get('HIGH', 0)} "
    f"MEDIUM={counts.get('MEDIUM', 0)} "
    f"LOW={counts.get('LOW', 0)}"
)

findings = data.get("findings", [])[:5]
if findings:
    print("    Top findings:")
    for finding in findings:
        sev = finding.get("severity", "UNKNOWN")
        rule = finding.get("rule_id", "UNKNOWN_RULE")
        file_path = finding.get("file_path", "?")
        line_no = finding.get("line_number", 0)
        print(f"      - [{sev}] {rule} @ {file_path}:{line_no}")
PY
}

run_security_check() {
    local guard_script="$1"
    local mode="$2"
    local target="$3"
    local report_file
    local rc
    report_file="$(mktemp)"

    local cmd=(python3 "$guard_script" --json --min-severity high "$mode")
    cmd+=(--path "$target")

    : > "$report_file"
    set +e
    "${cmd[@]}" >"$report_file"
    rc=$?
    set -e

    if [[ "$rc" -eq 0 ]]; then
        echo -e "${GREEN}✅ 安全检查通过 (${mode})${NC}"
        print_guard_summary "$report_file"
        rm -f "$report_file"
        return 0
    fi

    if [[ -s "$report_file" ]]; then
        echo -e "${RED}❌ 安全检查未通过 (${mode})${NC}"
        print_guard_summary "$report_file"
    else
        echo -e "${RED}❌ 安全检查执行失败 (${mode}), exit=${rc}${NC}"
    fi
    rm -f "$report_file"
    return 1
}

trim_trailing_slash() {
    local value="$1"
    while [[ "$value" == */ && "$value" != "/" ]]; do
        value="${value%/}"
    done
    printf '%s\n' "$value"
}

derive_package_name() {
    local repo="$1"
    local normalized
    normalized="$(trim_trailing_slash "$repo")"
    normalized="${normalized##*/}"
    normalized="${normalized%.git}"
    printf '%s\n' "$normalized"
}

derive_update_group() {
    local repo="$1"
    local normalized
    normalized="$(trim_trailing_slash "$repo")"
    normalized="${normalized#https://github.com/}"
    normalized="${normalized#http://github.com/}"
    normalized="${normalized#git@github.com:}"
    normalized="${normalized%.git}"
    printf '%s\n' "$normalized"
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

write_source_metadata() {
    local target_path="$1"
    local source_repo="$2"
    local skill_name="$3"
    local source_type="${4:-single}"
    local source_ref="${5:-}"
    local source_path="${6:-$skill_name}"
    local bundle_root="${7:-}"
    local update_group="${8:-$source_repo}"
    local package_name="${9:-}"
    local claude_publish="${10:-true}"
    local claude_install="${11:-skill}"
    local claude_plugin_name="${12:-}"
    local claude_install_hint="${13:-}"
    local claude_plugin_marketplace="${14:-}"
    local claude_plugin_marketplace_source="${15:-}"
    local platform_profile="${16:-all}"
    local meta_file="$target_path/.skill-source.json"
    local now_utc
    now_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    python3 - "$meta_file" "$source_repo" "$skill_name" "$source_type" "$source_ref" "$source_path" "$bundle_root" "$update_group" "$package_name" "$claude_publish" "$claude_install" "$claude_plugin_name" "$claude_install_hint" "$claude_plugin_marketplace" "$claude_plugin_marketplace_source" "$now_utc" "$platform_profile" <<'PY'
import json
import os
import sys

(
    meta_file,
    source_repo,
    skill_name,
    source_type,
    source_ref,
    source_path,
    bundle_root,
    update_group,
    package_name,
    claude_publish,
    claude_install,
    claude_plugin_name,
    claude_install_hint,
    claude_plugin_marketplace,
    claude_plugin_marketplace_source,
    now_utc,
    platform_profile,
) = sys.argv[1:18]
data = {}

if os.path.exists(meta_file):
    try:
        with open(meta_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        data = {}

if not package_name:
    package_name = source_repo.rstrip("/").split("/")[-1] if source_repo else skill_name

data["source"] = "community"
data["source_type"] = source_type or data.get("source_type") or "single"
data["package_name"] = package_name
data["source_repo"] = source_repo
data["source_ref"] = source_ref
data["source_path"] = source_path
data["bundle_root"] = bundle_root
data["install_mode"] = "package-source-plus-runtime-export"
data["update_group"] = update_group
platform_policies = data.get("platform_policies")
if not isinstance(platform_policies, dict):
    platform_policies = {}
claude_policy = platform_policies.get("claude_code")
if not isinstance(claude_policy, dict):
    claude_policy = {}
claude_policy["publish"] = claude_publish.lower() == "true"
claude_policy["install"] = claude_install or claude_policy.get("install") or "skill"
if claude_plugin_name:
    claude_policy["plugin_name"] = claude_plugin_name
if claude_install_hint:
    claude_policy["install_hint"] = claude_install_hint
if claude_plugin_marketplace:
    claude_policy["plugin_marketplace"] = claude_plugin_marketplace
if claude_plugin_marketplace_source:
    claude_policy["plugin_marketplace_source"] = claude_plugin_marketplace_source
platform_policies["claude_code"] = claude_policy
if platform_profile == "codex-only":
    for platform_key, publish in {
        "codex": True,
        "claude_code": False,
        "cursor": False,
        "gemini": False,
        "antigravity": False,
        "windsurf": False,
        "cline": False,
        "goose": False,
    }.items():
        policy = platform_policies.get(platform_key)
        if not isinstance(policy, dict):
            policy = {}
        policy["publish"] = publish
        platform_policies[platform_key] = policy
data["platform_policies"] = platform_policies
data["installed_by"] = "install-skill"
data.setdefault("installed_at", now_utc)
data["updated_at"] = now_utc

with open(meta_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

detect_bundle_root() {
    local repo_dir="$1"
    local bundle_root="${2:-}"

    if [[ -n "$bundle_root" ]]; then
        printf '%s\n' "$bundle_root"
        return 0
    fi

    if [[ -d "$repo_dir/skills" ]]; then
        printf 'skills\n'
        return 0
    fi

    return 1
}

detect_claude_plugin_policy() {
    local repo_dir="$1"
    local package_name="$2"
    local publish="true"
    local install_mode="skill"
    local plugin_name=""
    local install_hint=""
    local plugin_marketplace=""
    local plugin_marketplace_source=""
    local extracted=""

    extracted="$(python3 - "$repo_dir" "$package_name" <<'PY'
import re
import sys
from pathlib import Path

repo_dir = Path(sys.argv[1])
package_name = sys.argv[2]

marketplace_add = ""
plugin_name = ""
plugin_marketplace = ""
install_hint = ""

readme_candidates = []
for pattern in ("README*", "docs/README*", ".claude/README*", ".claude-plugin/README*"):
    readme_candidates.extend(sorted(repo_dir.glob(pattern)))

seen = set()
for path in readme_candidates:
    if path in seen or not path.is_file():
        continue
    seen.add(path)
    try:
        content = path.read_text(encoding="utf-8")
    except Exception:
        continue

    add_match = re.search(r"/plugin\s+marketplace\s+add\s+([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)", content)
    if add_match and not marketplace_add:
        marketplace_add = add_match.group(1)

    install_matches = re.findall(r"/plugin\s+install\s+([A-Za-z0-9_.-]+)(?:@([A-Za-z0-9_.-]+))?", content)
    if not install_matches:
        continue

    selected = None
    for item in install_matches:
        if item[0] == package_name:
            selected = item
            break
    if selected is None:
        selected = install_matches[0]

    plugin_name = selected[0]
    plugin_marketplace = selected[1] or ""
    if plugin_name:
        install_hint = f"/plugin install {plugin_name}"
        if plugin_marketplace:
            install_hint += f"@{plugin_marketplace}"
    break

if marketplace_add and not plugin_marketplace:
    plugin_marketplace = marketplace_add.split("/")[-1]

print("\x1f".join([plugin_name, plugin_marketplace, marketplace_add, install_hint]))
PY
)"

    IFS=$'\x1f' read -r plugin_name plugin_marketplace plugin_marketplace_source install_hint <<< "$extracted"

    if [[ -f "$repo_dir/.claude-plugin/plugin.json" || -n "$plugin_name" || -n "$install_hint" ]]; then
        publish="false"
        install_mode="plugin"
        if [[ -z "$plugin_name" ]]; then
            plugin_name="$package_name"
        fi
        if [[ -z "$plugin_marketplace" ]]; then
            plugin_marketplace="claude-plugins-official"
        fi
        if [[ -z "$install_hint" ]]; then
            install_hint="/plugin install ${plugin_name}@${plugin_marketplace}"
        fi
    fi

    printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\n' "$publish" "$install_mode" "$plugin_name" "$install_hint" "$plugin_marketplace" "$plugin_marketplace_source"
}

claude_plugin_installed() {
    local plugin_ref="$1"
    local installed_file="$HOME/.claude/plugins/installed_plugins.json"

    if [[ ! -f "$installed_file" ]]; then
        return 1
    fi

    python3 - "$installed_file" "$plugin_ref" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
plugin_ref = sys.argv[2]

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(1)

plugins = data.get("plugins") or {}
raise SystemExit(0 if plugin_ref in plugins else 1)
PY
}

ensure_claude_plugin_installed() {
    local plugin_name="$1"
    local plugin_marketplace="$2"
    local plugin_marketplace_source="$3"
    local install_hint="$4"
    local plugin_ref=""

    if [[ "$GLOBAL_INSTALL" != true ]]; then
        return 0
    fi

    if [[ -z "$plugin_name" ]]; then
        return 0
    fi

    if ! command -v claude >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ 未检测到 Claude CLI，已跳过 Claude 插件自动安装${NC}"
        if [[ -n "$install_hint" ]]; then
            echo -e "${YELLOW}   可在 Claude Code 中手动执行: ${install_hint}${NC}"
        fi
        return 0
    fi

    if [[ ! -d "$HOME/.claude" ]]; then
        echo -e "${YELLOW}⚠️ 未检测到 ~/.claude，已跳过 Claude 插件自动安装${NC}"
        if [[ -n "$install_hint" ]]; then
            echo -e "${YELLOW}   可在 Claude Code 中手动执行: ${install_hint}${NC}"
        fi
        return 0
    fi

    plugin_ref="$plugin_name"
    if [[ -n "$plugin_marketplace" ]]; then
        plugin_ref="${plugin_name}@${plugin_marketplace}"
    fi

    if [[ -n "$plugin_marketplace_source" ]]; then
        if ! claude plugins marketplace list 2>/dev/null | grep -Fq "$plugin_marketplace"; then
            echo -e "${YELLOW}⏳ 正在为 Claude Code 添加插件市场: ${plugin_marketplace_source}${NC}"
            claude plugins marketplace add "$plugin_marketplace_source"
        fi
    fi

    if claude_plugin_installed "$plugin_ref"; then
        echo -e "${GREEN}✅ Claude Code 插件已安装: ${plugin_ref}${NC}"
        claude plugins enable "$plugin_ref" >/dev/null 2>&1 || true
        return 0
    fi

    echo -e "${YELLOW}⏳ 正在为 Claude Code 安装插件: ${plugin_ref}${NC}"
    claude plugins install "$plugin_ref"
    echo -e "${GREEN}✅ Claude Code 插件安装完成: ${plugin_ref}${NC}"
}

refresh_global_indexes() {
    local install_script=""
    local update_script=""

    echo ""
    echo -e "${YELLOW}⏳ 正在刷新全局 skills 状态...${NC}"
    echo -e "${BLUE}🧠 用途/触发关键词请由当前 AI 在安装后补充到 .skill-source.json${NC}"

    if [[ -f "$REPO_ROOT/shared/scripts/install.sh" ]]; then
        install_script="$REPO_ROOT/shared/scripts/install.sh"
    fi

    if [[ -n "$install_script" ]]; then
        if SKILLS_DIR="$RUNTIME_SKILLS_DIR" SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR" bash "$install_script" >/dev/null; then
            echo -e "${GREEN}✅ 平台链接已刷新${NC}"
        else
            echo -e "${YELLOW}⚠️  平台链接刷新失败，请手动执行：SKILLS_DIR=\"$RUNTIME_SKILLS_DIR\" SOURCE_SKILLS_DIR=\"$SOURCE_SKILLS_DIR\" bash \"$install_script\"${NC}"
        fi
    fi

    if [[ -f "$REPO_ROOT/shared/scripts/update-skills-list.sh" ]]; then
        update_script="$REPO_ROOT/shared/scripts/update-skills-list.sh"
    fi

    if [[ -n "$update_script" ]]; then
        if SKILLS_DIR="$SOURCE_SKILLS_DIR" SOURCE_SKILLS_DIR="$SOURCE_SKILLS_DIR" bash "$update_script"; then
            echo -e "${GREEN}✅ Skills 列表已更新${NC}"
        else
            echo -e "${YELLOW}⚠️  Skills 列表更新失败，请手动执行：SKILLS_DIR=\"$SOURCE_SKILLS_DIR\" SOURCE_SKILLS_DIR=\"$SOURCE_SKILLS_DIR\" bash \"$update_script\"${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  未找到 update-skills-list.sh，已跳过列表更新${NC}"
    fi
}

clone_bundle_repo() {
    local repo="$1"
    local target_dir="$2"
    git clone --depth 1 "$repo" "$target_dir" >/dev/null 2>&1
}

cleanup_repo_snapshot() {
    local repo_dir="${1:-}"
    if [[ -n "$repo_dir" && -d "$repo_dir" ]]; then
        rm -rf "$(dirname "$repo_dir")"
    fi
}

prepare_repo_snapshot() {
    local repo="$1"
    local temp_dir=""
    local repo_dir=""

    temp_dir="$(mktemp -d)"
    repo_dir="$temp_dir/repo"

    echo -e "${YELLOW}📥 正在拉取临时仓库副本...${NC}" >&2
    if ! clone_bundle_repo "$repo" "$repo_dir"; then
        cleanup_repo_snapshot "$repo_dir"
        echo -e "${RED}❌ 临时克隆仓库失败: ${repo}${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}🔒 执行临时副本安全预审...${NC}" >&2
    if ! run_security_check "$SECURITY_GUARD_SCRIPT" local "$repo_dir" >&2; then
        cleanup_repo_snapshot "$repo_dir"
        echo -e "${RED}❌ 已阻断安装/更新，请先处理仓库风险: ${repo}${NC}" >&2
        return 1
    fi

    printf '%s\n' "$repo_dir"
}

install_bundle_skills() {
    local repo="$1"
    local install_root="$2"
    local bundle_root_arg="$3"
    local install_location="$4"
    local install_type="$5"
    local repo_dir=""
    local bundle_root=""
    local source_ref=""
    local package_name=""
    local update_group=""
    local claude_policy_row=""
    local claude_publish=""
    local claude_install=""
    local claude_plugin_name=""
    local claude_install_hint=""
    local claude_plugin_marketplace=""
    local claude_plugin_marketplace_source=""
    local installed_count=0
    local skill_md=""
    local relative_skill_dir=""
    local skill_name=""
    local target_path=""

    repo_dir="$(prepare_repo_snapshot "$repo")" || {
        echo -e "${RED}❌ 无法准备 bundle 仓库副本: ${repo}${NC}"
        exit 1
    }

    bundle_root="$(detect_bundle_root "$repo_dir" "$bundle_root_arg" || true)"
    if [[ -z "$bundle_root" || ! -d "$repo_dir/$bundle_root" ]]; then
        cleanup_repo_snapshot "$repo_dir"
        echo -e "${RED}❌ 无法识别 bundle 根目录，请使用 --bundle-root 显式指定${NC}"
        exit 1
    fi

    source_ref="$(git -C "$repo_dir" rev-parse HEAD)"
    package_name="$(derive_package_name "$repo")"
    update_group="$(derive_update_group "$repo")"
    claude_policy_row="$(detect_claude_plugin_policy "$repo_dir" "$package_name")"
    IFS=$'\x1f' read -r claude_publish claude_install claude_plugin_name claude_install_hint claude_plugin_marketplace claude_plugin_marketplace_source <<< "$claude_policy_row"
    if [[ "$CODEX_ONLY" == true ]]; then
        claude_publish="false"
        claude_install="disabled"
        claude_plugin_name=""
        claude_install_hint=""
        claude_plugin_marketplace=""
        claude_plugin_marketplace_source=""
    fi

    echo -e "${YELLOW}⏳ 正在${OPERATION} bundle skills...${NC}"

    while IFS= read -r skill_md; do
        [[ -n "$skill_md" ]] || continue
        skill_dir="$(dirname "$skill_md")"
        skill_name="$(extract_skill_name "$skill_md" "$(basename "$skill_dir")")"
        relative_skill_dir="${skill_dir#$repo_dir/}"
        target_path="$install_root/$relative_skill_dir"

        assert_no_export_name_conflict "$skill_name" "$target_path"

        copy_skill_dir "$skill_dir" "$target_path"

        if ! run_security_check "$SECURITY_GUARD_SCRIPT" local "$target_path"; then
            cleanup_repo_snapshot "$repo_dir"
            echo -e "${RED}❌ bundle skill 本地安全深扫未通过: ${skill_name}${NC}"
            exit 1
        fi

        if ! write_source_metadata \
            "$target_path" \
            "$repo" \
            "$skill_name" \
            "bundle" \
            "$source_ref" \
            "$relative_skill_dir" \
            "$bundle_root" \
            "$update_group" \
            "$package_name" \
            "$claude_publish" \
            "$claude_install" \
            "$claude_plugin_name" \
            "$claude_install_hint" \
            "$claude_plugin_marketplace" \
            "$claude_plugin_marketplace_source" \
            "$([[ "$CODEX_ONLY" == true ]] && printf 'codex-only' || printf 'all')"; then
            cleanup_repo_snapshot "$repo_dir"
            echo -e "${RED}❌ 写入 bundle 来源元数据失败: ${target_path}/.skill-source.json${NC}"
            exit 1
        fi

        installed_count=$((installed_count + 1))
    done < <(find "$repo_dir/$bundle_root" -type f -name SKILL.md | sort)

    cleanup_repo_snapshot "$repo_dir"

    if [[ "$GLOBAL_INSTALL" == true ]]; then
        refresh_global_indexes
    fi

    if [[ "$claude_install" == "plugin" ]]; then
        ensure_claude_plugin_installed \
            "$claude_plugin_name" \
            "$claude_plugin_marketplace" \
            "$claude_plugin_marketplace_source" \
            "$claude_install_hint"
    fi

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ ${install_type}${OPERATION} bundle 成功！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}📍 来源: ${repo}${NC}"
    echo -e "${BLUE}📂 位置: ${install_location}${NC}"
    echo -e "${BLUE}📦 安装技能数: ${installed_count}${NC}"
    if [[ "$CODEX_ONLY" == true ]]; then
        echo -e "${BLUE}🔗 已仅发布到 Codex${NC}"
    elif [[ "$claude_publish" != "true" ]]; then
        echo -e "${YELLOW}⚠️ Claude Code 将改用插件安装，不通过 ~/.claude/skills 发布${NC}"
        if [[ -n "$claude_plugin_marketplace_source" ]]; then
            echo -e "${YELLOW}   插件市场: ${claude_plugin_marketplace_source}${NC}"
        fi
        if [[ -n "$claude_install_hint" ]]; then
            echo -e "${YELLOW}   目标命令: ${claude_install_hint}${NC}"
        fi
    fi
    echo ""
    exit 0
}

cleanup_rollback_backup() {
    if [[ -n "${ROLLBACK_BACKUP_DIR:-}" ]] && [[ -d "${ROLLBACK_BACKUP_DIR:-}" ]]; then
        rm -rf "$ROLLBACK_BACKUP_DIR"
    fi
    if [[ -n "${REPO_SNAPSHOT_DIR:-}" ]]; then
        cleanup_repo_snapshot "$REPO_SNAPSHOT_DIR"
    fi
}

rollback_after_failed_scan() {
    local target_path="$1"

    if [[ "$ROLLBACK_ON_FAIL" != true ]]; then
        return 1
    fi

    if [[ "$target_path" != "$INSTALL_ROOT/"* ]]; then
        echo -e "${YELLOW}⚠️ 回滚被跳过：目标路径不在安装根目录内 (${target_path})${NC}"
        return 1
    fi

    if [[ "$OPERATION" == "安装" ]]; then
        if [[ -e "$target_path" ]]; then
            rm -rf "$target_path"
            echo -e "${GREEN}↩️ 已回滚安装：删除 ${target_path}${NC}"
        fi
        return 0
    fi

    if [[ -z "${ROLLBACK_BACKUP_PATH:-}" ]] || [[ ! -e "${ROLLBACK_BACKUP_PATH:-}" ]]; then
        echo -e "${YELLOW}⚠️ 回滚失败：未找到更新前备份${NC}"
        return 1
    fi

    rm -rf "$target_path"
    cp -a "$ROLLBACK_BACKUP_PATH" "$target_path"
    echo -e "${GREEN}↩️ 已回滚更新：恢复 ${target_path}${NC}"
    return 0
}

# 解析参数
REPO=""
SKILL_NAME=""
BUNDLE_INSTALL=false
BUNDLE_ROOT=""
GLOBAL_INSTALL=false
CODEX_ONLY=false
ROLLBACK_ON_FAIL=true
ROLLBACK_BACKUP_DIR=""
ROLLBACK_BACKUP_PATH=""
REPO_SNAPSHOT_DIR=""

trap cleanup_rollback_backup EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill)
            if [[ $# -lt 2 || -z "${2:-}" || "${2:0:1}" == "-" ]]; then
                echo -e "${RED}❌ 错误: --skill 需要一个有效的 skill 名称${NC}"
                usage
            fi
            SKILL_NAME="$2"
            shift 2
            ;;
        --all-skills)
            BUNDLE_INSTALL=true
            shift
            ;;
        --bundle-root)
            if [[ $# -lt 2 || -z "${2:-}" || "${2:0:1}" == "-" ]]; then
                echo -e "${RED}❌ 错误: --bundle-root 需要一个有效目录${NC}"
                usage
            fi
            BUNDLE_ROOT="$2"
            shift 2
            ;;
        --global|-g)
            GLOBAL_INSTALL=true
            shift
            ;;
        --codex-only)
            CODEX_ONLY=true
            shift
            ;;
        --rollback-on-fail)
            ROLLBACK_ON_FAIL=true
            shift
            ;;
        --no-rollback-on-fail|--no-rollback)
            ROLLBACK_ON_FAIL=false
            shift
            ;;
        --help|-h) usage ;;
        --*)
            echo -e "${RED}❌ 错误: 未知参数 $1${NC}"
            usage
            ;;
        *)
            if [[ -n "$REPO" ]]; then
                echo -e "${RED}❌ 错误: 多余位置参数 $1${NC}"
                usage
            fi
            REPO="$1"
            shift
            ;;
    esac
done

# 验证参数
if [[ -z "$REPO" ]]; then
    echo -e "${RED}❌ 错误: 缺少必需参数${NC}"
    usage
fi

if [[ "$BUNDLE_INSTALL" != true && -z "$SKILL_NAME" ]]; then
    echo -e "${RED}❌ 错误: 缺少必需参数${NC}"
    usage
fi

if [[ "$BUNDLE_INSTALL" == true && -n "$SKILL_NAME" ]]; then
    echo -e "${RED}❌ 错误: --all-skills 不能与 --skill 同时使用${NC}"
    usage
fi

if [[ "$BUNDLE_INSTALL" == false ]] && [[ -n "$BUNDLE_ROOT" ]]; then
    echo -e "${RED}❌ 错误: --bundle-root 只能和 --all-skills 一起使用${NC}"
    echo -e "${RED}❌ 错误: 缺少必需参数${NC}"
    usage
fi

if [[ "$BUNDLE_INSTALL" != true ]] && ! command -v npx >/dev/null 2>&1; then
    echo -e "${RED}❌ 错误: 未找到 npx，请先安装 Node.js${NC}"
    exit 1
fi

SECURITY_GUARD_SCRIPT="$(resolve_security_guard_script || true)"
if [[ -z "$SECURITY_GUARD_SCRIPT" ]]; then
    echo -e "${RED}❌ 错误: 未找到 skill-security-guard 扫描器${NC}"
    echo -e "${YELLOW}请先确保以下路径存在其一：${NC}"
    echo "  - ~/.agents/skills/skill-security-guard/scripts/skill_security_guard.py"
    echo "  - ~/Workspace/my-ai-skills/skill-security-guard/scripts/skill_security_guard.py"
    exit 1
fi

# 确定安装位置和类型
if [[ "$GLOBAL_INSTALL" == true ]]; then
    ensure_source_repo_layout
    INSTALL_LOCATION="$SOURCE_SKILLS_DIR"
    INSTALL_TYPE="全局"
    INSTALL_ROOT="$SOURCE_SKILLS_DIR/packages/community"
    RUNTIME_ROOT="$RUNTIME_SKILLS_DIR"
else
    INSTALL_LOCATION="./.agents/skills"
    INSTALL_TYPE="项目级"
    INSTALL_ROOT="$(pwd)/.agents/skills"
    RUNTIME_ROOT="$INSTALL_ROOT"
fi

if [[ "$BUNDLE_INSTALL" == true ]]; then
    OPERATION="安装"
else
    if [[ "$GLOBAL_INSTALL" == true ]]; then
        PACKAGE_NAME="$(derive_package_name "$REPO")"
        TARGET_SKILL_PATH="$INSTALL_ROOT/$PACKAGE_NAME/$SKILL_NAME"
    else
        TARGET_SKILL_PATH="$INSTALL_ROOT/$SKILL_NAME"
    fi
    if [[ -e "$TARGET_SKILL_PATH" ]]; then
        OPERATION="更新"
    else
        OPERATION="安装"
    fi
fi

if [[ "$BUNDLE_INSTALL" == true ]]; then
    echo -e "${BLUE}📦 ${INSTALL_TYPE}${OPERATION} Bundle: $(derive_package_name "$REPO")${NC}"
else
    echo -e "${BLUE}📦 ${INSTALL_TYPE}${OPERATION} Skill: ${SKILL_NAME}${NC}"
fi
echo -e "${BLUE}📍 来源: ${REPO}${NC}"
echo -e "${BLUE}📂 位置: ${INSTALL_LOCATION}${NC}"
if [[ "$CODEX_ONLY" == true ]]; then
    echo -e "${BLUE}🧭 发布策略: 仅 Codex${NC}"
else
    echo -e "${BLUE}🧭 发布策略: 默认多平台${NC}"
fi
if [[ "$ROLLBACK_ON_FAIL" == true ]]; then
    echo -e "${BLUE}🧯 本地深扫失败自动回滚: 开启${NC}"
else
    echo -e "${YELLOW}🧯 本地深扫失败自动回滚: 关闭${NC}"
fi
echo ""

if [[ "$OPERATION" == "更新" ]] && [[ "$ROLLBACK_ON_FAIL" == true ]]; then
    ROLLBACK_BACKUP_DIR="$(mktemp -d)"
    ROLLBACK_BACKUP_PATH="$ROLLBACK_BACKUP_DIR/$SKILL_NAME"
    if ! cp -a "$TARGET_SKILL_PATH" "$ROLLBACK_BACKUP_PATH"; then
        echo -e "${RED}❌ 创建更新前备份失败，已终止更新${NC}"
        exit 1
    fi
fi

if [[ "$BUNDLE_INSTALL" == true ]]; then
    install_bundle_skills "$REPO" "$INSTALL_ROOT" "$BUNDLE_ROOT" "$INSTALL_LOCATION" "$INSTALL_TYPE"
fi

REPO_SNAPSHOT_DIR="$(prepare_repo_snapshot "$REPO")" || exit 1
SOURCE_REF="$(git -C "$REPO_SNAPSHOT_DIR" rev-parse HEAD 2>/dev/null || true)"
PACKAGE_NAME="$(derive_package_name "$REPO")"
UPDATE_GROUP="$(derive_update_group "$REPO")"
CLAUDE_POLICY_ROW="$(detect_claude_plugin_policy "$REPO_SNAPSHOT_DIR" "$PACKAGE_NAME")"
IFS=$'\x1f' read -r CLAUDE_PUBLISH CLAUDE_INSTALL CLAUDE_PLUGIN_NAME CLAUDE_INSTALL_HINT CLAUDE_PLUGIN_MARKETPLACE CLAUDE_PLUGIN_MARKETPLACE_SOURCE <<< "$CLAUDE_POLICY_ROW"
if [[ "$CODEX_ONLY" == true ]]; then
    CLAUDE_PUBLISH="false"
    CLAUDE_INSTALL="disabled"
    CLAUDE_PLUGIN_NAME=""
    CLAUDE_INSTALL_HINT=""
    CLAUDE_PLUGIN_MARKETPLACE=""
    CLAUDE_PLUGIN_MARKETPLACE_SOURCE=""
fi

if [[ "$GLOBAL_INSTALL" == true ]]; then
    SOURCE_SKILL_DIR="$(find_skill_dir_in_repo "$REPO_SNAPSHOT_DIR" "$SKILL_NAME" || true)"
    if [[ -z "${SOURCE_SKILL_DIR:-}" ]]; then
        echo -e "${RED}❌ 无法在仓库中定位 skill: ${SKILL_NAME}${NC}"
        exit 1
    fi

    TARGET_SKILL_PATH="$INSTALL_ROOT/$PACKAGE_NAME/$SKILL_NAME"
    assert_no_export_name_conflict "$SKILL_NAME" "$TARGET_SKILL_PATH"

    echo -e "${YELLOW}⏳ 正在${OPERATION}到源码层...${NC}"
    copy_skill_dir "$SOURCE_SKILL_DIR" "$TARGET_SKILL_PATH"
    echo -e "${GREEN}✅ Skill ${OPERATION}成功${NC}"
else
    # 使用 npx skills add（从临时本地副本安装）
    echo -e "${YELLOW}⏳ 正在${OPERATION}...${NC}"
    install_cmd=(npx skills add "$REPO_SNAPSHOT_DIR" --skill "$SKILL_NAME" -y)
    if [[ "$GLOBAL_INSTALL" == true ]]; then
        install_cmd+=(-g)
    fi

    if "${install_cmd[@]}"; then
        echo -e "${GREEN}✅ Skill ${OPERATION}成功${NC}"
    else
        echo -e "${RED}❌ ${OPERATION}失败${NC}"
        exit 1
    fi

    if [[ ! -d "$TARGET_SKILL_PATH" ]]; then
        FOUND_PATH="$(find "$INSTALL_ROOT" -maxdepth 2 -type d -name "$SKILL_NAME" 2>/dev/null | head -n 1 || true)"
        if [[ -n "${FOUND_PATH:-}" ]]; then
            TARGET_SKILL_PATH="$FOUND_PATH"
        fi
    fi

    if [[ ! -d "$TARGET_SKILL_PATH" ]]; then
        echo -e "${RED}❌ 无法定位已${OPERATION}的 skill 目录: ${TARGET_SKILL_PATH}${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}🔒 执行本地安全深扫...${NC}"
if ! run_security_check "$SECURITY_GUARD_SCRIPT" local "$TARGET_SKILL_PATH"; then
    echo -e "${RED}❌ 已${OPERATION}但安全检查未通过，请立即人工复核：${TARGET_SKILL_PATH}${NC}"
    if rollback_after_failed_scan "$TARGET_SKILL_PATH"; then
        echo -e "${YELLOW}⚠️ 已执行自动回滚，请复核后重试${NC}"
    elif [[ "$ROLLBACK_ON_FAIL" == true ]]; then
        echo -e "${YELLOW}⚠️ 自动回滚未成功，请手动处理当前目录状态${NC}"
    fi
    exit 1
fi

echo ""
echo -e "${YELLOW}📝 记录安装来源元数据...${NC}"
if write_source_metadata "$TARGET_SKILL_PATH" "$REPO" "$SKILL_NAME" "single" "$SOURCE_REF" "$SKILL_NAME" "" "$UPDATE_GROUP" "$PACKAGE_NAME" "$CLAUDE_PUBLISH" "$CLAUDE_INSTALL" "$CLAUDE_PLUGIN_NAME" "$CLAUDE_INSTALL_HINT" "$CLAUDE_PLUGIN_MARKETPLACE" "$CLAUDE_PLUGIN_MARKETPLACE_SOURCE" "$([[ "$CODEX_ONLY" == true ]] && printf 'codex-only' || printf 'all')"; then
    echo -e "${GREEN}✅ 来源元数据已更新: ${REPO}${NC}"
else
    echo -e "${RED}❌ 写入来源元数据失败: ${TARGET_SKILL_PATH}/.skill-source.json${NC}"
    exit 1
fi

# 后处理：仅全局安装需要更新列表
if [[ "$GLOBAL_INSTALL" == true ]]; then
    refresh_global_indexes
fi

if [[ "$CLAUDE_INSTALL" == "plugin" ]]; then
    ensure_claude_plugin_installed \
        "${CLAUDE_PLUGIN_NAME:-$PACKAGE_NAME}" \
        "$CLAUDE_PLUGIN_MARKETPLACE" \
        "$CLAUDE_PLUGIN_MARKETPLACE_SOURCE" \
        "$CLAUDE_INSTALL_HINT"
fi

# 成功提示
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ ${INSTALL_TYPE}${OPERATION}成功！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ "$GLOBAL_INSTALL" == true ]]; then
    echo -e "${BLUE}📍 源码层位置: ${TARGET_SKILL_PATH}${NC}"
    echo -e "${BLUE}📍 运行时位置: ${RUNTIME_ROOT}/${SKILL_NAME}${NC}"
    if [[ "$CODEX_ONLY" == true ]]; then
        echo -e "${BLUE}🔗 已仅发布到 Codex${NC}"
    else
        echo -e "${BLUE}🔗 已自动链接到所有 AI 编码工具${NC}"
    fi
    if [[ "$CLAUDE_INSTALL" == "plugin" ]]; then
        echo -e "${BLUE}🔌 Claude Code 插件已按平台策略自动处理${NC}"
    fi
    echo ""
    echo -e "${YELLOW}💡 提交到 Git:${NC}"
    echo "   cd $SOURCE_SKILLS_DIR"
    echo "   git add ."
    echo "   git commit -m \"feat: 安装 ${SKILL_NAME} skill\""
    echo "   git push"
else
    echo -e "${BLUE}📍 位置: ./.agents/skills/${SKILL_NAME}${NC}"
    echo -e "${BLUE}🔗 仅在当前项目可用${NC}"
    echo ""
    echo -e "${YELLOW}💡 如需提交到项目仓库:${NC}"
    echo "   git add .agents/skills/${SKILL_NAME}"
    echo "   git commit -m \"feat: 添加项目级 skill ${SKILL_NAME}\""
fi
echo ""
