#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"

mkdir -p "$TEST_HOME" "$RUNTIME_DIR"
mkdir -p "$SOURCE_DIR/packages/core/first-skill"
mkdir -p "$SOURCE_DIR/packages/community/bundle/second-skill"

cat > "$SOURCE_DIR/packages/core/first-skill/SKILL.md" <<'EOF'
---
name: duplicate-skill
description: test
---
EOF

cat > "$SOURCE_DIR/packages/community/bundle/second-skill/SKILL.md" <<'EOF'
---
name: duplicate-skill
description: test
---
EOF

set +e
OUTPUT="$(
    HOME="$TEST_HOME" \
    SKILLS_DIR="$RUNTIME_DIR" \
    SOURCE_SKILLS_DIR="$SOURCE_DIR" \
    bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/install.sh 2>&1
)"
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
    echo "expected install.sh to fail on duplicate skill names"
    echo "$OUTPUT"
    exit 1
fi

if [[ "$OUTPUT" != *"重复 skill 名称"* ]]; then
    echo "expected duplicate skill error message"
    echo "$OUTPUT"
    exit 1
fi

echo "PASS"
