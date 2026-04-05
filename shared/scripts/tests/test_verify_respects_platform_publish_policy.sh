#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"

mkdir -p "$TEST_HOME"
mkdir -p "$SOURCE_DIR/packages/community/bundle/codex-only-skill"

cat > "$SOURCE_DIR/packages/community/bundle/codex-only-skill/SKILL.md" <<'EOF'
---
name: codex-only-skill
description: codex only
---
EOF

cat > "$SOURCE_DIR/packages/community/bundle/codex-only-skill/.skill-source.json" <<'EOF'
{
  "platform_policies": {
    "claude_code": { "publish": false },
    "codex": { "publish": true },
    "cursor": { "publish": false },
    "gemini": { "publish": false },
    "antigravity": { "publish": false },
    "windsurf": { "publish": false },
    "cline": { "publish": false },
    "goose": { "publish": false }
  }
}
EOF

HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/install.sh >/tmp/test-verify-platform-install.log 2>&1

JSON_OUT="$ROOT/verify.json"
HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/verify.sh --json-out "$JSON_OUT" >/tmp/test-verify-platform.log 2>&1

if grep -q 'missing_tool_link' "$JSON_OUT"; then
    echo "did not expect missing_tool_link for disabled platforms"
    cat "$JSON_OUT"
    exit 1
fi

if [[ ! -L "$TEST_HOME/.codex/skills/codex-only-skill" ]]; then
    echo "expected codex link to exist"
    cat /tmp/test-verify-platform-install.log
    cat /tmp/test-verify-platform.log
    exit 1
fi

if [[ -e "$TEST_HOME/.cursor/skills/codex-only-skill" || -L "$TEST_HOME/.cursor/skills/codex-only-skill" ]]; then
    echo "did not expect cursor link for disabled platform"
    cat /tmp/test-verify-platform-install.log
    exit 1
fi

echo "PASS"
