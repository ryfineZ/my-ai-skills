#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

SOURCE_DIR="$ROOT/source"
mkdir -p "$SOURCE_DIR/packages/community/existing"

cat > "$SOURCE_DIR/packages/community/existing/SKILL.md" <<'EOF'
---
name: demo-skill
description: existing
---
EOF

set +e
OUTPUT="$(
    SOURCE_SKILLS_DIR="$SOURCE_DIR" \
    python3 /Users/zhangyufan/Workspace/skills-central/packages/core/create-skill/scripts/init_skill.py demo-skill 2>&1
)"
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
    echo "expected init_skill.py to fail on duplicate export name"
    echo "$OUTPUT"
    exit 1
fi

if [[ "$OUTPUT" != *"already exists"* && "$OUTPUT" != *"冲突"* ]]; then
    echo "expected duplicate-name error message"
    echo "$OUTPUT"
    exit 1
fi

echo "PASS"
