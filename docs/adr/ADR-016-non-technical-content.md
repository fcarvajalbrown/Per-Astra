# ADR-016: Non-Technical Track Content Strategy

**Status:** Proposed — deferred to v2
**Date:** 2026-06-23

---

## Context

The v2 non-technical / business-user track needs roughly 40 lessons of content. There are two candidate sourcing approaches:

1. Author original content from scratch, following Per Astra's exercise authoring guide.
2. Derive exercises from Anthropic Academy's non-technical courses.

These two sources are different things: the developer-focused `anthropics/courses` GitHub repo is published under Apache 2.0, while the Anthropic Academy courses are hosted on Skilljar under Anthropic's site terms. Choosing a source — and reviewing the terms that apply to whichever source is chosen — is a content-sourcing decision for the project owner. This ADR does not assess or decide that; it is not within scope here.

---

## Decision

**Recommended: author original content from scratch** for the non-technical track, using the same authoring guide that governs community contributions.

Rationale (product, not legal):
- Fully owned by Per Astra — no dependency on any external source's structure or availability.
- Can ship in the open repo and accept community contributions from day one.
- Keeps the non-technical content pipeline identical to the developer-track pipeline (ADR-011), so there is one workflow to maintain.

Deriving from Anthropic Academy material is an alternative the owner may choose instead. If so, the owner decides how that material is sourced and used.

---

## Consequences

- Original authoring is slower than generating drafts from existing source material, so build extra content lead time into the v2 schedule.
- This does not affect v1 or block v2 launch — the developer track (Apache-2.0-sourced, ADR-011) is independent of this decision.
