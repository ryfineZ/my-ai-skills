#!/bin/bash
# common.sh - 通用代码质量检查规则（适用于所有项目）

# 检查：正则表达式控制字符
check_regex_control_chars() {
    local check_name="正则表达式控制字符"
    echo "🔍 检查: $check_name..."

    local issues=""
    for file in $STAGED_FILES; do
        if [ -f "$PROJECT_PATH/$file" ]; then
            local matches=$(grep -n '\\x[0-1][0-9a-fA-F]' "$PROJECT_PATH/$file" || true)
            if [ -n "$matches" ]; then
                issues="$issues\n📍 $file\n$matches\n"
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

# 检查：未使用的变量（ESLint）
check_unused_vars() {
    local check_name="未使用的变量（ESLint）"
    echo "🔍 检查: $check_name..."

    if command -v npx &> /dev/null && [ -f "$PROJECT_PATH/package.json" ]; then
        cd "$PROJECT_PATH"
        for file in $STAGED_FILES; do
            if [ -f "$file" ]; then
                local eslint_output=$(npx eslint --no-eslintrc --rule 'no-unused-vars: warn' "$file" 2>/dev/null || true)
                if [ -n "$eslint_output" ]; then
                    echo -e "\n📍 $file\n$eslint_output\n" >> $OPTIONAL_ISSUES_FILE
                    OPTIONAL_ISSUES=$((OPTIONAL_ISSUES + 1))
                fi
            fi
        done
        echo -e "  ${GREEN}✓ 完成${NC}"
    else
        echo -e "  ${YELLOW}⊘ 跳过（未安装 ESLint 或非 JS 项目）${NC}"
    fi
}

# 检查：硬编码的敏感信息
check_hardcoded_secrets() {
    local check_name="硬编码的敏感信息"
    echo "🔍 检查: $check_name..."

    local issues=""
    local patterns=(
        "api[_-]?key.*=.*['\"][a-zA-Z0-9]{20,}['\"]"
        "password.*=.*['\"][^'\"]{6,}['\"]"
        "secret.*=.*['\"][a-zA-Z0-9]{20,}['\"]"
        "token.*=.*['\"][a-zA-Z0-9]{20,}['\"]"
    )

    for file in $STAGED_FILES; do
        if [ -f "$PROJECT_PATH/$file" ]; then
            for pattern in "${patterns[@]}"; do
                local matches=$(grep -inE "$pattern" "$PROJECT_PATH/$file" || true)
                if [ -n "$matches" ]; then
                    issues="$issues\n📍 $file\n⚠️  可能包含硬编码的敏感信息:\n$matches\n"
                    REQUIRED_ISSUES=$((REQUIRED_ISSUES + 1))
                    break
                fi
            done
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
