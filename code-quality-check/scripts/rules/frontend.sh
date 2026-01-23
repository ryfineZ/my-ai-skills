#!/bin/bash
# frontend.sh - 前端代码质量检查规则（React/Vue/前端项目）

# 检查：禁止使用 innerHTML/outerHTML（XSS 风险）
check_innerHTML_usage() {
    local check_name="禁止使用 innerHTML/outerHTML（XSS 风险）"
    echo "🔍 检查: $check_name..."

    local issues=""
    for file in $STAGED_FILES; do
        if [ -f "$PROJECT_PATH/$file" ]; then
            local inner_html=$(grep -n "\.innerHTML\s*=" "$PROJECT_PATH/$file" || true)
            local outer_html=$(grep -n "\.outerHTML\s*=" "$PROJECT_PATH/$file" || true)

            if [ -n "$inner_html" ] || [ -n "$outer_html" ]; then
                issues="$issues\n📍 $file\n"
                [ -n "$inner_html" ] && issues="$issues$inner_html\n"
                [ -n "$outer_html" ] && issues="$issues$outer_html\n"
                REQUIRED_ISSUES=$((REQUIRED_ISSUES + 1))
            fi
        fi
    done

    if [ -n "$issues" ]; then
        echo -e "$issues" >> $REQUIRED_ISSUES_FILE
        echo -e "  ${RED}✗ 发现问题${NC}"
    else
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        echo -e "  ${GREEN}✓ 通过${NC}"
    fi
}

# 检查：dangerouslySetInnerHTML 使用（React）
check_dangerouslySetInnerHTML() {
    local check_name="dangerouslySetInnerHTML 使用（React）"
    echo "🔍 检查: $check_name..."

    local issues=""
    for file in $STAGED_FILES; do
        if [ -f "$PROJECT_PATH/$file" ]; then
            local matches=$(grep -n "dangerouslySetInnerHTML" "$PROJECT_PATH/$file" || true)
            if [ -n "$matches" ]; then
                issues="$issues\n📍 $file\n⚠️  使用了 dangerouslySetInnerHTML:\n$matches\n"
                OPTIONAL_ISSUES=$((OPTIONAL_ISSUES + 1))
            fi
        fi
    done

    if [ -n "$issues" ]; then
        echo -e "$issues" >> $OPTIONAL_ISSUES_FILE
        echo -e "  ${YELLOW}⚠ 需注意${NC}"
    else
        echo -e "  ${GREEN}✓ 通过${NC}"
    fi
}

# 检查：console.log 残留
check_console_log() {
    local check_name="console.log 残留（生产环境）"
    echo "🔍 检查: $check_name..."

    local issues=""
    for file in $STAGED_FILES; do
        if [ -f "$PROJECT_PATH/$file" ]; then
            # 排除注释中的 console.log
            local matches=$(grep -n "^\s*console\\.log\|^\s*console\\.debug\|^\s*console\\.warn" "$PROJECT_PATH/$file" || true)
            if [ -n "$matches" ]; then
                issues="$issues\n📍 $file\n$matches\n"
                OPTIONAL_ISSUES=$((OPTIONAL_ISSUES + 1))
            fi
        fi
    done

    if [ -n "$issues" ]; then
        echo -e "$issues" >> $OPTIONAL_ISSUES_FILE
        echo -e "  ${YELLOW}⚠ 建议清理${NC}"
    else
        echo -e "  ${GREEN}✓ 通过${NC}"
    fi
}
