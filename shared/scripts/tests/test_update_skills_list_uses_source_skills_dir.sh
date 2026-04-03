#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

DOC_ROOT="$ROOT/doc-root"
SOURCE_DIR="$ROOT/source"

mkdir -p "$DOC_ROOT"
mkdir -p "$SOURCE_DIR/packages/core/create-skill"
mkdir -p "$SOURCE_DIR/packages/community/superpowers/brainstorming"

cat > "$SOURCE_DIR/packages/core/create-skill/SKILL.md" <<'EOF'
---
name: create-skill
description: Use when creating a new skill.
---
EOF

cat > "$SOURCE_DIR/packages/community/superpowers/brainstorming/SKILL.md" <<'EOF'
---
name: brainstorming
description: Use before implementation.
---
EOF

HOME="$ROOT/home" \
SKILLS_DIR="$DOC_ROOT" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/update-skills-list.sh >/tmp/test-update-skills-list.log 2>&1

if [[ ! -f "$SOURCE_DIR/INSTALLED_SKILLS.md" ]]; then
    echo "expected INSTALLED_SKILLS.md to be generated"
    cat /tmp/test-update-skills-list.log
    exit 1
fi

if ! grep -q '^### create-skill$' "$SOURCE_DIR/INSTALLED_SKILLS.md"; then
    echo "expected create-skill in INSTALLED_SKILLS.md"
    cat "$SOURCE_DIR/INSTALLED_SKILLS.md"
    exit 1
fi

if ! grep -q '^### brainstorming$' "$SOURCE_DIR/INSTALLED_SKILLS.md"; then
    echo "expected brainstorming in INSTALLED_SKILLS.md"
    cat "$SOURCE_DIR/INSTALLED_SKILLS.md"
    exit 1
fi

echo "PASS"
