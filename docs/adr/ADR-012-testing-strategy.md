# ADR-012: Testing Strategy

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-001-state-management]], [[ADR-007-gamification-logic]]

---

## Decision

**Unit tests for all Riverpod notifiers (gamification logic). Widget tests for the lesson player flow. No integration or golden tests in v1.**

---

## Unit Test Scope

All pure-Dart logic in Riverpod notifiers is unit-tested with `ProviderContainer` and mock DAOs:

| Notifier | What is tested |
|----------|---------------|
| `StreakNotifier` | All five branches: first lesson ever (null `last_active_date`) / same day / yesterday / gap with enough freezes / gap with too few freezes. Include the one-freeze-per-missed-day accounting (e.g. 2-day gap with 1 freeze must reset; 2-day gap with 2 freezes must hold) |
| `ProgressNotifier` | XP award (lesson, module bonus, daily-first-lesson, first-try), level-up detection, idempotent re-completion (no double lesson XP), non-idempotent daily XP |
| `BadgeNotifier` | Module completion trigger, track completion trigger, freeze award |
| `SkillTreeNotifier` | Correct module lock/unlock state from a given set of completed lesson IDs |
| `levelForXp()` | Boundary values for all level thresholds |

Mock DAOs use Mockito (`build_mock` annotation). No SQLite in unit tests.

---

## Widget Test Scope

Key flows tested with `WidgetTester`:

- Multiple choice step: tap correct answer → XP animation → next step.
- Multiple choice step: tap wrong answer → error color → explanation shown.
- Write-a-prompt step: enter text → submit → model answer revealed → self-eval buttons.
- Lesson completion screen: XP awarded, streak updated, share button visible.
- Skill tree: locked module shows lock icon, tapping shows prerequisite message.

---

## What Is Not Tested in v1

- Golden / screenshot tests (brittle, high maintenance for a frequently-iterated UI).
- Integration tests on a physical device (adds CI device provisioning complexity).
- Content JSON schema validation (enforced by the Dart `fromJson` constructors — parse errors fail at runtime).

---

## Test File Convention

```
test/
  unit/
    streak_notifier_test.dart
    progress_notifier_test.dart
    badge_notifier_test.dart
    skill_tree_notifier_test.dart
    level_for_xp_test.dart
  widget/
    lesson_player_mc_test.dart
    lesson_player_write_prompt_test.dart
    lesson_completion_test.dart
    skill_tree_test.dart
```

---

## Packages

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.x
  build_runner: ^2.x  # already present for Riverpod codegen
```
