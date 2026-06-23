# ADR-011: Content Pipeline Tooling

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-005-content-format]]

---

## Decision

**Python script using the Anthropic Python SDK. Lives in `tools/content_pipeline/` in the repo.**

---

## Flow

```
Anthropic GitHub course chapter (markdown)
        |
        v
  generate_exercises.py
  - reads chapter file
  - sends to Claude (claude-haiku-4-5) with structured prompt
  - requests draft exercises as JSON matching the lesson schema (ADR-005)
        |
        v
  draft output: assets/content/lessons/draft/<lesson_id>.json
        |
        v
  Human review: editor opens draft, edits, moves to assets/content/lessons/
        |
        v
  Bundled with app on next build
```

---

## Script Interface

```bash
python tools/content_pipeline/generate_exercises.py \
  --chapter courses/prompt_engineering/chapter_02_xml_tags.md \
  --module m1 \
  --lesson-id m1-l3 \
  --count 4          # number of MC questions to generate
```

Output: `assets/content/lessons/draft/m1-l3.json`

---

## Prompt Design (inside the script)

The script instructs Claude to:
1. Read the chapter and identify the 3-5 core concepts.
2. For each core concept, generate one multiple-choice question (4 options, one correct, explanation for wrong answers).
3. Generate one write-a-prompt exercise: a task description, target output spec in plain English, and a model answer prompt.
4. Return everything as a JSON object matching the lesson schema exactly.

System prompt enforces the JSON schema via an example. Output is parsed and validated before writing.

---

## Human Review Step

Every draft must be reviewed before moving to `assets/content/lessons/`. Reviewer checks:
- Is the question testing the right concept?
- Is the correct answer actually correct?
- Is the model prompt answer good (not just technically correct but idiomatic)?
- Is the task description clear to a learner who has not read the chapter?

No automated quality gate in v1. Review is manual and mandatory.

---

## Packages

```
anthropic>=0.40.0
```

No other dependencies. Standard library only (`json`, `pathlib`, `argparse`).
