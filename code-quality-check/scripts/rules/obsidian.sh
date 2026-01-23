#!/bin/bash
# obsidian.sh - Obsidian 插件特定检查规则

# 检查：禁止直接创建 style 元素（Obsidian 特定）
check_style_element_creation() {
    local check_name="禁止直接创建 style 元素（Obsidian 规范）"
    echo "🔍 检查: $check_name..."

    local issues=""
    for file in $STAGED_FILES; do
        if [ -f "$PROJECT_PATH/$file" ]; then
            local matches=$(grep -n "createElement.*['\"]style['\"]" "$PROJECT_PATH/$file" || true)
            if [ -n "$matches" ]; then
                issues="$issues\n📍 $file\n$matches\n"
                issues="$issues💡 修复建议：将 CSS 移到 styles.css 文件\n"
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

# 检查：禁止导入 Node.js 模块（Obsidian 特定）
check_nodejs_imports() {
    local check_name="禁止导入 Node.js 模块（Obsidian 规范）"
    echo "🔍 检查: $check_name..."

    local issues=""
    for file in $STAGED_FILES; do
        if [ -f "$PROJECT_PATH/$file" ]; then
            local fs_import=$(grep -n "import.*['\"]fs['\"]" "$PROJECT_PATH/$file" || true)
            local path_import=$(grep -n "import.*['\"]path['\"]" "$PROJECT_PATH/$file" || true)
            local fs_require=$(grep -n "require.*['\"]fs['\"]" "$PROJECT_PATH/$file" || true)
            local path_require=$(grep -n "require.*['\"]path['\"]" "$PROJECT_PATH/$file" || true)

            if [ -n "$fs_import" ] || [ -n "$path_import" ] || [ -n "$fs_require" ] || [ -n "$path_require" ]; then
                issues="$issues\n📍 $file\n"
                [ -n "$fs_import" ] && issues="$issues$fs_import\n"
                [ -n "$path_import" ] && issues="$issues$path_import\n"
                [ -n "$fs_require" ] && issues="$issues$fs_require\n"
                [ -n "$path_require" ] && issues="$issues$path_require\n"
                issues="$issues💡 修复建议：使用 Obsidian Vault API (this.app.vault)\n"
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
