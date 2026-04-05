#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

TEST_HOME="$ROOT/home"
mkdir -p "$TEST_HOME/.agents/skills"

set +e
OUTPUT="$(
    HOME="$TEST_HOME" \
    SKILLS_DIR="$TEST_HOME/.agents/skills" \
    SOURCE_SKILLS_DIR="$ROOT/missing-source" \
    bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/verify.sh --json 2>&1
)"
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
    echo "expected verify.sh to fail when SOURCE_SKILLS_DIR is missing"
    echo "$OUTPUT"
    exit 1
fi

if [[ "$OUTPUT" != *"missing_source_skills_dir"* ]]; then
    echo "expected missing_source_skills_dir issue in json output"
    echo "$OUTPUT"
    exit 1
fi

echo "PASS"
