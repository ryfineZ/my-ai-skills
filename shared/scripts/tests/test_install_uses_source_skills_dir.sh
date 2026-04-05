#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"

mkdir -p "$TEST_HOME" "$RUNTIME_DIR"
mkdir -p "$SOURCE_DIR/packages/core/create-skill"
mkdir -p "$SOURCE_DIR/packages/community/superpowers/brainstorming"

cat > "$SOURCE_DIR/packages/core/create-skill/SKILL.md" <<'EOF'
---
name: create-skill
description: test
---
EOF

cat > "$SOURCE_DIR/packages/community/superpowers/brainstorming/SKILL.md" <<'EOF'
---
name: brainstorming
description: test
---
EOF

HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/install.sh >/tmp/test-install-source-skills-dir.log 2>&1

if [[ ! -L "$TEST_HOME/.agents/skills/create-skill" ]]; then
    echo "expected runtime link for create-skill"
    cat /tmp/test-install-source-skills-dir.log
    exit 1
fi

if [[ ! -L "$TEST_HOME/.agents/skills/brainstorming" ]]; then
    echo "expected runtime link for brainstorming"
    cat /tmp/test-install-source-skills-dir.log
    exit 1
fi

EXPECTED_CREATE_SKILL_TARGET="$(cd "$SOURCE_DIR/packages/core/create-skill" && pwd -P)"
ACTUAL_CREATE_SKILL_TARGET="$(cd "$TEST_HOME/.agents/skills/create-skill" && pwd -P)"

if [[ "$ACTUAL_CREATE_SKILL_TARGET" != "$EXPECTED_CREATE_SKILL_TARGET" ]]; then
    echo "unexpected create-skill link target"
    cat /tmp/test-install-source-skills-dir.log
    exit 1
fi

if [[ ! -L "$TEST_HOME/.codex/skills/create-skill" ]]; then
    echo "expected codex link for create-skill"
    cat /tmp/test-install-source-skills-dir.log
    exit 1
fi

echo "PASS"
