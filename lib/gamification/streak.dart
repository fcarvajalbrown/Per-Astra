/// Pure streak logic (ADR-007, mirrored from ADR-006).
///
/// Kept free of Drift and Riverpod so the day-gap rules are unit-testable
/// without a database or widget tree. The notifier converts to/from the Drift
/// `Streak` row. Date comparison uses the device's local calendar date (not
/// UTC) to match user expectation. This logic must stay identical to the copy
/// in ADR-006 — if one changes, change both.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Database-agnostic snapshot of streak state.
@immutable
class StreakState {
  const StreakState({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.freezeCount,
  });

  /// A fresh streak with no history (matches the DB defaults).
  const StreakState.empty()
      : currentStreak = 0,
        longestStreak = 0,
        lastActiveDate = null,
        freezeCount = 0;

  final int currentStreak;
  final int longestStreak;

  /// ISO `YYYY-MM-DD` of the last day a lesson was completed, or null if never.
  final String? lastActiveDate;
  final int freezeCount;
}

/// Formats [d] as a local-calendar ISO date (`YYYY-MM-DD`).
String isoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Whole local-calendar days from [lastIso] to [now] (0 = same day).
int dayGap(String lastIso, DateTime now) {
  final parts = lastIso.split('-');
  final last = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(last).inDays;
}

/// Applies a lesson completion at [now] to [s], returning the new streak state.
///
/// Implements the ADR-007 rules: same-day completions are a no-op, a one-day
/// gap extends the streak, and a multi-day gap spends one freeze per missed day
/// or resets the streak to 1.
StreakState advanceStreak(StreakState s, DateTime now) {
  final today = isoDate(now);

  // First lesson ever.
  if (s.lastActiveDate == null) {
    return StreakState(
      currentStreak: 1,
      longestStreak: math.max(s.longestStreak, 1),
      lastActiveDate: today,
      freezeCount: s.freezeCount,
    );
  }

  final gap = dayGap(s.lastActiveDate!, now);

  // Same day (or clock skew): streak already counted today.
  if (gap <= 0) return s;

  // Completed yesterday: extend the streak.
  if (gap == 1) {
    final next = s.currentStreak + 1;
    return StreakState(
      currentStreak: next,
      longestStreak: math.max(s.longestStreak, next),
      lastActiveDate: today,
      freezeCount: s.freezeCount,
    );
  }

  // gap >= 2: one freeze rescues exactly one missed calendar day.
  final missedDays = gap - 1;
  if (s.freezeCount >= missedDays) {
    final next = s.currentStreak + 1;
    return StreakState(
      currentStreak: next,
      longestStreak: math.max(s.longestStreak, next),
      lastActiveDate: today,
      freezeCount: s.freezeCount - missedDays,
    );
  }

  // Not enough freezes: the streak resets.
  return StreakState(
    currentStreak: 1,
    longestStreak: math.max(s.longestStreak, 1),
    lastActiveDate: today,
    freezeCount: 0,
  );
}
