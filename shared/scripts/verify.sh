#!/bin/bash
# verify.sh - 验证 Skills 配置（按每个 skill 软链接）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PYTHON_VERIFY_SCRIPT="$SCRIPT_DIR/verify_skills.py"

usage() {
    cat <<'USAGE'
用法:
  shared/scripts/verify.sh [--json] [--json-out <path>]

参数:
  --json              输出 JSON 到 stdout（不输出人类可读日志）
  --json-out <path>   将 JSON 结果写入文件
  -h, --help          显示帮助
USAGE
}

if [[ ! -f "$PYTHON_VERIFY_SCRIPT" ]]; then
    echo "❌ 找不到验证脚本: $PYTHON_VERIFY_SCRIPT" >&2
    exit 1
fi

if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
    esac
fi

exec python3 "$PYTHON_VERIFY_SCRIPT" "$@"
