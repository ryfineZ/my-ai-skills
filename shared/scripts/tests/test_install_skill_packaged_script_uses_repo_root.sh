#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"
REPO_DIR="$ROOT/repo"
GUARD_SCRIPT="$ROOT/fake_guard.py"

mkdir -p "$TEST_HOME" "$SOURCE_DIR/shared/scripts" "$SOURCE_DIR/packages/core/install-skill" "$SOURCE_DIR/packages/core/skill-security-guard/scripts" "$REPO_DIR/my-test-skill"

cp /Users/zhangyufan/Workspace/skills-central/packages/core/install-skill/install-skill.sh "$SOURCE_DIR/packages/core/install-skill/install-skill.sh"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/install.sh "$SOURCE_DIR/shared/scripts/install.sh"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/update-skills-list.sh "$SOURCE_DIR/shared/scripts/update-skills-list.sh"
cp /Users/zhangyufan/Workspace/skills-central/shared/scripts/generate-claude-plugin-recommendations.sh "$SOURCE_DIR/shared/scripts/generate-claude-plugin-recommendations.sh"
chmod +x "$SOURCE_DIR/packages/core/install-skill/install-skill.sh" "$SOURCE_DIR/shared/scripts/install.sh" "$SOURCE_DIR/shared/scripts/update-skills-list.sh" "$SOURCE_DIR/shared/scripts/generate-claude-plugin-recommendations.sh"

cat > "$REPO_DIR/my-test-skill/SKILL.md" <<'EOF'
---
name: my-test-skill
description: packaged install test
---
EOF

cat > "$GUARD_SCRIPT" <<'EOF'
#!/usr/bin/env python3
import json
import sys

print(json.dumps({
    "summary": {
        "verdict": "SAFE",
        "severity_counts": {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}
    },
    "findings": []
}))
sys.exit(0)
EOF
chmod +x "$GUARD_SCRIPT"

git -C "$REPO_DIR" init >/dev/null 2>&1
git -C "$REPO_DIR" config user.name test >/dev/null
git -C "$REPO_DIR" config user.email test@example.com >/dev/null
git -C "$REPO_DIR" add . >/dev/null
git -C "$REPO_DIR" commit -m init >/dev/null 2>&1

HOME="$TEST_HOME" \
RUNTIME_SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
SECURITY_GUARD_SCRIPT="$GUARD_SCRIPT" \
bash "$SOURCE_DIR/packages/core/install-skill/install-skill.sh" "$REPO_DIR" --skill my-test-skill --global >/tmp/test-packaged-install-skill.log 2>&1

TARGET_DIR="$SOURCE_DIR/packages/community/repo/my-test-skill"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "expected packaged install-skill to write into source repo"
    cat /tmp/test-packaged-install-skill.log
    exit 1
fi

if [[ ! -L "$TEST_HOME/.agents/skills/my-test-skill" ]]; then
    echo "expected packaged install-skill to refresh runtime links"
    cat /tmp/test-packaged-install-skill.log
    exit 1
fi

echo "PASS"
