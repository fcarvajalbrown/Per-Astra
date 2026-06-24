/// Core data-layer providers (ADR-001).
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../content/content_repository.dart';
import 'database.dart';

part 'providers.g.dart';

/// The single app-wide Drift database. Kept alive for the app's lifetime and
/// closed when the provider is disposed.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Repository for bundled lesson/module content.
@Riverpod(keepAlive: true)
ContentRepository contentRepository(Ref ref) => ContentRepository();

/// Wall-clock source for gamification (streak, daily-bonus) logic. Wrapped in a
/// class rather than exposed as a bare function so it round-trips through
/// Riverpod codegen; tests pin "now" by overriding with `Clock(() => date)`.
class Clock {
  Clock([DateTime Function()? now]) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime now() => _now();
}

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => Clock();

/// The set of completed lesson ids, kept live. Skill-tree lock state and
/// per-module progress are derived from this (ADR-007).
@riverpod
Stream<Set<String>> completedLessonIds(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.progressDao.watchCompletedLessonIds();
}

/// The user profile row (XP, level, preferences), kept live. Null until the
/// first lesson completion creates it.
///
/// Declared as a manual [StreamProvider] rather than via `@riverpod`: the
/// generator can't resolve drift's generated row types ([UserProfile]) in a
/// provider signature, so codegen is reserved for core-typed providers.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.profileDao.watchProfile();
});

/// The streak row (current/longest streak, freeze inventory), kept live. Manual
/// for the same reason as [userProfileProvider].
final streakStateProvider = StreamProvider<Streak?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.streakDao.watchStreak();
});
