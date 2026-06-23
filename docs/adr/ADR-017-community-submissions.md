# ADR-017: Community Exercise Submission Workflow

**Status:** Accepted (Deferred — implement at v2 start)
**Date:** 2026-06-23
**Depends on:** [[ADR-005-content-format]], [[ADR-011-content-pipeline]]

---

## Decision

**Community submissions via GitHub Pull Request to the Per Astra open-source repository. No in-app submission form in v2.**

---

## Rationale

The developer audience already uses GitHub. A PR-based workflow:
- Requires zero additional infrastructure.
- Uses GitHub's existing diff, comment, and review tools.
- Makes the content corpus fully transparent and auditable.
- Lets contributors fix typos and improve existing exercises with the same flow.

---

## Contributor Flow

1. Contributor forks the Per Astra repo.
2. Runs `tools/content_pipeline/generate_exercises.py` (ADR-011) or writes a lesson JSON manually.
3. Validates against the schema using `tools/validate_lesson.py` (a companion validation script).
4. Opens a PR with the new/updated lesson JSON file.
5. PR template auto-fills: lesson ID, module, checklist (schema valid, model answer tested, explanation for wrong answers written).
6. Maintainer reviews: checks content quality, tests the model answer prompt manually, merges.
7. Content is bundled in the next app release.

---

## Repository Structure

```
per-astra/
  assets/
    content/
      modules.json
      lessons/
        m1-l1.json     # shipped content
        ...
      draft/
        m1-l8.json     # contributor drafts, not yet approved
  tools/
    content_pipeline/
      generate_exercises.py
      validate_lesson.py   # JSON schema validation CLI
    CONTRIBUTING.md        # contributor guide with exercise authoring standards
```

---

## Authoring Guide (`CONTRIBUTING.md` excerpt)

The guide covers:
- Exercise JSON schema with field-by-field explanation.
- Standards for multiple choice questions (one unambiguously correct answer, plausible distractors, no trick questions).
- Standards for write-a-prompt exercises (task must be completable in one well-crafted prompt, model answer must be a real prompt tested against Claude).
- How to run `validate_lesson.py` before submitting.
- Review process and timeline expectations.

---

## v3 Consideration

An in-app submission form (users submit exercises without GitHub) opens the contributor pool to non-developers. Deferred to v3 after the GitHub flow is validated and the Supabase moderation backend (ADR-014) is in place.

---

## Consequences

**Positive:**
- Zero infrastructure cost.
- Content quality gate is high (GitHub PR review).
- Transparent history of who contributed what and why.

**Negative:**
- Excludes non-developer contributors (no GitHub account required for v2 non-technical track users).
- Content updates still require an app release to reach users (consistent with ADR-005).
