#!/bin/bash

set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

SOURCE_DIR="$ROOT/source"
DOC_PATH="$ROOT/claude-plugin-recommendations.md"

mkdir -p "$SOURCE_DIR/packages/community/example-bundle/example-skill"

cat > "$SOURCE_DIR/packages/community/example-bundle/example-skill/SKILL.md" <<'EOF'
---
name: example-skill
description: example
---
EOF

cat > "$SOURCE_DIR/packages/community/example-bundle/example-skill/.skill-source.json" <<'EOF'
{
  "package_name": "example-bundle",
  "source_repo": "https://github.com/example/example-bundle",
  "platform_policies": {
    "claude_code": {
      "publish": false,
      "install": "plugin",
      "plugin_name": "example-plugin",
      "plugin_marketplace": "example-marketplace",
      "plugin_marketplace_source": "example/example-bundle",
      "install_hint": "/plugin install example-plugin@example-marketplace"
    }
  }
}
EOF

SKILLS_DIR="$SOURCE_DIR" \
DOC_PATH="$DOC_PATH" \
bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/generate-claude-plugin-recommendations.sh >/tmp/test-generate-claude-plugin-doc.log 2>&1

if [[ ! -f "$DOC_PATH" ]]; then
    echo "expected claude plugin recommendations doc to be generated"
    cat /tmp/test-generate-claude-plugin-doc.log
    exit 1
fi

if ! grep -q '## example-bundle' "$DOC_PATH"; then
    echo "expected bundle heading in generated doc"
    cat "$DOC_PATH"
    exit 1
fi

if ! grep -q '/plugin install example-plugin@example-marketplace' "$DOC_PATH"; then
    echo "expected install hint in generated doc"
    cat "$DOC_PATH"
    exit 1
fi

echo "PASS"
