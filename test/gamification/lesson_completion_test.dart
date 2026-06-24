import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:per_astra/data/database.dart';
import 'package:per_astra/data/providers.dart';
import 'package:per_astra/gamification/lesson_completion.dart';

void main() {
  // ContentRepository reads the bundled seed assets via rootBundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  DateTime now = DateTime(2026, 6, 23, 9);

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(Clock(() => now)),
        ],
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = makeContainer();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<LessonCompletionResult> complete(
    String lessonId, {
    bool allFirstTryCorrect = true,
  }) {
    return container.read(lessonCompletionProvider.notifier).record(
          lessonId: lessonId,
          moduleId: 'm1',
          lessonXpValue: 20,
          hasMultipleChoice: true,
          allFirstTryCorrect: allFirstTryCorrect,
          writePromptPassed: true,
        );
  }

  test('first completion awards lesson + daily + first-try XP and starts streak',
      () async {
    final result = await complete('m1-l1');

    expect(result.lessonXp, 20);
    expect(result.dailyBonus, 30);
    expect(result.firstTryBonus, 5);
    expect(result.moduleBonus, 0); // module not finished yet
    expect(result.xpEarned, 55);
    expect(result.currentStreak, 1);
    expect(result.streakIncreased, isTrue);

    final profile = await db.profileDao.getProfile();
    expect(profile!.totalXp, 55);
    expect(profile.level, 1);
  });

  test('a missed first-try answer drops the first-try bonus', () async {
    final result = await complete('m1-l1', allFirstTryCorrect: false);
    expect(result.firstTryBonus, 0);
    expect(result.xpEarned, 50); // 20 + 30 daily
  });

  test('re-completing the same lesson awards no lesson XP and no daily repeat',
      () async {
    await complete('m1-l1');
    final again = await complete('m1-l1');

    expect(again.lessonXp, 0);
    expect(again.firstTryBonus, 0);
    expect(again.dailyBonus, 0); // already completed a lesson today
    expect(again.xpEarned, 0);

    final profile = await db.profileDao.getProfile();
    expect(profile!.totalXp, 55); // unchanged from the first completion
  });

  test('finishing the last module lesson awards the module bonus, badge, freeze',
      () async {
    await complete('m1-l1');
    final second = await complete('m1-l2'); // same day -> no daily bonus

    expect(second.lessonXp, 20);
    expect(second.dailyBonus, 0);
    expect(second.firstTryBonus, 5);
    expect(second.moduleBonus, 50);
    expect(second.xpEarned, 75);
    expect(second.badgesEarned, contains('module_m1_complete'));
    expect(second.freezesAwarded, 1); // module completion freeze

    final badges = await db.badgeDao.getAllBadges();
    expect(badges.map((b) => b.badgeId), contains('module_m1_complete'));

    final streak = await db.streakDao.getStreak();
    expect(streak!.freezeCount, 1);

    final profile = await db.profileDao.getProfile();
    expect(profile!.totalXp, 55 + 75);
  });

  test('the daily bonus returns on a new calendar day and extends the streak',
      () async {
    await complete('m1-l1');
    now = DateTime(2026, 6, 24, 9); // next day
    final nextDay = await complete('m1-l2');

    expect(nextDay.dailyBonus, 30);
    expect(nextDay.currentStreak, 2);
    expect(nextDay.streakIncreased, isTrue);
  });
}
