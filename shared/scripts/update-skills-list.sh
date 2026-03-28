#!/bin/bash

# 自动更新 INSTALLED_SKILLS.md 中的 Skills 列表
# 从每个 skill 的 SKILL.md frontmatter 中提取名字/用途/触发关键词

set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"

if [[ -f "$SKILLS_DIR/.skillsrc" ]]; then
    # shellcheck disable=SC1090
    source "$SKILLS_DIR/.skillsrc"
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "❌ 中央仓库不存在: $SKILLS_DIR"
    exit 1
fi

REPO_ROOT="$(cd "$SKILLS_DIR" && pwd -P)"
SKILLS_DOC="$REPO_ROOT/INSTALLED_SKILLS.md"

discover_skill_files() {
    local entry=""
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        [[ -e "$entry" ]] || continue
        [[ -f "$entry/SKILL.md" ]] || continue
        printf '%s\n' "$entry/SKILL.md"
    done < <(find "$REPO_ROOT" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | sort)
}

# 临时文件
SKILLS_DATA=$(mktemp)
EXISTING_META=$(mktemp)

echo "🔍 正在扫描已安装的 skills..."
echo "📁 仓库路径: $REPO_ROOT"

# 读取现有列表中的中文描述与触发关键词（用于保留）

if [[ -f "$SKILLS_DOC" ]]; then
SKILLS_DOC="$SKILLS_DOC" python3 - <<'PY' > "$EXISTING_META"
import os
import re
from pathlib import Path

path = os.environ.get("SKILLS_DOC")
if not path or not os.path.exists(path):
    raise SystemExit(0)

text = Path(path).read_bytes().decode("utf-8", errors="replace")
pattern = re.compile(r'^###\s+(.+?)\n(.*?)(?=^###\s+|^##\s+|\Z)', re.M | re.S)

for name, block in pattern.findall(text):
    zh = ""
    kw = ""
    m = re.search(r'^\*\*中文描述：\*\*\s*(.*)$', block, re.M)
    if m:
        zh = m.group(1).strip()
    if not zh:
        m = re.search(r'^\*\*用途：\*\*\s*(.*)$', block, re.M)
        if m:
            zh = m.group(1).strip()
    m = re.search(r'^\*\*触发关键词：\*\*\s*(.*)$', block, re.M)
    if m:
        kw = m.group(1).strip()
    if zh or kw:
        print(f"{name}\t{zh}\t{kw}")
PY

fi

# 按名称查找已存在的中文描述（兼容 macOS bash 3.2）
get_zh_desc() {
    local skill_name="$1"
    awk -F '\t' -v name="$skill_name" '$1==name {print $2; exit}' "$EXISTING_META"
}

get_keywords() {
    local skill_name="$1"
    awk -F '\t' -v name="$skill_name" '$1==name {print $3; exit}' "$EXISTING_META"
}

is_placeholder_meta() {
    local value="${1:-}"
    [[ -z "$value" || "$value" == "（待补充）" || "$value" == "(待补充)" || "$value" == "待补充" ]]
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

extract_skill_meta() {
    local skill_file="$1"
    python3 - "$skill_file" <<'PY'
import re
import sys

path = sys.argv[1]
try:
    content = open(path, "r", encoding="utf-8").read()
except Exception:
    print("\t\t")
    raise SystemExit(0)

match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
frontmatter = match.group(1) if match else ""

def clean(text: str) -> str:
    text = re.sub(r"\s+", " ", text or "")
    text = text.replace("\t", " ").replace("|", " ")
    return text.strip()

def has_cjk(text: str) -> bool:
    return bool(re.search(r"[\u4e00-\u9fff]", text or ""))

def short_sentence(text: str, max_len: int = 72) -> str:
    text = clean(text)
    if not text:
        return ""
    sentence = re.split(r"[。！？.!?]", text, maxsplit=1)[0].strip()
    if len(sentence) < 6:
        sentence = text
    if len(sentence) > max_len:
        sentence = sentence[: max_len - 3].rstrip() + "..."
    return sentence

name = ""
description = ""
raw_keywords = []
pending_list_key = None

for raw_line in frontmatter.splitlines():
    line = raw_line.rstrip()
    stripped = line.strip()
    if pending_list_key:
        if stripped.startswith("-"):
            token = stripped[1:].strip().strip('"').strip("'")
            if token:
                raw_keywords.append(token)
            continue
        if stripped:
            pending_list_key = None

    line = stripped
    if not line or ":" not in line:
        continue
    key, value = line.split(":", 1)
    key = key.strip().lower()
    value = value.strip().strip('"').strip("'")
    if key == "name":
        name = value
    elif key == "description":
        description = value
    elif key in {"keywords", "triggers", "tags", "trigger_keywords"}:
        if not value:
            pending_list_key = key
            continue
        if value.startswith("[") and value.endswith("]"):
            value = value[1:-1]
        parts = re.split(r"[，,;；/|]+", value)
        for part in parts:
            part = part.strip().strip('"').strip("'")
            if part:
                raw_keywords.append(part)

description = clean(description)
lower_haystack = f"{name} {description}".lower()

rules = [
    ((r"\bdoctor-skills\b", r"\bverify\.sh\b", r"diagnos(e|ing)", r"中央 skills 仓库状态", r"lightweight repair"), "诊断中央 skills 仓库状态并执行轻量修复", ["仓库诊断", "verify.sh", "轻量修复"]),
    ((r"\buninstall-skill\b", r"\buninstall\b", r"\bremove\b", r"delete installed", r"删除并自动刷新平台"), "删除已安装 skill 并清理平台发布状态", ["卸载 skill", "删除 skill", "平台清理"]),
    ((r"\bupdate-skill\b", r"\bupdate_group\b", r"bundle-aware", r"基于 \.skill-source\.json 更新", r"已安装 skill"), "更新已安装 skill 并按来源回放 bundle 变更", ["更新 skill", "bundle 更新", "skill-source.json"]),
    ((r"\bdeep research\b", r"multi-step research", r"competitive landscaping", r"literature reviews?", r"due diligence"), "执行多步骤深度调研并输出带引用报告", ["深度调研", "带引用报告", "Gemini"]),
    ((r"\btavily\b", r"\bweb search\b", r"search api integration"), "通过 Tavily API 执行网页搜索", ["Tavily", "网页搜索", "API"]),
    ((r"\binstall\b", r"skills add", r"github", r"\brepositor(?:y|ies)\b"), "安装和更新 skill", ["安装 skill", "更新 skill", "GitHub 仓库"]),
    ((r"\bcreate-skill\b", r"\bskill-creator\b", r"creating effective skills", r"\bcustom skill\b", r"\bnew skill\b"), "创建和维护 skill", ["创建 skill", "维护 skill", "自定义 skill"]),
    ((r"\bsecurity\b", r"\baudit\b", r"\bscan\b", r"\brisk\b", r"\bguard\b", r"prompt injection", r"\bmalicious\b"), "执行 skill 安全审计与风险拦截", ["安全审计", "风险扫描", "Prompt Injection"]),
    ((r"\bbrowser\b", r"\bweb testing\b", r"\bform filling\b", r"\bscreenshot(s)?\b", r"\bdata extraction\b"), "自动化浏览器交互与网页数据提取", ["浏览器自动化", "网页测试", "截图", "数据提取"]),
    ((r"\bfrontend\b", r"\bui\b", r"\bux\b", r"\bcomponent(s)?\b", r"\binterface(s)?\b", r"\blanding page\b", r"\bdashboard\b"), "设计和审查前端界面与交互体验", ["前端设计", "UI", "UX", "组件"]),
    ((r"\bplanning\b", r"\btask[_ -]?plan\b", r"\bcomplex tasks?\b", r"\bworkflow\b"), "规划复杂任务并沉淀执行计划", ["任务规划", "执行计划", "工作流"]),
    ((r"\bgit commit\b", r"\bconventional commit\b", r"\bcommit message\b"), "生成规范化 Git 提交", ["Git Commit", "约定式提交"]),
    ((r"\bseo\b", r"\branking\b", r"\bmeta tags?\b"), "审计网站 SEO 与页面优化问题", ["SEO 审计", "站内优化", "Meta 标签"]),
    ((r"\bnotebooklm\b", r"\bcitation\b"), "基于 NotebookLM 进行来源可追溯检索", ["NotebookLM", "来源引用", "文档检索"]),
    ((r"\bpull request\b", r"\bpr comments?\b", r"\breview comments?\b", r"\bgh cli\b", r"address comments"), "处理 GitHub PR 评论并回写修复", ["PR 评论", "代码审查", "gh CLI"]),
    ((r"\bhumanize(r)?\b", r"\bgptzero\b", r"\bai detector\b"), "优化文本表达并降低 AI 写作痕迹", ["文本润色", "去 AI 痕迹", "AI 检测"]),
]

matched_rules = []
for patterns, summary_text, keywords_text in rules:
    if any(re.search(pattern, lower_haystack) for pattern in patterns):
        matched_rules.append((summary_text, keywords_text))

summary = ""
if has_cjk(description):
    summary = short_sentence(description)
elif matched_rules:
    summary_parts = []
    for item, _keywords in matched_rules:
        if item not in summary_parts:
            summary_parts.append(item)
        if len(summary_parts) >= 2:
            break
    summary = "用于" + "、".join(summary_parts) + "。"
elif description:
    summary = f"用于 {name}：{short_sentence(description, max_len=44)}"
else:
    summary = f"用于 {name} 相关工作流。"

stopwords_en = {
    "a", "an", "the", "and", "or", "for", "with", "from", "when", "this", "that", "your", "into",
    "use", "using", "used", "supports", "support", "skill", "skills", "guide", "based", "help",
    "helps", "through", "across", "before", "after", "check", "checks", "install", "update", "create",
    "run", "runs", "workflow", "workflows", "local", "global", "all", "any",
    "generates", "users", "asks", "questions", "like", "project", "projects", "project-level", "shared"
}
stopwords_zh = {"用于", "以及", "相关", "支持", "自动", "执行", "进行", "能力", "流程", "工具"}

keywords = []

def add_keyword(token: str) -> None:
    token = clean(token).strip("`'\"()[]{}.,;: ")
    if not token:
        return
    if len(token) > 40:
        return
    if token.lower() in stopwords_en:
        return
    if token in stopwords_zh:
        return
    if token not in keywords:
        keywords.append(token)

add_keyword(name)

for token in raw_keywords:
    add_keyword(token)

if has_cjk(description):
    common_phrases = [
        "安全审计", "提示词劫持", "下载执行", "凭证窃取", "数据外传", "持久化", "提权风险",
        "风险结论", "安装前审计", "安装后检查", "代码质量", "约定式提交", "任务规划",
        "浏览器自动化", "前端设计", "可访问性", "规则同步", "文档检索", "SEO 审计"
    ]
    for phrase in common_phrases:
        if phrase in description:
            add_keyword(phrase)

    for segment in re.split(r"[，,。；;、：:（）()\[\]]+", description):
        segment = clean(segment)
        segment = re.sub(r"^(用于|支持|通过|对|在|并|可|会|当用户|用于对)", "", segment)
        segment = segment.strip()
        if not segment:
            continue
        if len(segment) > 14:
            continue
        if re.search(r"[A-Za-z]{3,}", segment):
            continue
        add_keyword(segment)
else:
    for _summary_text, rule_keywords in matched_rules:
        for token in rule_keywords:
            add_keyword(token)

    important_words = {
        "react", "next.js", "vue", "svelte", "flutter", "swiftui", "tailwind", "shadcn/ui",
        "github", "notebooklm", "gemini", "seo", "mcp", "json", "sarif", "ux", "ui", "pr", "cli"
    }
    for word in re.findall(r"[A-Za-z][A-Za-z0-9+./#-]{1,20}", f"{name} {description}"):
        token = word.strip(".,;:()[]{}")
        if not token:
            continue
        lower = token.lower()
        if lower in stopwords_en:
            continue
        has_inner_upper = any(ch.isupper() for ch in token[1:])
        if lower in important_words or token.isupper() or has_inner_upper or any(ch in token for ch in ".+/#-"):
            add_keyword(token)

if len(keywords) < 2:
    add_keyword("技能管理")

keywords_text = "、".join(keywords[:10])
print(f"{clean(name)}\t{clean(summary)}\t{clean(keywords_text)}")
PY
}

# 计数器
custom_count=0
community_count=0

# 扫描所有已发布的 skill 目录
while IFS= read -r skill_file; do
    if [[ -z "$skill_file" ]]; then
        continue
    fi
    skill_dir="$(dirname "$skill_file")"
    dir_name="$(basename "$skill_dir")"
    dir_rel="${skill_dir#$REPO_ROOT/}"

    skill_meta="$(extract_skill_meta "$skill_file")"
    IFS=$'\t' read -r name auto_desc auto_keywords <<< "$skill_meta"
    effective_name="$name"

    # 如果没有提取到 name，使用目录名
    if [[ -z "$effective_name" ]]; then
        effective_name="$dir_name"
        name="$dir_name"
    fi

    # 判断来源：只有 skill-creator 创建的才算自建，其它一律视为社区
    source="community"
    source_repo=""
    source_type=""
    package_name=""
    ai_desc=""
    ai_keywords=""
    source_meta="$skill_dir/.skill-source.json"
    if [[ -f "$source_meta" ]]; then
        source_meta_row="$(python3 - "$source_meta" <<'PY'
import json, sys

path = sys.argv[1]
try:
    data = json.load(open(path, "r", encoding="utf-8"))
except Exception:
    data = {}

def clean(v):
    if v is None:
        return ""
    s = str(v).replace("\n", " ").replace("\t", " ").replace("|", " ")
    return " ".join(s.split()).strip()

source = clean(data.get("source"))
source_repo = clean(data.get("source_repo"))
source_type = clean(data.get("source_type"))
package_name = clean(data.get("package_name"))
usage_zh = clean(data.get("usage_zh") or data.get("purpose_zh"))
keywords = data.get("trigger_keywords") or data.get("keywords_zh") or []
if isinstance(keywords, list):
    kw_text = "、".join(clean(item) for item in keywords if clean(item))
else:
    kw_text = clean(keywords)

print(f"{source}\x1f{source_repo}\x1f{source_type}\x1f{package_name}\x1f{usage_zh}\x1f{kw_text}")
PY
)"
        IFS=$'\x1f' read -r source source_repo source_type package_name ai_desc ai_keywords <<< "$source_meta_row"
    fi

    if [[ "$source" == "custom" ]]; then
        ((custom_count++))
    else
        source="community"
        if [[ -n "$source_repo" && "$source_type" == "bundle" && -n "$package_name" ]]; then
            source_repo="$source_repo (bundle: $package_name)"
        elif [[ -z "$source_repo" && -n "$package_name" ]]; then
            source_repo="$package_name"
        elif [[ -z "$source_repo" ]]; then
            source_repo="（未记录）"
        fi
        ((community_count++))
    fi

    existing_desc="$(get_zh_desc "$name")"
    existing_keywords="$(get_keywords "$name")"

    # 优先级：install-skill 的 AI 元数据 > 历史手工值 > 自动提取兜底
    zh_desc="$ai_desc"
    keywords="$ai_keywords"

    if is_placeholder_meta "$zh_desc"; then
        zh_desc="$existing_desc"
    fi
    if is_placeholder_meta "$keywords"; then
        keywords="$existing_keywords"
    fi
    if is_placeholder_meta "$zh_desc"; then
        zh_desc="$auto_desc"
    fi
    if is_placeholder_meta "$keywords"; then
        keywords="$auto_keywords"
    fi
    if is_placeholder_meta "$zh_desc"; then
        zh_desc="（待补充）"
    fi
    if is_placeholder_meta "$keywords"; then
        keywords="（待补充）"
    fi

    # 存储数据（使用 Unit Separator 作为分隔符，避免空字段错位）
    printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\n' \
        "$source" "$name" "$dir_rel" "$source_repo" "$zh_desc" "$keywords" >> "$SKILLS_DATA"
done < <(discover_skill_files)

# 按类型和名称排序
sort "$SKILLS_DATA" -o "$SKILLS_DATA"

# 获取当前时间
current_date=$(date "+%Y-%m-%d %H:%M:%S")

# 开始生成文档
cat > "$SKILLS_DOC" << 'HEADER_EOF'
# 📦 已安装的 Skills 列表

> 本文档由 `shared/scripts/update-skills-list.sh` 自动生成和维护
> 文件名：`INSTALLED_SKILLS.md` - 避免与各 skill 目录中的 `SKILL.md` 混淆
> 用途/触发关键词：优先由 AI 自动生成中文（可按需手动补充）
HEADER_EOF

echo "> 最后更新：$current_date" >> "$SKILLS_DOC"
echo "" >> "$SKILLS_DOC"
echo "---" >> "$SKILLS_DOC"
echo "" >> "$SKILLS_DOC"

# 生成自己创建的 Skills 部分
if [[ $custom_count -gt 0 ]]; then
    echo "## 🎨 自己创建的 Skills" >> "$SKILLS_DOC"
    echo "" >> "$SKILLS_DOC"

    while IFS=$'\x1f' read -r source name dir_rel source_repo zh_desc keywords; do
        if [[ "$source" != "custom" ]]; then
            continue
        fi

        echo "### $name" >> "$SKILLS_DOC"
        echo "**用途：** $zh_desc" >> "$SKILLS_DOC"
        echo "**触发关键词：** $keywords" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "**位置：** \`$REPO_ROOT/$dir_rel/\`" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "---" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
    done < "$SKILLS_DATA"
fi

# 生成社区安装的 Skills 部分
if [[ $community_count -gt 0 ]]; then
    echo "## 🌐 社区安装的 Skills" >> "$SKILLS_DOC"
    echo "" >> "$SKILLS_DOC"

    while IFS=$'\x1f' read -r source name dir_rel source_repo zh_desc keywords; do
        if [[ "$source" != "community" ]]; then
            continue
        fi

        echo "### $name" >> "$SKILLS_DOC"
        echo "**用途：** $zh_desc" >> "$SKILLS_DOC"
        echo "**触发关键词：** $keywords" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "**来源：** $source_repo" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "**位置：** \`$REPO_ROOT/$dir_rel/\`" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "---" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
    done < "$SKILLS_DATA"
fi

# 生成统计信息
total_count=$((custom_count + community_count))

cat >> "$SKILLS_DOC" << STATS_EOF
## 📊 统计信息

- **总计：** $total_count 个 skills
- **自己创建：** $custom_count 个
- **社区安装：** $community_count 个

---

## 🔄 如何更新此列表

\`\`\`bash
# 手动更新
SKILLS_DIR=$REPO_ROOT bash $REPO_ROOT/shared/scripts/update-skills-list.sh

# 自动更新时机
# 1. 创建新 skill 后
# 2. 安装新 skill 后
# 3. 修改 SKILL.md 中 description/keywords 后
\`\`\`
STATS_EOF

# 清理
rm "$SKILLS_DATA"
rm "$EXISTING_META"

echo "✅ Skills 列表已更新到 INSTALLED_SKILLS.md"
echo ""
echo "📋 当前统计："
echo "   - 总计: $total_count 个 skills"
echo "   - 自己创建的: $custom_count 个"
echo "   - 社区安装的: $community_count 个"
echo ""
echo "📄 文件位置: $SKILLS_DOC"
