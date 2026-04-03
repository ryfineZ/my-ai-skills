#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
SOURCE_DIR="$ROOT/source"
RUNTIME_DIR="$ROOT/runtime"
REPO_DIR="$ROOT/repo"
GUARD_SCRIPT="$ROOT/fake_guard.py"

mkdir -p "$TEST_HOME" "$SOURCE_DIR" "$RUNTIME_DIR" "$REPO_DIR/my-test-skill"

cat > "$REPO_DIR/my-test-skill/SKILL.md" <<'EOF'
---
name: my-test-skill
description: version one
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
bash /Users/zhangyufan/Workspace/skills-central/packages/core/install-skill/install-skill.sh "$REPO_DIR" --skill my-test-skill --global >/dev/null 2>&1

cat > "$REPO_DIR/my-test-skill/SKILL.md" <<'EOF'
---
name: my-test-skill
description: version two
---
EOF
git -C "$REPO_DIR" add . >/dev/null
git -C "$REPO_DIR" commit -m update >/dev/null 2>&1

HOME="$TEST_HOME" \
SKILLS_DIR="$RUNTIME_DIR" \
SOURCE_SKILLS_DIR="$SOURCE_DIR" \
SECURITY_GUARD_SCRIPT="$GUARD_SCRIPT" \
bash /Users/zhangyufan/Workspace/skills-central/packages/core/update-skill/update-skill.sh --skill my-test-skill >/tmp/test-update-skill.log 2>&1

TARGET_DIR="$SOURCE_DIR/packages/community/repo/my-test-skill"

if ! grep -q 'version two' "$TARGET_DIR/SKILL.md"; then
    echo "expected updated skill content in source repo"
    cat /tmp/test-update-skill.log
    cat "$TARGET_DIR/SKILL.md"
    exit 1
fi

echo "PASS"
