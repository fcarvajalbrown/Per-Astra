# ADR-006: Local Database Schema (Drift)

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-002-backend-and-data]], [[ADR-003-authentication]]

---

## Context

Per Astra v1 stores all user state on-device using Drift (typed SQLite). The schema must cover:

- User identity and preferences
- Streak logic (daily reset, freeze inventory)
- XP accumulation and level
- Lesson completion records
- Earned badges

The schema must also be designed so that a v2 cloud migration is straightforward: column names and types should map cleanly to a relational backend (Supabase/PostgreSQL) without a transformation layer.

---

## Decision

**Track completion and score only — no per-question or per-attempt history in v1.**

---

## Schema

### Table: `user_profile`

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PRIMARY KEY | Local UUID (from secure keychain, ADR-003) |
| `display_name` | TEXT NULLABLE | Optional name shown on certificate |
| `total_xp` | INTEGER DEFAULT 0 | Running total |
| `level` | INTEGER DEFAULT 1 | Derived from total_xp, recalculated on insert |
| `notification_hour` | INTEGER DEFAULT 20 | Hour (0-23) for daily reminder |
| `notification_minute` | INTEGER DEFAULT 0 | |
| `created_at` | INTEGER | Unix timestamp ms |

Single row only. No multi-user support in v1.

---

### Table: `streak`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER PRIMARY KEY | Always 1 (single row) |
| `current_streak` | INTEGER DEFAULT 0 | Consecutive days with at least one lesson |
| `longest_streak` | INTEGER DEFAULT 0 | All-time high |
| `last_active_date` | TEXT NULLABLE | ISO date string YYYY-MM-DD |
| `freeze_count` | INTEGER DEFAULT 0 | Available streak freeze items |

**Streak logic (implemented in a Riverpod notifier, not in the DB):**
Let `gap = (today - last_active_date)` in whole calendar days (local time). `missedDays = gap - 1` (the days between last activity and today on which nothing was completed).
1. On lesson completion, read `last_active_date`.
2. **First lesson ever** (`last_active_date == null`): `current_streak = 1`, set `last_active_date = today`.
3. `gap == 0` (today): no change to streak (already counted).
4. `gap == 1` (yesterday): `current_streak += 1`, set `last_active_date = today`.
5. `gap >= 2` and `freeze_count >= missedDays`: **one freeze covers one missed day** — `freeze_count -= missedDays`, keep `current_streak`, then `current_streak += 1` for today, set `last_active_date = today`.
6. `gap >= 2` and `freeze_count < missedDays`: not enough freezes to bridge the gap — `current_streak = 1`, `freeze_count = 0`, set `last_active_date = today`.
7. After any change, update `longest_streak = max(longest_streak, current_streak)`.

A single freeze rescues exactly one missed calendar day. A 3-day gap (two missed days) requires two freezes, or the streak resets. This matches user expectation from Duolingo-style streak freezes.

---

### Table: `lesson_progress`

| Column | Type | Notes |
|--------|------|-------|
| `lesson_id` | TEXT PRIMARY KEY | Matches the `id` field in the JSON asset |
| `module_id` | TEXT NOT NULL | Denormalized for fast module-level queries |
| `completed_at` | INTEGER NOT NULL | Unix timestamp ms |
| `xp_earned` | INTEGER NOT NULL | XP recorded at time of completion |
| `write_prompt_passed` | INTEGER NOT NULL | 1 = learner self-rated pass, 0 = fail |

No attempt history. One row per lesson. Re-doing a lesson updates `completed_at` and `write_prompt_passed` in place (REPLACE INTO).

---

### Table: `badges`

| Column | Type | Notes |
|--------|------|-------|
| `badge_id` | TEXT PRIMARY KEY | e.g. `module_1_complete`, `track_complete` |
| `earned_at` | INTEGER NOT NULL | Unix timestamp ms |
| `shared_linkedin` | INTEGER DEFAULT 0 | 1 = user has shared this badge |

---

## XP and Level Thresholds

Level thresholds are defined as a constant in the app (not stored in DB) so they can be adjusted without a migration:

```dart
const levelThresholds = [0, 100, 250, 500, 900, 1400, 2000, 2700, 3500, 4500];
// Level 1 = 0 XP, Level 2 = 100 XP, Level 10 = 4500 XP
```

XP sources (canonical definition in ADR-007): 20 XP per lesson, 50 XP module-completion bonus, plus per-day and first-try XP so that completing the full Developer Track reaches near the top of the curve rather than stalling at level 5. Lesson/bonus XP alone (40 lessons + 4 modules = 1,000 XP) would cap a 100% completion at level 5; the additional sources in ADR-007 are sized so the level curve stays meaningful through level 10. See ADR-007 for the full XP table and the reachability rationale.

---

## Consequences

**Positive:**
- Simple schema, easy to reason about and test.
- Column names map directly to a PostgreSQL schema for v2 cloud migration.
- No write amplification — one row per lesson, updated on replay.

**Negative:**
- No per-question data means spaced repetition in v2 will start fresh (no historical difficulty data from v1).
- Re-doing a completed lesson overwrites the original completion — no history of improvement over time.

---

## v2 Migration Notes

The `lesson_progress` table maps directly to a cloud table of the same schema. Migration in v2: read all rows from local Drift, POST to backend in a single batch on first account creation. The `user_profile.id` UUID becomes the foreign key in the cloud schema.

Note: the mapping is near-direct but not zero-transform. Timestamps are stored here as INTEGER Unix-ms and booleans as INTEGER 0/1; a PostgreSQL target will typically use `timestamptz` and `boolean`. This is a thin conversion at the sync layer, not a schema redesign — call it out so v2 does not assume a literal column-for-column copy.

---

## Packages

```yaml
dependencies:
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  path_provider: ^2.x

dev_dependencies:
  drift_dev: ^2.x
  build_runner: ^2.x
```
