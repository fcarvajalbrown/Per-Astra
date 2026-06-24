/// Lesson-completion orchestration (ADR-007).
///
/// Coordinates the responsibilities the ADR splits across ProgressNotifier,
/// StreakNotifier, and BadgeNotifier: it persists the lesson_progress row,
/// updates XP/level, advances the streak and freeze inventory, and unlocks
/// module/track badges — all in one transaction-like sequence per completion.
/// The result is held in provider state so the lesson-complete screen can show
/// what was earned after the router navigates to it.
library;

import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../content/models.dart';
import '../data/database.dart';
import '../data/providers.dart';
import 'streak.dart';
import 'xp.dart';

part 'lesson_completion.g.dart';

/// What a single lesson completion awarded, for display on the complete screen.
@immutable
class LessonCompletionResult {
  const LessonCompletionResult({
    required this.lessonId,
    required this.lessonXp,
    required this.dailyBonus,
    required this.firstTryBonus,
    required this.moduleBonus,
    required this.totalXpBefore,
    required this.totalXpAfter,
    required this.levelBefore,
    required this.levelAfter,
    required this.currentStreak,
    required this.streakIncreased,
    required this.freezesAwarded,
    required this.badgesEarned,
  });

  final String lessonId;

  /// Base lesson XP — awarded only on first completion (idempotent re-play).
  final int lessonXp;

  /// 30 XP for the first lesson completed on a new calendar day.
  final int dailyBonus;

  /// 5 XP when every multiple-choice answer was correct on first tap.
  final int firstTryBonus;

  /// 50 XP when this completion finished the module for the first time.
  final int moduleBonus;

  final int totalXpBefore;
  final int totalXpAfter;
  final int levelBefore;
  final int levelAfter;
  final int currentStreak;
  final bool streakIncreased;

  /// Freeze items granted this completion (7-day milestone, module, track).
  final int freezesAwarded;

  /// Badge ids unlocked this completion.
  final List<String> badgesEarned;

  int get xpEarned => lessonXp + dailyBonus + firstTryBonus + moduleBonus;
  bool get leveledUp => levelAfter > levelBefore;
}

/// Records lesson completions and exposes the most recent result.
@Riverpod(keepAlive: true)
class LessonCompletion extends _$LessonCompletion {
  @override
  LessonCompletionResult? build() => null;

  /// Persists a completion of [lessonId] in [moduleId] and updates all
  /// gamification state. Returns (and stores) the resulting award summary.
  ///
  /// [lessonXpValue] is the content-declared base XP; [hasMultipleChoice] and
  /// [allFirstTryCorrect] drive the first-try bonus; [writePromptPassed]
  /// records the self-evaluation outcome for the write-a-prompt step.
  Future<LessonCompletionResult> record({
    required String lessonId,
    required String moduleId,
    required int lessonXpValue,
    required bool hasMultipleChoice,
    required bool allFirstTryCorrect,
    required bool writePromptPassed,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final content = ref.read(contentRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final nowMs = now.millisecondsSinceEpoch;
    final today = isoDate(now);

    final profile = await _ensureProfile(db, nowMs);
    final xpBefore = profile.totalXp;
    final levelBefore = profile.level;

    // Prior progress determines idempotent vs. repeatable XP sources.
    final priorProgress = await db.progressDao.getAllProgress();
    final isFirstCompletion =
        !priorProgress.any((r) => r.lessonId == lessonId);
    final completedToday = priorProgress.any(
      (r) => isoDate(DateTime.fromMillisecondsSinceEpoch(r.completedAt)) ==
          today,
    );

    final lessonXp = isFirstCompletion ? lessonXpValue : 0;
    final firstTryBonus =
        (isFirstCompletion && hasMultipleChoice && allFirstTryCorrect)
            ? xpFirstTryBonus
            : 0;
    final dailyBonus = completedToday ? 0 : xpDailyFirstLesson;

    // Module / track badge + bonus detection against post-completion state.
    final modules = await content.loadModules();
    final completedAfter = <String>{
      for (final r in priorProgress) r.lessonId,
      lessonId,
    };
    bool moduleComplete(Module m, bool Function(String) done) =>
        m.lessonIds.isNotEmpty && m.lessonIds.every(done);
    bool wasDone(String id) => priorProgress.any((r) => r.lessonId == id);

    final existingBadges =
        (await db.badgeDao.getAllBadges()).map((b) => b.badgeId).toSet();
    final badgesEarned = <String>[];
    var moduleBonus = 0;
    var freezesAwarded = 0;

    final module = modules.firstWhere(
      (m) => m.id == moduleId,
      orElse: () => throw StateError('Unknown module: $moduleId'),
    );
    final moduleNowComplete = moduleComplete(module, completedAfter.contains);
    final moduleWasComplete = moduleComplete(module, wasDone);
    if (moduleNowComplete && !moduleWasComplete) {
      moduleBonus = xpModuleCompletionBonus;
      freezesAwarded += 1; // ADR-007: complete any module -> +1 freeze
      final badgeId = 'module_${moduleId}_complete';
      if (existingBadges.add(badgeId)) {
        await db.badgeDao.insertBadge(
          BadgesCompanion.insert(badgeId: badgeId, earnedAt: nowMs),
        );
        badgesEarned.add(badgeId);
      }
    }

    final trackNowComplete = modules.isNotEmpty &&
        modules.every((m) => moduleComplete(m, completedAfter.contains));
    final trackWasComplete = modules.isNotEmpty &&
        modules.every((m) => moduleComplete(m, wasDone));
    if (trackNowComplete && !trackWasComplete) {
      freezesAwarded += 2; // ADR-007: earn the track certificate -> +2 freezes
      const trackBadge = 'track_developer_v1_complete';
      if (existingBadges.add(trackBadge)) {
        await db.badgeDao.insertBadge(
          BadgesCompanion.insert(badgeId: trackBadge, earnedAt: nowMs),
        );
        badgesEarned.add(trackBadge);
      }
    }

    // Streak: advance, then apply the 7-day-milestone freeze and any module /
    // track freezes earned above.
    final before = await _readStreak(db);
    final afterStreak = advanceStreak(before, now);
    if (afterStreak.currentStreak >= 7 && before.longestStreak < 7) {
      freezesAwarded += 1; // ADR-007: first 7-day streak -> +1 freeze
    }
    await db.streakDao.upsertStreak(
      StreaksCompanion(
        id: const Value(1),
        currentStreak: Value(afterStreak.currentStreak),
        longestStreak: Value(afterStreak.longestStreak),
        lastActiveDate: Value(afterStreak.lastActiveDate),
        freezeCount: Value(afterStreak.freezeCount + freezesAwarded),
      ),
    );

    // Persist the lesson row and the running XP/level total.
    final earned = lessonXp + firstTryBonus + dailyBonus + moduleBonus;
    await db.progressDao.upsertProgress(
      LessonProgressEntriesCompanion.insert(
        lessonId: lessonId,
        moduleId: moduleId,
        completedAt: nowMs,
        xpEarned: earned,
        writePromptPassed: writePromptPassed,
      ),
    );
    final xpAfter = xpBefore + earned;
    final levelAfter = levelForXp(xpAfter);
    await db.profileDao.upsertProfile(
      UserProfilesCompanion(
        id: Value(profile.id),
        totalXp: Value(xpAfter),
        level: Value(levelAfter),
        createdAt: Value(profile.createdAt),
      ),
    );

    final result = LessonCompletionResult(
      lessonId: lessonId,
      lessonXp: lessonXp,
      dailyBonus: dailyBonus,
      firstTryBonus: firstTryBonus,
      moduleBonus: moduleBonus,
      totalXpBefore: xpBefore,
      totalXpAfter: xpAfter,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      currentStreak: afterStreak.currentStreak,
      streakIncreased: afterStreak.currentStreak > before.currentStreak,
      freezesAwarded: freezesAwarded,
      badgesEarned: List.unmodifiable(badgesEarned),
    );
    state = result;
    return result;
  }

  /// Returns the profile row, creating it with a local UUID on first run
  /// (ADR-003: local-only identity in v1).
  Future<UserProfile> _ensureProfile(AppDatabase db, int nowMs) async {
    final existing = await db.profileDao.getProfile();
    if (existing != null) return existing;
    await db.profileDao.upsertProfile(
      UserProfilesCompanion.insert(id: _localUuid(), createdAt: nowMs),
    );
    return (await db.profileDao.getProfile())!;
  }

  Future<StreakState> _readStreak(AppDatabase db) async {
    final row = await db.streakDao.getStreak();
    if (row == null) return const StreakState.empty();
    return StreakState(
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      lastActiveDate: row.lastActiveDate,
      freezeCount: row.freezeCount,
    );
  }
}

/// Generates an RFC-4122-shaped v4 UUID. Sufficient as a local device id in v1;
/// the secure-keychain handling for the v2 migration is out of scope (ADR-003).
String _localUuid() {
  final rng = math.Random();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
