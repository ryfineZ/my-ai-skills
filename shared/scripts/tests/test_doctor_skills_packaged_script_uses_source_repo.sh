#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"

mkdir -p "$TEST_HOME"
mkdir -p "$SOURCE_DIR/shared/scripts" "$SOURCE_DIR/packages/core/doctor-skills" "$SOURCE_DIR/packages/custom/demo-skill"

cp /Users/zhangyufan/Workspace/skills-central/packages/core/doctor-skills/doctor-skills.sh "$SOURCE_DIR/packages/core/doctor-skills/doctor-skills.sh"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/install.sh "$SOURCE_DIR/shared/scripts/install.sh"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/update-skills-list.sh "$SOURCE_DIR/shared/scripts/update-skills-list.sh"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/verify.sh "$SOURCE_DIR/shared/scripts/verify.sh"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/verify_skills.py "$SOURCE_DIR/shared/scripts/verify_skills.py"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/generate-claude-plugin-recommendations.sh "$SOURCE_DIR/shared/scripts/generate-claude-plugin-recommendations.sh"
chmod +x "$SOURCE_DIR/packages/core/doctor-skills/doctor-skills.sh" "$SOURCE_DIR/shared/scripts/install.sh" "$SOURCE_DIR/shared/scripts/update-skills-list.sh" "$SOURCE_DIR/shared/scripts/verify.sh" "$SOURCE_DIR/shared/scripts/verify_skills.py" "$SOURCE_DIR/shared/scripts/generate-claude-plugin-recommendations.sh"

cat > "$SOURCE_DIR/packages/custom/demo-skill/SKILL.md" <<'EOF'
---
name: demo-skill
description: demo
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
bash "$SOURCE_DIR/shared/scripts/install.sh" >/tmp/test-doctor-packaged-install.log 2>&1

JSON_OUT="$ROOT/doctor.json"
HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
bash "$SOURCE_DIR/packages/core/doctor-skills/doctor-skills.sh" --json >"$JSON_OUT"

SOURCE_DIR_REAL="$(cd "$SOURCE_DIR" && pwd -P)"

if ! grep -q "\"status\": \"OK\"" "$JSON_OUT"; then
    echo "expected doctor-skills packaged script to report OK"
    cat "$JSON_OUT"
    exit 1
fi

if ! grep -q "\"source_skills_dir\": \"$SOURCE_DIR_REAL\"" "$JSON_OUT"; then
    echo "expected doctor-skills to infer source repo from packaged path"
    cat "$JSON_OUT"
    exit 1
fi

echo "PASS"
