/// Gamification XP and level rules (ADR-007).
///
/// All values are compile-time constants so they can be tuned without a DB
/// migration. Logic here is pure Dart and unit-testable without a widget tree.
library;

/// XP awarded for the first completion of a lesson.
const int xpPerLesson = 20;

/// XP awarded once per module, when its final lesson is completed.
const int xpModuleCompletionBonus = 50;

/// XP awarded when every multiple-choice question in a lesson is answered
/// correctly on the first tap. Idempotent per lesson.
const int xpFirstTryBonus = 5;

/// XP awarded the first time a lesson is completed on each new calendar date.
/// The streak-aligned, repeatable source that keeps the level curve reachable.
const int xpDailyFirstLesson = 30;

/// Cumulative XP required to reach each level. Index `i` is the threshold for
/// level `i + 1` (level 1 = 0 XP ... level 10 = 4500 XP).
const List<int> levelThresholds = <int>[
  0, // Level 1
  100, // Level 2
  250, // Level 3
  500, // Level 4
  900, // Level 5
  1400, // Level 6
  2000, // Level 7
  2700, // Level 8
  3500, // Level 9
  4500, // Level 10
];

/// Returns the level (1-based) for a given cumulative [xp].
///
/// XP at or above the top threshold returns the maximum level; negative or
/// sub-threshold XP returns level 1.
int levelForXp(int xp) {
  for (var i = levelThresholds.length - 1; i >= 0; i--) {
    if (xp >= levelThresholds[i]) return i + 1;
  }
  return 1;
}
