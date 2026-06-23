# ADR-007: Gamification Logic

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-001-state-management]], [[ADR-006-local-database-schema]]

---

## Context

Per Astra's retention mechanics are streak, XP, levels, streak freeze, and badge unlock. These rules must be implemented consistently across the app and be unit-testable without a running Flutter widget tree.

---

## Decision

**All gamification logic runs in pure Dart inside Riverpod `Notifier` / `AsyncNotifier` classes (generated via `@riverpod`, per ADR-001). No server, no rules engine. XP and level thresholds are compile-time constants.**

Terminology: these are codegen `Notifier`/`AsyncNotifier` classes, not the legacy `StateNotifier` API. `@riverpod` (ADR-001) generates `Notifier`-family classes; `StateNotifier` is a separate, pre-codegen pattern and is demoted to legacy in Riverpod 3.0. Do not mix the two.

---

## Rules

### XP

```dart
const int xpPerLesson = 20;            // first completion of a lesson
const int xpModuleCompletionBonus = 50; // awarded once per module
const int xpFirstTryBonus = 5;          // all MC questions in a lesson correct on first tap
const int xpDailyFirstLesson = 30;      // first lesson completed on a new calendar day

const List<int> levelThresholds = [
  0,    // Level 1
  100,  // Level 2
  250,  // Level 3
  500,  // Level 4
  900,  // Level 5
  1400, // Level 6
  2000, // Level 7
  2700, // Level 8
  3500, // Level 9
  4500, // Level 10
];

int levelForXp(int xp) {
  for (var i = levelThresholds.length - 1; i >= 0; i--) {
    if (xp >= levelThresholds[i]) return i + 1;
  }
  return 1;
}
```

**XP reachability.** Lesson XP is idempotent — re-completing a lesson awards no additional lesson XP (the `lesson_progress` row is updated in place per ADR-006). Lesson + module XP alone totals 40×20 + 4×50 = 1,000 XP, which would cap a full-track completion at level 5 and leave levels 6–10 permanently unreachable. To keep the curve meaningful, two repeatable, non-idempotent sources are added:

- **Daily-first-lesson XP (`xpDailyFirstLesson`, 30):** awarded the first time a lesson is completed on each new calendar date. This is the streak-aligned source — it accrues with engagement, not just content volume.
- **First-try bonus (`xpFirstTryBonus`, 5):** awarded when every multiple-choice question in a lesson is answered correctly on first tap. Encourages real learning over guessing; idempotent per lesson (recorded alongside `write_prompt_passed`).

A learner who completes the 40-lesson track over a typical ~30 active days earns roughly 1,000 (lessons + modules) + ~900 (daily) + up to 200 (first-try) ≈ 2,000+ XP, reaching level 7–8, with levels 9–10 attainable through sustained daily practice. This makes the full level curve reachable without inflating per-lesson XP.

### Streak (see also ADR-006)

Logic runs in `StreakNotifier` on every lesson completion. Let `gap = today - last_active_date` in whole local calendar days and `missedDays = gap - 1`:

1. Read `last_active_date` from DB.
2. **First lesson ever** (`last_active_date == null`): `current_streak = 1`, `last_active_date = today`.
3. `gap == 0` (today): no-op — streak already counted.
4. `gap == 1` (yesterday): `current_streak += 1`, `last_active_date = today`.
5. `gap >= 2` and `freeze_count >= missedDays`: one freeze per missed day — `freeze_count -= missedDays`, `current_streak += 1`, `last_active_date = today`.
6. `gap >= 2` and `freeze_count < missedDays`: not enough freezes — `current_streak = 1`, `freeze_count = 0`, `last_active_date = today`.
7. `longest_streak = max(longest_streak, current_streak)`.
8. Persist to DB, invalidate Riverpod provider.

One freeze rescues exactly one missed calendar day; a multi-day gap consumes one freeze per missed day or the streak resets. Date comparison uses the device's local calendar date (not UTC) to match user expectation. This logic must stay identical to the copy in ADR-006 — if one changes, change both.

### Streak Freeze Acquisition

Freeze items are earned only — never purchased in v1:

| Trigger | Freezes awarded |
|---------|----------------|
| Reach a 7-day streak for the first time | +1 |
| Complete any module | +1 |
| Earn the track certificate | +2 |

### Badge Unlock

Badges are checked after every lesson completion:

```dart
// Pseudo-logic in LessonCompletionNotifier
if (allLessonsInModuleComplete(moduleId)) {
  awardBadge('module_${moduleId}_complete');
  awardXp(xpModuleCompletionBonus);
  awardStreakFreeze(1);
}
if (allModulesComplete()) {
  awardBadge('track_developer_v1_complete');
  awardStreakFreeze(2);
}
```

---

## Notifier Responsibilities

| Notifier | Owns |
|----------|------|
| `ProgressNotifier` | XP, level, lesson_progress writes |
| `StreakNotifier` | Streak logic, freeze inventory |
| `BadgeNotifier` | Badge detection, badge DB writes |
| `SkillTreeNotifier` | Derived: reads lesson_progress to compute locked/unlocked state |

All notifiers are Riverpod `@riverpod` classes. They read/write Drift DAOs injected as providers.

---

## Consequences

**Positive:**
- All logic is pure Dart — fully unit-testable without widget or DB dependencies (inject mock DAOs).
- Constants can be tuned without schema changes.
- No async complexity beyond DB reads/writes.

**Negative:**
- Level cap at 10 for v1. Extending requires adding thresholds to the constant (trivial, no migration).
- Freeze acquisition rules are hardcoded — changing them requires a code release.
