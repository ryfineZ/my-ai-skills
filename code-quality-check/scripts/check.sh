#!/bin/bash
# check.sh - 通用代码质量检查主脚本

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

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 获取项目路径
PROJECT_PATH="${1:-.}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 代码质量检查${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检测项目类型
detect_project_type() {
    # Obsidian 插件（检测是否有 id, name, version 字段，且没有 manifest_version）
    if [ -f "$PROJECT_PATH/manifest.json" ]; then
        if grep -q "\"id\"" "$PROJECT_PATH/manifest.json" 2>/dev/null && \
           grep -q "\"name\"" "$PROJECT_PATH/manifest.json" 2>/dev/null && \
           grep -q "\"version\"" "$PROJECT_PATH/manifest.json" 2>/dev/null && \
           ! grep -q "manifest_version" "$PROJECT_PATH/manifest.json" 2>/dev/null; then
            echo "obsidian"
            return
        fi
    fi

    # 浏览器扩展
    if [ -f "$PROJECT_PATH/manifest.json" ]; then
        if grep -q "manifest_version" "$PROJECT_PATH/manifest.json" 2>/dev/null; then
            echo "browser-extension"
            return
        fi
    fi

    # 前端项目（React/Vue/Angular）
    if [ -f "$PROJECT_PATH/package.json" ]; then
        if grep -qE "\"react\"|\"vue\"|\"@angular\"" "$PROJECT_PATH/package.json" 2>/dev/null; then
            echo "frontend"
            return
        fi
    fi

    # Electron 应用
    if [ -f "$PROJECT_PATH/package.json" ]; then
        if grep -q "\"electron\"" "$PROJECT_PATH/package.json" 2>/dev/null; then
            echo "electron"
            return
        fi
    fi

    # 通用项目
    echo "generic"
}

PROJECT_TYPE=$(detect_project_type)

echo "📂 项目路径: $PROJECT_PATH"
echo "🏷️  项目类型: $PROJECT_TYPE"
echo ""

# 获取暂存的文件
STAGED_FILES=$(git diff --staged --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.(ts|js|tsx|jsx)$' || true)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}⚠️  没有暂存的代码文件${NC}"
    echo ""
    echo "运行以下命令暂存文件："
    echo "  git add ."
    exit 0
fi

echo "📝 检查暂存的文件："
echo "$STAGED_FILES" | sed 's/^/  - /'
echo ""

# 临时文件存储问题
REQUIRED_ISSUES_FILE=$(mktemp)
OPTIONAL_ISSUES_FILE=$(mktemp)

# 清理临时文件
trap "rm -f $REQUIRED_ISSUES_FILE $OPTIONAL_ISSUES_FILE" EXIT

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}开始检查...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 加载并执行规则
source "$SCRIPT_DIR/rules/common.sh"

# 执行通用规则
check_regex_control_chars
check_hardcoded_secrets
check_unused_vars

# 根据项目类型加载对应规则
case $PROJECT_TYPE in
    obsidian)
        echo ""
        echo -e "${BLUE}🔌 Obsidian 插件特定检查${NC}"
        source "$SCRIPT_DIR/rules/frontend.sh"
        source "$SCRIPT_DIR/rules/obsidian.sh"

        check_innerHTML_usage
        check_console_log
        check_style_element_creation
        check_nodejs_imports
        ;;

    browser-extension)
        echo ""
        echo -e "${BLUE}🌐 浏览器扩展特定检查${NC}"
        source "$SCRIPT_DIR/rules/frontend.sh"

        check_innerHTML_usage
        check_dangerouslySetInnerHTML
        check_console_log
        ;;

    electron)
        echo ""
        echo -e "${BLUE}⚡ Electron 应用特定检查${NC}"
        source "$SCRIPT_DIR/rules/frontend.sh"

        check_innerHTML_usage
        check_dangerouslySetInnerHTML
        check_console_log
        ;;

    frontend)
        echo ""
        echo -e "${BLUE}🎨 前端项目特定检查${NC}"
        source "$SCRIPT_DIR/rules/frontend.sh"

        check_innerHTML_usage
        check_dangerouslySetInnerHTML
        check_console_log
        ;;

    *)
        echo ""
        echo -e "${BLUE}📦 通用项目检查（已完成基础检查）${NC}"
        ;;
esac

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
    echo "  再次触发提交"
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
