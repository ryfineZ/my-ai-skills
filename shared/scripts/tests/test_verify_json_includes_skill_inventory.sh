#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"
JSON_OUT="$ROOT/verify.json"

mkdir -p "$TEST_HOME"
mkdir -p "$SOURCE_DIR/packages/custom/demo-skill"

cat > "$SOURCE_DIR/packages/custom/demo-skill/SKILL.md" <<'EOF'
---
name: demo-skill
description: demo verify inventory
---
EOF

cat > "$SOURCE_DIR/packages/custom/demo-skill/.skill-source.json" <<'EOF'
{
  "source": "custom",
  "source_type": "custom"
}
EOF

HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/install.sh >/tmp/test-verify-inventory-install.log 2>&1

HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/verify.sh --json-out "$JSON_OUT" >/tmp/test-verify-inventory.log 2>&1

python3 - "$JSON_OUT" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

assert data['status'] == 'OK', data
assert data['skills_count'] == 1, data
assert len(data['skills']) == 1, data
skill = data['skills'][0]
assert skill['name'] == 'demo-skill', skill
assert skill['meta_exists'] is True, skill
assert skill['meta_valid'] is True, skill
assert skill['source'] == 'custom', skill
assert skill['source_type'] == 'custom', skill
PY

echo "PASS"
