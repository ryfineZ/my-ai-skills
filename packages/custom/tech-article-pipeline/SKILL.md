---
name: tech-article-pipeline
description: "Write publishable technical articles from a clear topic plus a small amount of background. Use when the user wants to turn a technical practice, architecture change, tool evaluation, workflow upgrade, or incident analysis into a WeChat-ready draft and an X thread. The workflow is collaborative: decide whether research is light or deep, draft 1-2 paragraphs at a time, and ask only one direction-changing question when needed."
---

# Tech Article Pipeline

## Overview

This skill is for technical content production, not generic copywriting.

Input should be:

- a clear topic
- a small amount of background or intent
- optional source links, notes, screenshots, or local files

Default outputs:

- a publishable WeChat draft
- an X thread version
- a Markdown file written into the Obsidian draft directory

## Workflow

Read `references/workflow.md` before starting.

Use this workflow:

1. Clarify the topic and desired article direction from the user's short background.
2. Decide whether the task needs light research or deep research.
3. Draft only 1-2 paragraphs at a time.
4. Ask at most one direction-changing question at a time, only when the answer would materially change the article.
5. Continue drafting from the approved direction instead of restarting from scratch.
6. Converge into:
   - WeChat long-form draft
   - X thread version
   - optional title candidates and cover copy

## Research Mode Selection

Use `agent-reach` when:

- the topic needs current web information
- the user provides links to web pages, videos, posts, or platform content
- you need lightweight fact collection fast

Use `deep-research` when:

- the topic is disputed, high-stakes, or strongly time-sensitive
- the article depends on multi-source comparison
- source quality will materially affect the argument

If the topic is mainly a personal technical practice recap, default to light research.

## Drafting Rules

Do not force a fixed article template.

Instead, enforce these writing constraints:

- open with a concrete entry point, not generic framing
- surface the author's core judgment early
- spend most of the article on architecture, implementation, tradeoffs, and concrete details
- preserve technical facts, names, paths, commands, versions, and dates
- prefer specific evidence over broad claims
- avoid standard AI listicles unless the material is inherently list-shaped
- keep the collaboration iterative: each round should move the draft forward, not re-summarize the whole article

If the user dislikes the current direction, revise from the last accepted section instead of regenerating the whole draft blindly.

## Output Contract

Read `references/output-spec.md` before finalizing outputs.

Default article file target:

- root: `/Users/zhangyufan/Workspace/Obsidian/我的大脑/1-Process/01-项目/公众号运营/钢之AI术师`
- draft directory: `/Users/zhangyufan/Workspace/Obsidian/我的大脑/1-Process/01-项目/公众号运营/钢之AI术师/草稿`

When writing the final result:

- write the WeChat draft to the Obsidian draft directory
- keep Markdown frontmatter if the user wants a ready-to-publish note
- include an X thread version in the conversation output
- optionally include:
  - 3-5 title candidates
  - a short summary/deck
  - cover image copy suggestions

## What Not To Do

- do not turn every article into a tutorial
- do not force a six-part outline when the topic does not need it
- do not ask a question after every paragraph
- do not overwrite an existing draft unless the user explicitly asks
- do not fabricate citations or claim verification you did not perform
