#!/bin/bash
# install-skill - 安装 skills（支持全局和项目级）

set -e

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
    exit 1
}

# 解析参数
REPO=""
SKILL_NAME=""
GLOBAL_FLAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skill) SKILL_NAME="$2"; shift 2 ;;
        --global|-g) GLOBAL_FLAG="-g"; shift ;;
        --help|-h) usage ;;
        *) REPO="$1"; shift ;;
    esac
done

# 验证参数
if [[ -z "$REPO" ]] || [[ -z "$SKILL_NAME" ]]; then
    echo -e "${RED}❌ 错误: 缺少必需参数${NC}"
    usage
fi

# 确定安装位置和类型
if [[ -n "$GLOBAL_FLAG" ]]; then
    INSTALL_LOCATION="~/.agents/skills"
    INSTALL_TYPE="全局"
else
    INSTALL_LOCATION="./.agents/skills"
    INSTALL_TYPE="项目级"
fi

echo -e "${BLUE}📦 ${INSTALL_TYPE}安装 Skill: ${SKILL_NAME}${NC}"
echo -e "${BLUE}📍 来源: ${REPO}${NC}"
echo -e "${BLUE}📂 位置: ${INSTALL_LOCATION}${NC}"
echo ""

# 使用 npx skills add（非交互式）
echo -e "${YELLOW}⏳ 正在安装...${NC}"
if npx skills add "$REPO" --skill "$SKILL_NAME" -y $GLOBAL_FLAG; then
    echo -e "${GREEN}✅ Skill 安装成功${NC}"
else
    echo -e "${RED}❌ 安装失败${NC}"
    exit 1
fi

# 后处理：仅全局安装需要更新列表
if [[ -n "$GLOBAL_FLAG" ]]; then
    echo ""
    echo -e "${YELLOW}⏳ 正在更新 skills 列表...${NC}"

    UPDATE_SCRIPT=""
    if [[ -f "$HOME/.agents/skills/shared/scripts/update-skills-list.sh" ]]; then
        UPDATE_SCRIPT="$HOME/.agents/skills/shared/scripts/update-skills-list.sh"
    elif [[ -f "$HOME/Workspace/my-ai-skills/shared/scripts/update-skills-list.sh" ]]; then
        UPDATE_SCRIPT="$HOME/Workspace/my-ai-skills/shared/scripts/update-skills-list.sh"
    fi

    if [[ -n "$UPDATE_SCRIPT" ]]; then
        bash "$UPDATE_SCRIPT"
        echo -e "${GREEN}✅ Skills 列表已更新${NC}"
    fi
fi

# 成功提示
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ ${INSTALL_TYPE}安装成功！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ -n "$GLOBAL_FLAG" ]]; then
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
