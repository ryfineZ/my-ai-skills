#!/bin/bash
# skill-security-ci.sh - Central repository security gate for skills

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<'USAGE'
用法:
  shared/scripts/skill-security-ci.sh [选项]

选项:
  --repo-root <path>        仓库根目录（默认: 当前目录）
  --scope <changed|all>     扫描范围（默认: changed）
  --base <git-ref>          changed 模式基线（默认: origin/main）
  --head <git-ref>          changed 模式头部（默认: HEAD）
  --skills <a,b,c>          指定 skill 名称列表（覆盖 scope）
  --threshold <level>       失败阈值: low|medium|high|critical（默认: high）
  --output-dir <path>       报告输出目录（默认: .artifacts/skill-security）
  -h, --help                显示帮助

输出:
  <output-dir>/json/<skill>.json      每个 skill 的 JSON 报告
  <output-dir>/summary.json            聚合摘要 JSON
  <output-dir>/summary.sarif           聚合 SARIF

退出码:
  0  所有 skill 低于阈值
  1  命中阈值（阻断）
  2  扫描执行错误（如扫描器失败）
USAGE
}

contains_item() {
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

REPO_ROOT="$(pwd)"
SCOPE="changed"
BASE_REF="origin/main"
HEAD_REF="HEAD"
SKILLS_CSV=""
THRESHOLD="high"
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --scope)
            SCOPE="$2"
            shift 2
            ;;
        --base)
            BASE_REF="$2"
            shift 2
            ;;
        --head)
            HEAD_REF="$2"
            shift 2
            ;;
        --skills)
            SKILLS_CSV="$2"
            shift 2
            ;;
        --threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            usage
            exit 2
            ;;
    esac
done

REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$REPO_ROOT/.artifacts/skill-security"
fi

case "$SCOPE" in
    changed|all) ;;
    *)
        echo -e "${RED}❌ --scope 仅支持 changed 或 all${NC}"
        exit 2
        ;;
esac

case "$THRESHOLD" in
    low|medium|high|critical) ;;
    *)
        echo -e "${RED}❌ --threshold 仅支持 low|medium|high|critical${NC}"
        exit 2
        ;;
esac

SCANNER="$REPO_ROOT/skill-security-guard/scripts/skill_security_guard.py"
if [[ ! -f "$SCANNER" ]]; then
    SCANNER="$REPO_ROOT/packages/core/skill-security-guard/scripts/skill_security_guard.py"
fi
if [[ ! -f "$SCANNER" ]]; then
    echo -e "${RED}❌ 未找到扫描器: $SCANNER${NC}"
    exit 2
fi

mkdir -p "$OUTPUT_DIR/json"

SKILL_DIRS=()
SEARCH_ROOT="$REPO_ROOT"
if [[ -d "$REPO_ROOT/packages" ]]; then
    SEARCH_ROOT="$REPO_ROOT/packages"
fi

discover_all_skills() {
    find "$SEARCH_ROOT" -type f -name SKILL.md | while IFS= read -r skill_md; do
        [[ -n "$skill_md" ]] || continue
        dirname "$skill_md"
    done
}

if [[ -n "$SKILLS_CSV" ]]; then
    IFS=',' read -r -a INPUT_SKILLS <<< "$SKILLS_CSV"
    for raw in "${INPUT_SKILLS[@]}"; do
        skill_name="$(echo "$raw" | xargs)"
        [[ -z "$skill_name" ]] && continue
        candidate="$(find "$SEARCH_ROOT" -type f -name SKILL.md -path "*/$skill_name/SKILL.md" | head -n 1 | xargs dirname 2>/dev/null || true)"
        if [[ -z "$candidate" || ! -d "$candidate" || ! -f "$candidate/SKILL.md" ]]; then
            echo -e "${RED}❌ 指定 skill 不存在或缺少 SKILL.md: $skill_name${NC}"
            exit 2
        fi
        if ! contains_item "$candidate" "${SKILL_DIRS[@]-}"; then
            SKILL_DIRS+=("$candidate")
        fi
    done
else
    if [[ "$SCOPE" == "all" ]]; then
        while IFS= read -r dir; do
            [[ -n "$dir" ]] || continue
            if ! contains_item "$dir" "${SKILL_DIRS[@]-}"; then
                SKILL_DIRS+=("$dir")
            fi
        done < <(discover_all_skills)
    else
        if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            CHANGED_FILES=""
            if ! CHANGED_FILES="$(git -C "$REPO_ROOT" diff --name-only "$BASE_REF" "$HEAD_REF" 2>/dev/null)"; then
                echo -e "${YELLOW}⚠️ 无法比较 $BASE_REF..$HEAD_REF，回退为全量扫描${NC}"
                SCOPE="all"
                while IFS= read -r dir; do
                    [[ -n "$dir" ]] || continue
                    if ! contains_item "$dir" "${SKILL_DIRS[@]-}"; then
                        SKILL_DIRS+=("$dir")
                    fi
                done < <(discover_all_skills)
            fi

            if [[ -z "${CHANGED_FILES:-}" ]]; then
                echo -e "${YELLOW}ℹ️ 未检测到变更文件（$BASE_REF..$HEAD_REF）${NC}"
            else
                while IFS= read -r rel; do
                    [[ -z "$rel" ]] && continue
                    abs="$REPO_ROOT/$rel"
                    current="$abs"
                    while [[ "$current" != "$REPO_ROOT" && "$current" != "/" ]]; do
                        if [[ -f "$current/SKILL.md" ]]; then
                            if ! contains_item "$current" "${SKILL_DIRS[@]-}"; then
                                SKILL_DIRS+=("$current")
                            fi
                            break
                        fi
                        current="$(dirname "$current")"
                    fi
                done <<< "$CHANGED_FILES"
            fi
        else
            echo -e "${YELLOW}⚠️ 当前目录不是 git 仓库，回退为全量扫描${NC}"
            while IFS= read -r dir; do
                [[ -n "$dir" ]] || continue
                if ! contains_item "$dir" "${SKILL_DIRS[@]-}"; then
                    SKILL_DIRS+=("$dir")
                fi
            done < <(discover_all_skills)
        fi
    fi
fi

SUMMARY_JSON="$OUTPUT_DIR/summary.json"
SUMMARY_SARIF="$OUTPUT_DIR/summary.sarif"

if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
    echo -e "${YELLOW}ℹ️ 没有需要扫描的 skill，输出空报告${NC}"
    cat > "$SUMMARY_JSON" <<JSON
{
  "scope": "$SCOPE",
  "base_ref": "$BASE_REF",
  "head_ref": "$HEAD_REF",
  "threshold": "$THRESHOLD",
  "skills_scanned": 0,
  "totals": {
    "CRITICAL": 0,
    "HIGH": 0,
    "MEDIUM": 0,
    "LOW": 0
  },
  "gate": {
    "status": "PASS",
    "reason": "no skills changed"
  }
}
JSON
    cat > "$SUMMARY_SARIF" <<'SARIF'
{
  "version": "2.1.0",
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "skill-security-guard",
          "informationUri": "https://github.com",
          "rules": []
        }
      },
      "results": []
    }
  ]
}
SARIF
    echo -e "${GREEN}✅ Gate PASS${NC}"
    exit 0
fi

echo -e "${BLUE}🔍 Skill Security CI${NC}"
echo -e "${BLUE}Repo: $REPO_ROOT${NC}"
echo -e "${BLUE}Scope: $SCOPE${NC}"
echo -e "${BLUE}Threshold: $THRESHOLD${NC}"
echo -e "${BLUE}Output: $OUTPUT_DIR${NC}"
if [[ "$SCOPE" == "changed" && -z "$SKILLS_CSV" ]]; then
    echo -e "${BLUE}Diff: $BASE_REF..$HEAD_REF${NC}"
fi
echo ""

declare -a JSON_REPORTS=()
SCAN_ERROR=0

for skill_dir in "${SKILL_DIRS[@]}"; do
    skill_name="$(basename "$skill_dir")"
    report_path="$OUTPUT_DIR/json/$skill_name.json"

    echo -e "${YELLOW}⏳ 扫描 $skill_name ...${NC}"
    if python3 "$SCANNER" --json --min-severity low local --path "$skill_dir" > "$report_path"; then
        :
    else
        rc=$?
        if [[ "$rc" -eq 4 ]]; then
            echo -e "${RED}❌ 扫描执行失败: $skill_name${NC}"
            SCAN_ERROR=1
        else
            # 1/2/3 代表发现风险，报告仍有效
            :
        fi
    fi

    if [[ -s "$report_path" ]]; then
        JSON_REPORTS+=("$report_path")
    else
        echo -e "${RED}❌ 报告为空: $skill_name${NC}"
        SCAN_ERROR=1
    fi

done

if [[ "$SCAN_ERROR" -ne 0 ]]; then
    echo -e "${RED}❌ 存在扫描执行错误，Gate FAIL${NC}"
    exit 2
fi

export SEC_CI_SCOPE="$SCOPE"
export SEC_CI_BASE_REF="$BASE_REF"
export SEC_CI_HEAD_REF="$HEAD_REF"

if python3 - "$THRESHOLD" "$SUMMARY_JSON" "$SUMMARY_SARIF" "${JSON_REPORTS[@]-}" <<'PY'
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path

threshold = sys.argv[1].lower()
summary_json = Path(sys.argv[2])
summary_sarif = Path(sys.argv[3])
report_paths = [Path(p) for p in sys.argv[4:]]

sev_rank = {"LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}
threshold_rank = sev_rank[threshold.upper()]

skill_reports = []
totals = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}
all_results = []
rules = {}
max_rank_seen = 0

for report_path in report_paths:
    data = json.load(open(report_path, "r", encoding="utf-8"))
    summary = data.get("summary", {})
    counts = summary.get("severity_counts", {})
    verdict = summary.get("verdict", "UNKNOWN")

    for key in totals:
        totals[key] += int(counts.get(key, 0))

    findings = data.get("findings", [])
    local_max = 0
    for finding in findings:
        sev = str(finding.get("severity", "LOW")).upper()
        rank = sev_rank.get(sev, 1)
        local_max = max(local_max, rank)
        max_rank_seen = max(max_rank_seen, rank)

    skill_reports.append(
        {
            "skill": Path(report_path).stem,
            "report": str(report_path),
            "target": data.get("target"),
            "files_scanned": data.get("files_scanned", 0),
            "verdict": verdict,
            "severity_counts": {k: int(counts.get(k, 0)) for k in totals.keys()},
            "max_severity": next((k for k, v in sev_rank.items() if v == local_max), "NONE") if local_max else "NONE",
        }
    )

    for finding in findings:
        sev = str(finding.get("severity", "LOW")).upper()
        rule_id = str(finding.get("rule_id") or "UNKNOWN_RULE")
        normalized_rule = re.sub(r"_\d+$", "", rule_id)

        if normalized_rule not in rules:
            rules[normalized_rule] = {
                "id": normalized_rule,
                "name": normalized_rule,
                "shortDescription": {"text": finding.get("title") or normalized_rule},
                "fullDescription": {"text": finding.get("detail") or finding.get("title") or normalized_rule},
                "help": {"text": finding.get("recommendation") or "Review this finding manually."},
            }

        level = "note"
        if sev in ("CRITICAL", "HIGH"):
            level = "error"
        elif sev == "MEDIUM":
            level = "warning"

        file_path = str(finding.get("file_path") or "unknown")
        skill_name = Path(report_path).stem
        artifact_uri = f"{skill_name}/{file_path}"
        start_line = int(finding.get("line_number") or 1)

        all_results.append(
            {
                "ruleId": normalized_rule,
                "level": level,
                "message": {
                    "text": f"[{sev}] {finding.get('title', normalized_rule)} - {finding.get('detail', '')}"
                },
                "locations": [
                    {
                        "physicalLocation": {
                            "artifactLocation": {"uri": artifact_uri},
                            "region": {"startLine": max(start_line, 1)},
                        }
                    }
                ],
                "properties": {
                    "severity": sev,
                    "category": finding.get("category"),
                    "confidence": finding.get("confidence"),
                    "recommendation": finding.get("recommendation"),
                    "skill": skill_name,
                    "rule_id_raw": rule_id,
                },
            }
        )

status = "PASS" if max_rank_seen < threshold_rank else "FAIL"

summary = {
    "generated_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
    "scope": os.environ.get("SEC_CI_SCOPE", "unknown"),
    "base_ref": os.environ.get("SEC_CI_BASE_REF", "unknown"),
    "head_ref": os.environ.get("SEC_CI_HEAD_REF", "unknown"),
    "threshold": threshold.upper(),
    "skills_scanned": len(skill_reports),
    "skills": skill_reports,
    "totals": totals,
    "gate": {
        "status": status,
        "max_severity_seen": next((k for k, v in sev_rank.items() if v == max_rank_seen), "NONE") if max_rank_seen else "NONE",
        "reason": "severity threshold reached" if status == "FAIL" else "all findings below threshold",
    },
}

sarif = {
    "version": "2.1.0",
    "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
    "runs": [
        {
            "tool": {
                "driver": {
                    "name": "skill-security-guard",
                    "informationUri": "https://github.com",
                    "rules": list(rules.values()),
                }
            },
            "results": all_results,
        }
    ],
}

summary_json.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
summary_sarif.write_text(json.dumps(sarif, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"[summary] skills={len(skill_reports)} totals={totals} threshold={threshold.upper()} gate={status}")

if status == "FAIL":
    raise SystemExit(1)
PY
then
    PY_RC=0
else
    PY_RC=$?
fi

if [[ "$PY_RC" -ne 0 ]]; then
    echo -e "${RED}❌ Gate FAIL: 命中阈值 ${THRESHOLD}${NC}"
    echo -e "${YELLOW}报告路径:${NC}"
    echo "  - $SUMMARY_JSON"
    echo "  - $SUMMARY_SARIF"
    exit 1
fi

echo -e "${GREEN}✅ Gate PASS: 所有 findings 低于阈值 ${THRESHOLD}${NC}"
echo -e "${BLUE}报告路径:${NC}"
echo "  - $SUMMARY_JSON"
echo "  - $SUMMARY_SARIF"
