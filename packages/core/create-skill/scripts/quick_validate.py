#!/usr/bin/env python3
"""Quick validation script for skills.

优先使用 PyYAML 做完整 frontmatter 校验；若本机未安装 PyYAML，则回退到
轻量级解析器，只校验顶层字段以及 `name` / `description` 的基础格式。
"""

import sys
import re
from pathlib import Path

try:
    import yaml  # type: ignore
except ModuleNotFoundError:  # pragma: no cover - environment-dependent
    yaml = None


ALLOWED_PROPERTIES = {
    'name',
    'description',
    'license',
    'allowed-tools',
    'metadata',
    'disable-model-invocation',
    'argument-hint',
    'compatibility',
    'model',
    'hooks',
    'context',
    'agent',
    'user-invocable',
    'version',
    'author',
}

def parse_frontmatter_fallback(frontmatter_text):
    """Parse top-level YAML keys without PyYAML.

    这个回退解析器只覆盖当前 validator 真正需要的能力：
    - 顶层 key 集合
    - `name`
    - `description`

    对嵌套 `metadata:`、列表等结构不做深度解析，只保留顶层 key。
    """
    frontmatter = {}
    top_level_key_re = re.compile(r"^([A-Za-z0-9_-]+):\s*(.*)$")

    for raw_line in frontmatter_text.splitlines():
        if not raw_line.strip():
            continue
        if raw_line.startswith((" ", "\t", "-")):
            continue

        match = top_level_key_re.match(raw_line)
        if not match:
            continue

        key = match.group(1).strip()
        value = match.group(2).strip()
        if value.startswith(("'", '"')) and value.endswith(("'", '"')) and len(value) >= 2:
            value = value[1:-1]
        frontmatter[key] = value

    return frontmatter


def parse_frontmatter(frontmatter_text):
    if yaml is not None:
        try:
            parsed = yaml.safe_load(frontmatter_text)
            if not isinstance(parsed, dict):
                return None, "Frontmatter must be a YAML dictionary"
            return parsed, None
        except yaml.YAMLError as exc:
            return None, f"Invalid YAML in frontmatter: {exc}"

    parsed = parse_frontmatter_fallback(frontmatter_text)
    if not isinstance(parsed, dict) or not parsed:
        return None, "Invalid frontmatter format (fallback parser)"
    return parsed, None


def validate_skill(skill_path):
    """Basic validation of a skill."""
    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # Read and validate frontmatter
    content = skill_md.read_text()
    if not content.startswith('---'):
        return False, "No YAML frontmatter found"

    # Extract frontmatter
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    frontmatter_text = match.group(1)

    frontmatter, parse_error = parse_frontmatter(frontmatter_text)
    if parse_error:
        return False, parse_error

    # Check for unexpected properties (excluding nested keys under metadata)
    unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected_keys:
        return False, (
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Check required fields
    if 'name' not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if 'description' not in frontmatter:
        return False, "Missing 'description' in frontmatter"

    # Extract name for validation
    name = frontmatter.get('name', '')
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        # Check naming convention (hyphen-case: lowercase with hyphens)
        if not re.match(r'^[a-z0-9-]+$', name):
            return False, f"Name '{name}' should be hyphen-case (lowercase letters, digits, and hyphens only)"
        if name.startswith('-') or name.endswith('-') or '--' in name:
            return False, f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens"
        # Check name length (max 64 characters per spec)
        if len(name) > 64:
            return False, f"Name is too long ({len(name)} characters). Maximum is 64 characters."

    # Extract and validate description
    description = frontmatter.get('description', '')
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        # Check for angle brackets
        if '<' in description or '>' in description:
            return False, "Description cannot contain angle brackets (< or >)"
        # Check description length (max 1024 characters per spec)
        if len(description) > 1024:
            return False, f"Description is too long ({len(description)} characters). Maximum is 1024 characters."

    if yaml is None:
        return True, "Skill is valid! (fallback parser: PyYAML not installed)"
    return True, "Skill is valid!"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)
    
    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
