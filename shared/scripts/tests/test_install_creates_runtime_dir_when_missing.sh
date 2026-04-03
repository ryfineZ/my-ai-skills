#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"

mkdir -p "$TEST_HOME"
mkdir -p "$SOURCE_DIR/packages/core/create-skill"

cat > "$SOURCE_DIR/packages/core/create-skill/SKILL.md" <<'EOF'
---
name: create-skill
description: test
---
EOF

HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/install.sh >/tmp/test-install-create-runtime.log 2>&1

if [[ ! -d "$RUNTIME_DIR" ]]; then
    echo "expected runtime dir to be created automatically"
    cat /tmp/test-install-create-runtime.log
    exit 1
fi

if [[ ! -L "$TEST_HOME/.agents/skills/create-skill" ]]; then
    echo "expected create-skill runtime link"
    cat /tmp/test-install-create-runtime.log
    exit 1
fi

echo "PASS"
