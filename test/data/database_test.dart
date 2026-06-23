import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_astra/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('profile round-trips and upsert replaces in place', () async {
    await db.profileDao.upsertProfile(
      UserProfilesCompanion.insert(id: 'uuid-1', createdAt: 1000),
    );
    var profile = await db.profileDao.getProfile();
    expect(profile!.id, 'uuid-1');
    expect(profile.totalXp, 0); // default
    expect(profile.level, 1); // default
    expect(profile.notificationHour, 20); // default

    await db.profileDao.upsertProfile(
      const UserProfilesCompanion(
        id: Value('uuid-1'),
        totalXp: Value(120),
        level: Value(2),
        createdAt: Value(1000),
      ),
    );
    profile = await db.profileDao.getProfile();
    expect(profile!.totalXp, 120);
    expect(profile.level, 2);
  });

  test('streak persists the single row', () async {
    await db.streakDao.upsertStreak(
      const StreaksCompanion(
        id: Value(1),
        currentStreak: Value(3),
        longestStreak: Value(5),
        lastActiveDate: Value('2026-06-23'),
        freezeCount: Value(1),
      ),
    );
    final streak = await db.streakDao.getStreak();
    expect(streak!.currentStreak, 3);
    expect(streak.longestStreak, 5);
    expect(streak.lastActiveDate, '2026-06-23');
    expect(streak.freezeCount, 1);
  });

  test('lesson progress upserts and the completed-id stream updates', () async {
    final emissions = <Set<String>>[];
    final sub = db.progressDao.watchCompletedLessonIds().listen(emissions.add);

    await db.progressDao.upsertProgress(
      LessonProgressEntriesCompanion.insert(
        lessonId: 'm1-l1',
        moduleId: 'm1',
        completedAt: 1000,
        xpEarned: 20,
        writePromptPassed: true,
      ),
    );
    await db.progressDao.upsertProgress(
      LessonProgressEntriesCompanion.insert(
        lessonId: 'm1-l2',
        moduleId: 'm1',
        completedAt: 2000,
        xpEarned: 20,
        writePromptPassed: false,
      ),
    );

    final all = await db.progressDao.getAllProgress();
    expect(all, hasLength(2));

    // Re-completing updates in place rather than adding a row.
    await db.progressDao.upsertProgress(
      LessonProgressEntriesCompanion.insert(
        lessonId: 'm1-l1',
        moduleId: 'm1',
        completedAt: 3000,
        xpEarned: 20,
        writePromptPassed: true,
      ),
    );
    expect(await db.progressDao.getAllProgress(), hasLength(2));

    await Future<void>.delayed(Duration.zero);
    expect(emissions.last, {'m1-l1', 'm1-l2'});
    await sub.cancel();
  });

  test('badge inserts and markShared flips the flag', () async {
    await db.badgeDao.insertBadge(
      BadgesCompanion.insert(badgeId: 'module_m1_complete', earnedAt: 1000),
    );
    var badges = await db.badgeDao.getAllBadges();
    expect(badges.single.sharedLinkedin, isFalse);

    await db.badgeDao.markShared('module_m1_complete');
    badges = await db.badgeDao.getAllBadges();
    expect(badges.single.sharedLinkedin, isTrue);
  });
}
