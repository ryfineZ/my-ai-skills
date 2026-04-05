# workflow

## Goal

Turn a topic plus light background into a publishable technical article through an interactive drafting workflow.

The workflow should feel like collaborative writing, not batch generation.

## Default Flow

1. Read the user's topic, intent, and any background they already provided.
2. Identify the likely article type:
   - technical practice recap
   - architecture/design explanation
   - tool or workflow evaluation
   - issue/incident writeup
   - version/update interpretation
3. Decide research depth:
   - light research by default
   - upgrade to deep research only when source uncertainty is important
4. Produce the opening 1-2 paragraphs, not the full article.
5. Ask one direction-changing question only if needed.
6. Continue drafting in small batches.
7. Once the article body stabilizes, generate the final WeChat draft.
8. Compress the same argument into an X thread.

## Question Policy

Questions are expensive. Use them only when the answer would change:

- the article's thesis
- the target audience
- the level of technical detail
- the position taken on a disputed point
- the publish destination or format

Do not ask questions for details that can be inferred from the user's background or from lightweight research.

When you do ask, ask exactly one question.

## Research Policy

Use `agent-reach` for:

- current web search
- reading links the user provided
- checking platform discussions
- collecting lightweight supporting context

Use `deep-research` for:

- disputed or controversial claims
- multi-source comparisons
- situations where the article will rely on citation-backed argument

If the article is mostly a first-hand implementation recap, do not over-research it.

## Drafting Rhythm

Each drafting round should do one of these:

- advance the article by 1-2 paragraphs
- replace a weak section with a stronger version
- tighten the argument based on a user answer

Do not repeatedly restate the whole structure.

If the user says the writing sounds too much like AI:

- keep the facts
- reduce template headings
- shorten transitions
- replace generic meta-explanations with concrete observations
- keep the user's viewpoint closer to the front

## Completion Condition

The workflow ends when all of these are true:

- WeChat draft is coherent and publishable
- article argument is clear early
- implementation details are concrete enough
- X thread version exists
- output has been written to the Obsidian draft directory if requested
