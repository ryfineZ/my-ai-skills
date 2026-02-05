#!/bin/bash

# 自动更新 INSTALLED_SKILLS.md 中的 Skills 列表
# 从每个 skill 的 SKILL.md frontmatter 中提取名字

REPO_ROOT="$HOME/Workspace/my-ai-skills"
SKILLS_DOC="$REPO_ROOT/INSTALLED_SKILLS.md"

# 临时文件
SKILLS_DATA=$(mktemp)
EXISTING_META=$(mktemp)

echo "🔍 正在扫描已安装的 skills..."

# 读取现有列表中的中文描述与触发关键词（用于保留）

if [[ -f "$SKILLS_DOC" ]]; then
    SKILLS_DOC="$SKILLS_DOC" python3 - <<'PY' > "$EXISTING_META"
import os
import re

path = os.environ.get("SKILLS_DOC")
if not path or not os.path.exists(path):
    raise SystemExit(0)

text = open(path, "r", encoding="utf-8").read()
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

# 计数器
custom_count=0
community_count=0

# 扫描所有 skill 目录（排除特殊目录）
for skill_dir in "$REPO_ROOT"/*/; do
    # 跳过特殊目录
    dir_name=$(basename "$skill_dir")
    if [[ "$dir_name" == "shared" || "$dir_name" == ".git" || "$dir_name" == ".system" ]]; then
        continue
    fi

    # 检查是否有 SKILL.md
    skill_file="$skill_dir/SKILL.md"
    if [[ ! -f "$skill_file" ]]; then
        continue
    fi

    # 提取 frontmatter 中的 name
    # 使用 Python 来处理 YAML frontmatter（更可靠）
    frontmatter=$(python3 -c "
import sys
import re

try:
    content = open('$skill_file', 'r', encoding='utf-8').read()
    # 提取 frontmatter
    match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not match:
        sys.exit(1)

    fm = match.group(1)
    name = ''

    for line in fm.split('\n'):
        if line.startswith('name:'):
            name = line.split(':', 1)[1].strip().strip('\"')

    print(f'{name}')
except Exception as e:
    sys.exit(1)
" 2>/dev/null)

    if [[ -z "$frontmatter" ]]; then
        # Python 失败，回退到 awk
        name=$(awk '/^name:/ {$1=""; gsub(/^[ \t]+|[ \t]+$/, ""); gsub(/^"|"$/, ""); print; exit}' "$skill_file")
    else
        name="$frontmatter"
    fi

    # 如果没有提取到 name，使用目录名
    if [[ -z "$name" ]]; then
        name="$dir_name"
    fi

    # 判断来源：只有 skill-creator 创建的才算自建，其它一律视为社区
    source="community"
    source_repo=""
    source_meta="$skill_dir/.skill-source.json"
    if [[ -f "$source_meta" ]]; then
        source=$(python3 - "$source_meta" <<'PY'
import json, sys
path = sys.argv[1]
try:
    data = json.load(open(path, "r", encoding="utf-8"))
except Exception:
    data = {}
print((data.get("source") or "").strip())
PY
)
        source_repo=$(python3 - "$source_meta" <<'PY'
import json, sys
path = sys.argv[1]
try:
    data = json.load(open(path, "r", encoding="utf-8"))
except Exception:
    data = {}
print((data.get("source_repo") or "").strip())
PY
)
    fi

    if [[ "$source" == "custom" ]]; then
        ((custom_count++))
    else
        source="community"
        ((community_count++))
    fi

    # 存储数据：source|name|dir_name|source_repo
    echo "$source|$name|$dir_name|$source_repo" >> "$SKILLS_DATA"
done

# 按类型和名称排序
sort "$SKILLS_DATA" -o "$SKILLS_DATA"

# 获取当前时间
current_date=$(date "+%Y-%m-%d %H:%M:%S")

# 开始生成文档
cat > "$SKILLS_DOC" << 'HEADER_EOF'
# 📦 已安装的 Skills 列表

> 本文档由 `shared/scripts/update-skills-list.sh` 自动生成和维护
> 文件名：`INSTALLED_SKILLS.md` - 避免与各 skill 目录中的 `SKILL.md` 混淆
HEADER_EOF

echo "> 最后更新：$current_date" >> "$SKILLS_DOC"
echo "" >> "$SKILLS_DOC"
echo "---" >> "$SKILLS_DOC"
echo "" >> "$SKILLS_DOC"

# 生成自己创建的 Skills 部分
if [[ $custom_count -gt 0 ]]; then
    echo "## 🎨 自己创建的 Skills" >> "$SKILLS_DOC"
    echo "" >> "$SKILLS_DOC"

    while IFS='|' read -r source name dir_name source_repo; do
        if [[ "$source" != "custom" ]]; then
            continue
        fi
        skill_file="$REPO_ROOT/$dir_name/SKILL.md"

        zh_desc="$(get_zh_desc "$name")"
        keywords="$(get_keywords "$name")"
        if [[ -z "$zh_desc" ]]; then
            zh_desc="（待补充）"
        fi
        if [[ -z "$keywords" ]]; then
            keywords="（待补充）"
        fi

        echo "### $name" >> "$SKILLS_DOC"
        echo "**用途：** $zh_desc" >> "$SKILLS_DOC"
        echo "**触发关键词：** $keywords" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "**位置：** \`~/Workspace/my-ai-skills/$dir_name/\`" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "---" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
    done < "$SKILLS_DATA"
fi

# 生成社区安装的 Skills 部分
if [[ $community_count -gt 0 ]]; then
    echo "## 🌐 社区安装的 Skills" >> "$SKILLS_DOC"
    echo "" >> "$SKILLS_DOC"

    while IFS='|' read -r source name dir_name source_repo; do
        if [[ "$source" != "community" ]]; then
            continue
        fi
        skill_file="$REPO_ROOT/$dir_name/SKILL.md"

        zh_desc="$(get_zh_desc "$name")"
        keywords="$(get_keywords "$name")"
        if [[ -z "$zh_desc" ]]; then
            zh_desc="（待补充）"
        fi
        if [[ -z "$keywords" ]]; then
            keywords="（待补充）"
        fi

        echo "### $name" >> "$SKILLS_DOC"
        echo "**用途：** $zh_desc" >> "$SKILLS_DOC"
        echo "**触发关键词：** $keywords" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "**来源：** $source_repo" >> "$SKILLS_DOC"
        echo "" >> "$SKILLS_DOC"
        echo "**位置：** \`~/Workspace/my-ai-skills/$dir_name/\`" >> "$SKILLS_DOC"
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
bash ~/Workspace/my-ai-skills/shared/scripts/update-skills-list.sh

# 自动更新时机
# 1. 创建新 skill 后
# 2. 安装新 skill 后
# 3. 修改技能列表中文描述后
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
