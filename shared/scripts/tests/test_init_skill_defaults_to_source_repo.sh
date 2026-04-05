#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

SOURCE_DIR="$ROOT/source"
mkdir -p "$SOURCE_DIR"

SOURCE_SKILLS_DIR="$SOURCE_DIR" \
python3 /Users/zhangyufan/Workspace/skills-central/packages/core/create-skill/scripts/init_skill.py demo-skill >/tmp/test-init-skill.log 2>&1

TARGET_DIR="$SOURCE_DIR/packages/custom/demo-skill"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "expected demo-skill to be created in source repo packages/custom"
    cat /tmp/test-init-skill.log
    exit 1
fi

if [[ ! -f "$TARGET_DIR/.skill-source.json" ]]; then
    echo "expected metadata file for new custom skill"
    cat /tmp/test-init-skill.log
    exit 1
fi

echo "PASS"
