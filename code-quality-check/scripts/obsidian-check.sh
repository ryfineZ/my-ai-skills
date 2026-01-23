#!/bin/bash
# obsidian-check.sh - Obsidian 插件代码自动检查脚本

set -e

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计变量
REQUIRED_ISSUES=0
OPTIONAL_ISSUES=0
PASSED_CHECKS=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Obsidian 插件代码检查${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 获取项目路径
PROJECT_PATH="${1:-.}"

# 检查是否是 Obsidian 插件项目
if [ ! -f "$PROJECT_PATH/manifest.json" ]; then
    echo -e "${YELLOW}⚠️  不是 Obsidian 插件项目（未找到 manifest.json）${NC}"
    exit 0
fi

echo "📂 项目路径: $PROJECT_PATH"
echo ""

# 获取暂存的文件
STAGED_FILES=$(git diff --staged --name-only --diff-filter=ACM | grep -E '\.(ts|js)$' || true)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}⚠️  没有暂存的 TypeScript/JavaScript 文件${NC}"
    echo ""
    echo "运行以下命令暂存文件："
    echo "  git add ."
    exit 0
fi

echo "📝 检查暂存的文件："
echo "$STAGED_FILES" | sed 's/^/  - /'
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}开始检查...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 临时文件存储问题
REQUIRED_ISSUES_FILE=$(mktemp)
OPTIONAL_ISSUES_FILE=$(mktemp)

# 清理临时文件
trap "rm -f $REQUIRED_ISSUES_FILE $OPTIONAL_ISSUES_FILE" EXIT

# 检查 1: 禁止创建 style 元素
echo "🔍 检查 1/5: 禁止直接创建 style 元素..."
STYLE_ISSUES=""
for file in $STAGED_FILES; do
    if [ -f "$PROJECT_PATH/$file" ]; then
        MATCHES=$(grep -n "createElement.*['\"]style['\"]" "$PROJECT_PATH/$file" || true)
        if [ -n "$MATCHES" ]; then
            STYLE_ISSUES="$STYLE_ISSUES\n📍 $file\n$MATCHES\n"
            REQUIRED_ISSUES=$((REQUIRED_ISSUES + 1))
        fi
    fi
done

if [ -n "$STYLE_ISSUES" ]; then
    echo -e "$STYLE_ISSUES" >> $REQUIRED_ISSUES_FILE
    echo -e "  ${RED}✗ 发现问题${NC}"
else
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo -e "  ${GREEN}✓ 通过${NC}"
fi

# 检查 2: 禁止使用 innerHTML/outerHTML
echo "🔍 检查 2/5: 禁止使用 innerHTML/outerHTML..."
HTML_ISSUES=""
for file in $STAGED_FILES; do
    if [ -f "$PROJECT_PATH/$file" ]; then
        INNER_HTML=$(grep -n "\.innerHTML\s*=" "$PROJECT_PATH/$file" || true)
        OUTER_HTML=$(grep -n "\.outerHTML\s*=" "$PROJECT_PATH/$file" || true)

        if [ -n "$INNER_HTML" ] || [ -n "$OUTER_HTML" ]; then
            HTML_ISSUES="$HTML_ISSUES\n📍 $file\n"
            [ -n "$INNER_HTML" ] && HTML_ISSUES="$HTML_ISSUES$INNER_HTML\n"
            [ -n "$OUTER_HTML" ] && HTML_ISSUES="$HTML_ISSUES$OUTER_HTML\n"
            REQUIRED_ISSUES=$((REQUIRED_ISSUES + 1))
        fi
    fi
done

if [ -n "$HTML_ISSUES" ]; then
    echo -e "$HTML_ISSUES" >> $REQUIRED_ISSUES_FILE
    echo -e "  ${RED}✗ 发现问题${NC}"
else
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo -e "  ${GREEN}✓ 通过${NC}"
fi

# 检查 3: 正则表达式控制字符
echo "🔍 检查 3/5: 正则表达式控制字符..."
REGEX_ISSUES=""
for file in $STAGED_FILES; do
    if [ -f "$PROJECT_PATH/$file" ]; then
        MATCHES=$(grep -n '\\x[0-1][0-9a-fA-F]' "$PROJECT_PATH/$file" || true)
        if [ -n "$MATCHES" ]; then
            REGEX_ISSUES="$REGEX_ISSUES\n📍 $file\n$MATCHES\n"
            REQUIRED_ISSUES=$((REQUIRED_ISSUES + 1))
        fi
    fi
done

if [ -n "$REGEX_ISSUES" ]; then
    echo -e "$REGEX_ISSUES" >> $REQUIRED_ISSUES_FILE
    echo -e "  ${RED}✗ 发现问题${NC}"
else
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo -e "  ${GREEN}✓ 通过${NC}"
fi

# 检查 4: 禁止导入 Node.js 模块
echo "🔍 检查 4/5: 禁止导入 Node.js 模块..."
NODE_ISSUES=""
for file in $STAGED_FILES; do
    if [ -f "$PROJECT_PATH/$file" ]; then
        FS_IMPORT=$(grep -n "import.*['\"]fs['\"]" "$PROJECT_PATH/$file" || true)
        PATH_IMPORT=$(grep -n "import.*['\"]path['\"]" "$PROJECT_PATH/$file" || true)
        FS_REQUIRE=$(grep -n "require.*['\"]fs['\"]" "$PROJECT_PATH/$file" || true)
        PATH_REQUIRE=$(grep -n "require.*['\"]path['\"]" "$PROJECT_PATH/$file" || true)

        if [ -n "$FS_IMPORT" ] || [ -n "$PATH_IMPORT" ] || [ -n "$FS_REQUIRE" ] || [ -n "$PATH_REQUIRE" ]; then
            NODE_ISSUES="$NODE_ISSUES\n📍 $file\n"
            [ -n "$FS_IMPORT" ] && NODE_ISSUES="$NODE_ISSUES$FS_IMPORT\n"
            [ -n "$PATH_IMPORT" ] && NODE_ISSUES="$NODE_ISSUES$PATH_IMPORT\n"
            [ -n "$FS_REQUIRE" ] && NODE_ISSUES="$NODE_ISSUES$FS_REQUIRE\n"
            [ -n "$PATH_REQUIRE" ] && NODE_ISSUES="$NODE_ISSUES$PATH_REQUIRE\n"
            REQUIRED_ISSUES=$((REQUIRED_ISSUES + 1))
        fi
    fi
done

if [ -n "$NODE_ISSUES" ]; then
    echo -e "$NODE_ISSUES" >> $REQUIRED_ISSUES_FILE
    echo -e "  ${RED}✗ 发现问题${NC}"
else
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo -e "  ${GREEN}✓ 通过${NC}"
fi

# 检查 5: 未使用的变量（如果有 ESLint）
echo "🔍 检查 5/5: 未使用的变量（ESLint）..."
if command -v npx &> /dev/null && [ -f "$PROJECT_PATH/package.json" ]; then
    cd "$PROJECT_PATH"
    for file in $STAGED_FILES; do
        if [ -f "$file" ]; then
            ESLINT_OUTPUT=$(npx eslint --no-eslintrc --rule 'no-unused-vars: warn' "$file" 2>/dev/null || true)
            if [ -n "$ESLINT_OUTPUT" ]; then
                echo -e "\n📍 $file\n$ESLINT_OUTPUT\n" >> $OPTIONAL_ISSUES_FILE
                OPTIONAL_ISSUES=$((OPTIONAL_ISSUES + 1))
            fi
        fi
    done
    echo -e "  ${GREEN}✓ 完成${NC}"
else
    echo -e "  ${YELLOW}⊘ 跳过（未安装 ESLint）${NC}"
fi

echo ""

# 显示结果
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 检查结果${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 显示必须修复的问题
if [ $REQUIRED_ISSUES -gt 0 ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}🔴 必须修复的问题（$REQUIRED_ISSUES 个）${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    cat $REQUIRED_ISSUES_FILE
    echo ""
fi

# 显示可选优化
if [ $OPTIONAL_ISSUES -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🟡 建议优化（$OPTIONAL_ISSUES 个）${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    cat $OPTIONAL_ISSUES_FILE
    echo ""
fi

# 显示通过的检查
if [ $PASSED_CHECKS -gt 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ 通过检查（$PASSED_CHECKS 项）${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

# 总结
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 统计${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "🔴 必须修复: ${RED}$REQUIRED_ISSUES${NC} 个"
echo -e "🟡 建议优化: ${YELLOW}$OPTIONAL_ISSUES${NC} 个"
echo -e "✅ 通过检查: ${GREEN}$PASSED_CHECKS${NC} 项"
echo ""

# 决定退出码
if [ $REQUIRED_ISSUES -gt 0 ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ 检查失败！${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "请修复上述必须修复的问题后再提交。"
    echo ""
    echo "修复后运行："
    echo "  git add ."
    echo "  再次检查"
    echo ""
    exit 1
else
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ 检查通过！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [ $OPTIONAL_ISSUES -gt 0 ]; then
        echo "建议："
        echo "  - 考虑修复可选优化问题"
        echo "  - 或者直接提交代码"
        echo ""
    else
        echo "所有检查都已通过，可以安全提交！"
        echo ""
    fi

    exit 0
fi
