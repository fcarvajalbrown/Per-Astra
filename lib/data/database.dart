/// On-device Drift (SQLite) database and DAOs (ADR-006).
///
/// Column and table names match ADR-006 exactly so the v2 cloud migration maps
/// cleanly onto a PostgreSQL schema (timestamps are INTEGER Unix-ms; booleans
/// are INTEGER 0/1 via Drift's BoolColumn). Streak and gamification logic live
/// in Riverpod notifiers (ADR-007), not in the database.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Single-row table holding user identity and preferences.
@DataClassName('UserProfile')
class UserProfiles extends Table {
  @override
  String get tableName => 'user_profile';

  TextColumn get id => text()(); // local UUID (ADR-003)
  TextColumn get displayName => text().named('display_name').nullable()();
  IntColumn get totalXp =>
      integer().named('total_xp').withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get notificationHour =>
      integer().named('notification_hour').withDefault(const Constant(20))();
  IntColumn get notificationMinute =>
      integer().named('notification_minute').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')(); // Unix ms

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row table (id always 1) holding streak state and freeze inventory.
@DataClassName('Streak')
class Streaks extends Table {
  @override
  String get tableName => 'streak';

  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get currentStreak =>
      integer().named('current_streak').withDefault(const Constant(0))();
  IntColumn get longestStreak =>
      integer().named('longest_streak').withDefault(const Constant(0))();
  TextColumn get lastActiveDate =>
      text().named('last_active_date').nullable()(); // ISO YYYY-MM-DD
  IntColumn get freezeCount =>
      integer().named('freeze_count').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per completed lesson (REPLACE on re-completion). No attempt history.
@DataClassName('LessonProgressRow')
class LessonProgressEntries extends Table {
  @override
  String get tableName => 'lesson_progress';

  TextColumn get lessonId => text().named('lesson_id')();
  TextColumn get moduleId => text().named('module_id')();
  IntColumn get completedAt => integer().named('completed_at')(); // Unix ms
  IntColumn get xpEarned => integer().named('xp_earned')();
  BoolColumn get writePromptPassed => boolean().named('write_prompt_passed')();

  @override
  Set<Column> get primaryKey => {lessonId};
}

/// One row per earned badge.
@DataClassName('Badge')
class Badges extends Table {
  @override
  String get tableName => 'badges';

  TextColumn get badgeId => text().named('badge_id')();
  IntColumn get earnedAt => integer().named('earned_at')(); // Unix ms
  BoolColumn get sharedLinkedin =>
      boolean().named('shared_linkedin').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {badgeId};
}

/// User identity and preferences (single row).
@DriftAccessor(tables: [UserProfiles])
class ProfileDao extends DatabaseAccessor<AppDatabase>
    with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Future<UserProfile?> getProfile() =>
      select(userProfiles).getSingleOrNull();

  /// Emits the (single) profile row and re-emits whenever it changes, so XP and
  /// level displays stay live without manual invalidation.
  Stream<UserProfile?> watchProfile() =>
      select(userProfiles).watchSingleOrNull();

  Future<void> upsertProfile(UserProfilesCompanion profile) =>
      into(userProfiles).insertOnConflictUpdate(profile);
}

/// Streak state and freeze inventory (single row, id = 1).
@DriftAccessor(tables: [Streaks])
class StreakDao extends DatabaseAccessor<AppDatabase> with _$StreakDaoMixin {
  StreakDao(super.db);

  Future<Streak?> getStreak() => select(streaks).getSingleOrNull();

  /// Emits the (single) streak row and re-emits whenever it changes.
  Stream<Streak?> watchStreak() => select(streaks).watchSingleOrNull();

  Future<void> upsertStreak(StreaksCompanion streak) =>
      into(streaks).insertOnConflictUpdate(streak);
}

/// Lesson completion records.
@DriftAccessor(tables: [LessonProgressEntries])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Future<List<LessonProgressRow>> getAllProgress() =>
      select(lessonProgressEntries).get();

  /// Emits the set of completed lesson ids, updating as progress changes.
  /// The skill-tree lock state is derived from this (ADR-007).
  Stream<Set<String>> watchCompletedLessonIds() {
    final query = selectOnly(lessonProgressEntries)
      ..addColumns([lessonProgressEntries.lessonId]);
    return query
        .map((row) => row.read(lessonProgressEntries.lessonId)!)
        .watch()
        .map((ids) => ids.toSet());
  }

  Future<void> upsertProgress(LessonProgressEntriesCompanion entry) =>
      into(lessonProgressEntries).insertOnConflictUpdate(entry);
}

/// Earned badges.
@DriftAccessor(tables: [Badges])
class BadgeDao extends DatabaseAccessor<AppDatabase> with _$BadgeDaoMixin {
  BadgeDao(super.db);

  Future<List<Badge>> getAllBadges() => select(badges).get();

  Future<void> insertBadge(BadgesCompanion badge) =>
      into(badges).insertOnConflictUpdate(badge);

  Future<void> markShared(String badgeId) =>
      (update(badges)..where((b) => b.badgeId.equals(badgeId)))
          .write(const BadgesCompanion(sharedLinkedin: Value(true)));
}

@DriftDatabase(
  tables: [UserProfiles, Streaks, LessonProgressEntries, Badges],
  daos: [ProfileDao, StreakDao, ProgressDao, BadgeDao],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database. Pass an in-memory [executor] in tests.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/per_astra.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
