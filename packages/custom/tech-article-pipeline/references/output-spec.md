# output spec

## Primary Output

The primary output is a WeChat-ready Markdown draft.

Default destination:

- `/Users/zhangyufan/Workspace/Obsidian/我的大脑/1-Process/01-项目/公众号运营/钢之AI术师/草稿`

If the user provides a title, use it as the filename.
If not, generate a title candidate and use a safe Markdown filename.

## WeChat Draft Requirements

The draft should:

- read like a technical article, not a generic blog template
- front-load the central judgment or problem
- include architecture, implementation, and tradeoffs where relevant
- preserve exact technical names, paths, commands, and versions
- avoid fake citations

Optional frontmatter can include:

- `笔记路径`
- `作者`
- `封面图`

Only include frontmatter when the user wants a ready-to-publish Obsidian note.

## X Thread Output

Always produce a thread version when this skill completes unless the user opts out.

The X thread should:

- compress the core claim
- avoid repeating full technical detail
- preserve key numbers, paths, or commands only when necessary
- aim for a strong first post and clean post-to-post progression

## Optional Extras

Generate these by default unless the user narrows scope:

- 3-5 title candidates
- one short summary/deck
- cover image copy suggestions

## File Safety

- Do not overwrite an existing file silently.
- If a same-name draft already exists, create a new filename variant.
- Do not write to `已发布` by default.
- Default to `草稿`.
