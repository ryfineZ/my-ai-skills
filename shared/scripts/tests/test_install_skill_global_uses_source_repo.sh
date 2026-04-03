#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
RUNTIME_DIR="$ROOT/runtime"
SOURCE_DIR="$ROOT/source"
REPO_DIR="$ROOT/repo"
GUARD_SCRIPT="$ROOT/fake_guard.py"

mkdir -p "$TEST_HOME" "$RUNTIME_DIR" "$SOURCE_DIR" "$REPO_DIR/my-test-skill"

cat > "$REPO_DIR/my-test-skill/SKILL.md" <<'EOF'
---
name: my-test-skill
description: test skill
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
bash /Users/zhangyufan/Workspace/skills-central/packages/core/install-skill/install-skill.sh "$REPO_DIR" --skill my-test-skill --global >/tmp/test-install-skill-global.log 2>&1

TARGET_DIR="$SOURCE_DIR/packages/community/repo/my-test-skill"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "expected skill to be installed into source repo"
    cat /tmp/test-install-skill-global.log
    exit 1
fi

if [[ ! -L "$TEST_HOME/.agents/skills/my-test-skill" ]]; then
    echo "expected runtime link to be created"
    cat /tmp/test-install-skill-global.log
    exit 1
fi

if [[ ! -f "$TARGET_DIR/.skill-source.json" ]]; then
    echo "expected metadata file in source repo"
    cat /tmp/test-install-skill-global.log
    exit 1
fi

echo "PASS"
