# ADR-002: Backend Architecture and Data Persistence

**Status:** Accepted
**Date:** 2026-06-23

---

## Context

Per Astra v1 is a free, open source mobile app with no monetization and no user accounts. The data that needs to persist across sessions is:

- Completed lesson IDs
- Total XP and current level
- Daily streak count and last-completed date
- Streak freeze inventory
- Earned badges
- User-configured notification time

The write-a-prompt exercise mechanic requires evaluating whether a learner's prompt produces an output that meets a spec. This would normally require a call to the Claude API, which cannot have its key embedded in a compiled mobile app binary.

---

## Decision

**v1 is fully local and offline. No backend, no cloud service, no API calls at runtime.**

Specifically:
1. All user progress is persisted on-device using **Drift** (SQLite for Flutter) with a typed schema.
2. The **write-a-prompt exercises show a model answer after the learner submits**, and the learner self-evaluates. No live AI grader in v1.
3. Exercise content (questions, answers, model prompt answers) is **bundled with the app** as a JSON asset, not fetched from a server.
4. There is no authentication, no user account, and no remote sync in v1.

---

## Rationale

**No backend in v1 is the right call because:**
- The product goal is habit formation and learning, not cross-device sync. Single-device is sufficient for v1.
- The target user is a developer who is happy to install an app and have their progress live on their device.
- Eliminating the backend eliminates all runtime costs, rate limiting concerns, and API key security problems.
- Open source apps that call third-party APIs with a shared key create abuse vectors. BYOK (user provides key) was considered but adds friction for first-time users. Self-evaluation removes the problem entirely.

**Self-evaluation for write-a-prompt is acceptable for v1 because:**
- The model answer shown after submission teaches the learner the correct pattern even if they got it wrong.
- Self-assessment is used effectively in spaced repetition tools like Anki (learner rates their own recall).
- The multiple choice portion of each lesson provides objective graded feedback. Write-a-prompt is the practice rep, not a test.

---

## Consequences

**Positive:**
- Zero runtime infrastructure cost.
- App works fully offline.
- No API key management, no rate limiting, no abuse vectors.
- Simpler Flutter codebase (no HTTP client, no auth client, no network error states for v1).

**Negative:**
- No cross-device progress sync. If a user loses their phone or reinstalls, progress is lost.
- No live Claude grader means write-a-prompt is less interactive than originally specified in the PRD. (PRD §5/§7 have been updated to reflect self-evaluation; the live grader is tracked as a v2+ item in ADR-019.)
- v2 migration will need a data export/import or cloud sync path for users who have local-only progress.
- Exercise content updates require an app update (since exercises are bundled assets), unless we add a lightweight update mechanism later.

---

## v1 to v2 Migration Path (documented here to inform v2 planning)

When user accounts are added in v2, the migration must:
1. Detect existing local Drift database on first login.
2. Offer the user the option to upload local progress to their new account.
3. Keep local-first as the primary data path; remote is a sync layer, not the source of truth.

---

## Alternatives Considered

| Option | Reason not chosen |
|--------|------------------|
| BYOK (user enters Anthropic API key) | Adds friction for first-time users; requires network, error handling, and key storage in v1 scope. Better fit for v2 or a power-user toggle. |
| Shared public proxy with rate limiting | Costs money proportional to usage. Creates an abuse surface. Contradicts the fully-local decision. |
| Firebase | Overkill for v1 (accounts out of scope). Adds Google lock-in. Deferred to v2 backend evaluation. |
| Supabase | Same as Firebase — correct choice for v2 if we want open-source backend; premature for v1. |

---

## Packages

```yaml
dependencies:
  drift: ^2.x          # typed SQLite ORM for local persistence
  sqlite3_flutter_libs: ^0.5.x
  path_provider: ^2.x  # locate the database file on device
```
