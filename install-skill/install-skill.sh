#!/bin/bash
# install-skill - 安装 skills（支持全局和项目级）

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "用法: $0 <owner/repo> --skill <skill-name> [--global]"
    echo ""
    echo "示例:"
    echo "  $0 vercel-labs/agent-skills --skill frontend-design --global"
    echo "  $0 anthropics/skills --skill planning"
    echo ""
    echo "参数:"
    echo "  --global, -g    全局安装（到 ~/.agents/skills，跨项目共享）"
    echo "  不带 -g         项目级安装（到 ./.agents/skills，仅当前项目）"
    echo ""
    echo "说明:"
    echo "  安装和更新都会强制执行安全检查（远程预审 + 本地深扫）"
    exit 1
}

resolve_security_guard_script() {
    local candidates=(
        "$HOME/.agents/skills/skill-security-guard/scripts/skill_security_guard.py"
        "$HOME/Workspace/my-ai-skills/skill-security-guard/scripts/skill_security_guard.py"
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
    if [[ "$mode" == "github" ]]; then
        cmd+=(--repo "$target")
    else
        cmd+=(--path "$target")
    fi

    set +e
    if [[ "$mode" == "github" ]] && [[ -n "${SECURITY_SCAN_GITHUB_TOKEN:-}" ]]; then
        GITHUB_TOKEN="$SECURITY_SCAN_GITHUB_TOKEN" "${cmd[@]}" >"$report_file"
        rc=$?
    else
        "${cmd[@]}" >"$report_file"
        rc=$?
    fi
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

resolve_github_token_for_scan() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "$GITHUB_TOKEN"
        return 0
    fi
    if command -v gh >/dev/null 2>&1; then
        local token
        token="$(gh auth token 2>/dev/null || true)"
        if [[ -n "$token" ]]; then
            echo "$token"
            return 0
        fi
    fi
    return 1
}

# 解析参数
REPO=""
SKILL_NAME=""
GLOBAL_INSTALL=false

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
        --global|-g)
            GLOBAL_INSTALL=true
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
if [[ -z "$REPO" ]] || [[ -z "$SKILL_NAME" ]]; then
    echo -e "${RED}❌ 错误: 缺少必需参数${NC}"
    usage
fi

if ! command -v npx >/dev/null 2>&1; then
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

SECURITY_SCAN_GITHUB_TOKEN="$(resolve_github_token_for_scan || true)"
if [[ -z "$SECURITY_SCAN_GITHUB_TOKEN" ]]; then
    echo -e "${YELLOW}⚠️ 未检测到 GitHub Token，远程预审可能受 API 速率限制${NC}"
fi

# 确定安装位置和类型
if [[ "$GLOBAL_INSTALL" == true ]]; then
    INSTALL_LOCATION="~/.agents/skills"
    INSTALL_TYPE="全局"
    INSTALL_ROOT="$HOME/.agents/skills"
else
    INSTALL_LOCATION="./.agents/skills"
    INSTALL_TYPE="项目级"
    INSTALL_ROOT="$(pwd)/.agents/skills"
fi

TARGET_SKILL_PATH="$INSTALL_ROOT/$SKILL_NAME"
if [[ -e "$TARGET_SKILL_PATH" ]]; then
    OPERATION="更新"
else
    OPERATION="安装"
fi

echo -e "${BLUE}📦 ${INSTALL_TYPE}${OPERATION} Skill: ${SKILL_NAME}${NC}"
echo -e "${BLUE}📍 来源: ${REPO}${NC}"
echo -e "${BLUE}📂 位置: ${INSTALL_LOCATION}${NC}"
echo ""

echo -e "${YELLOW}🔒 执行远程安全预审...${NC}"
if ! run_security_check "$SECURITY_GUARD_SCRIPT" github "$REPO"; then
    echo -e "${RED}❌ 已阻断${OPERATION}，请先处理远程仓库风险${NC}"
    exit 1
fi

# 使用 npx skills add（非交互式）
echo -e "${YELLOW}⏳ 正在${OPERATION}...${NC}"
install_cmd=(npx skills add "$REPO" --skill "$SKILL_NAME" -y)
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

echo ""
echo -e "${YELLOW}🔒 执行本地安全深扫...${NC}"
if ! run_security_check "$SECURITY_GUARD_SCRIPT" local "$TARGET_SKILL_PATH"; then
    echo -e "${RED}❌ 已${OPERATION}但安全检查未通过，请立即人工复核：${TARGET_SKILL_PATH}${NC}"
    exit 1
fi

# 后处理：仅全局安装需要更新列表
if [[ "$GLOBAL_INSTALL" == true ]]; then
    echo ""
    echo -e "${YELLOW}⏳ 正在更新 skills 列表...${NC}"

    UPDATE_SCRIPT=""
    UPDATE_ROOT=""
    if [[ -f "$HOME/.agents/skills/shared/scripts/update-skills-list.sh" ]]; then
        UPDATE_SCRIPT="$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
        UPDATE_ROOT="$HOME/.agents/skills"
    elif [[ -f "$HOME/Workspace/my-ai-skills/shared/scripts/update-skills-list.sh" ]]; then
        UPDATE_SCRIPT="$HOME/Workspace/my-ai-skills/shared/scripts/update-skills-list.sh"
        UPDATE_ROOT="$HOME/Workspace/my-ai-skills"
    fi

    if [[ -n "$UPDATE_SCRIPT" ]]; then
        if SKILLS_DIR="$UPDATE_ROOT" bash "$UPDATE_SCRIPT"; then
            echo -e "${GREEN}✅ Skills 列表已更新${NC}"
        else
            echo -e "${YELLOW}⚠️  Skills 列表更新失败，请手动执行：SKILLS_DIR=\"$UPDATE_ROOT\" bash \"$UPDATE_SCRIPT\"${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  未找到 update-skills-list.sh，已跳过列表更新${NC}"
    fi
fi

# 成功提示
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ ${INSTALL_TYPE}${OPERATION}成功！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ "$GLOBAL_INSTALL" == true ]]; then
    echo -e "${BLUE}📍 位置: ~/.agents/skills/${SKILL_NAME}${NC}"
    echo -e "${BLUE}🔗 已自动链接到所有 AI 编码工具${NC}"
    echo ""
    echo -e "${YELLOW}💡 提交到 Git:${NC}"
    echo "   cd ~/.agents/skills  # 或 cd ~/Workspace/my-ai-skills"
    echo "   git add ${SKILL_NAME} INSTALLED_SKILLS.md"
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
