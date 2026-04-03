#!/bin/bash
# verify.sh - 验证多平台规则同步状态（只读）

set -e

RULES_DIR="$HOME/Workspace/agent-rules"
COMMON="$RULES_DIR/AGENTS.md"
AGENTS_DIR="$RULES_DIR/agents"
OUT_DIR="$RULES_DIR/generated"

ok=0
fail=0

say_ok() { echo "✅ $1"; ok=$((ok+1)); }
say_fail() { echo "❌ $1"; fail=$((fail+1)); }

check_file() {
  local path="$1"
  if [ -f "$path" ]; then
    say_ok "存在: $path"
  else
    say_fail "缺失: $path"
  fi
}

check_link() {
  local dest="$1"
  local expected="$2"
  if [ -L "$dest" ]; then
    local target
    target="$(readlink "$dest")"
    if [ "$target" = "$expected" ]; then
      say_ok "链接正确: $dest -> $expected"
    else
      say_fail "链接错误: $dest -> $target (期望 $expected)"
    fi
  else
    if [ -e "$dest" ]; then
      say_fail "不是软链接: $dest"
    else
      say_fail "缺失: $dest"
    fi
  fi
}

echo "🔍 验证 agent-rules 配置"

check_file "$COMMON"
check_file "$AGENTS_DIR/claude.md"
check_file "$AGENTS_DIR/codex.md"
check_file "$AGENTS_DIR/gemini.md"
check_file "$AGENTS_DIR/antigravity.md"

check_file "$OUT_DIR/CLAUDE.md"
check_file "$OUT_DIR/AGENTS.md"
check_file "$OUT_DIR/GEMINI.md"

check_link "$HOME/.claude/CLAUDE.md" "$OUT_DIR/CLAUDE.md"
check_link "$HOME/.codex/AGENTS.md" "$OUT_DIR/AGENTS.md"
check_link "$HOME/.gemini/GEMINI.md" "$OUT_DIR/GEMINI.md"

echo ""
echo "完成：通过 $ok 项，失败 $fail 项"

if [ "$fail" -ne 0 ]; then
  exit 1
fi
