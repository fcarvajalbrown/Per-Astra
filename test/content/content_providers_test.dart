import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:per_astra/content/content_providers.dart';
import 'package:per_astra/data/database.dart';
import 'package:per_astra/data/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> completeLesson(String lessonId, String moduleId) {
    return db.progressDao.upsertProgress(
      LessonProgressEntriesCompanion.insert(
        lessonId: lessonId,
        moduleId: moduleId,
        completedAt: 1000,
        xpEarned: 20,
        writePromptPassed: true,
      ),
    );
  }

  ModuleStatus statusFor(List<ModuleStatus> all, String id) =>
      all.firstWhere((s) => s.module.id == id);

  test('with no progress, only the prerequisite-free module is unlocked',
      () async {
    final statuses = await container.read(moduleStatusesProvider.future);

    expect(statusFor(statuses, 'm1').locked, isFalse);
    expect(statusFor(statuses, 'm2').locked, isTrue);
    expect(statusFor(statuses, 'm1').completedLessons, 0);
  });

  test('completing all of a module unlocks its dependents and marks it complete',
      () async {
    await completeLesson('m1-l1', 'm1');
    await completeLesson('m1-l2', 'm1');

    final statuses = await container.read(moduleStatusesProvider.future);

    expect(statusFor(statuses, 'm1').isComplete, isTrue);
    expect(statusFor(statuses, 'm1').completedLessons, 2);
    expect(statusFor(statuses, 'm2').locked, isFalse);
    // m3 still locked: its prerequisite m2 has no completed lessons.
    expect(statusFor(statuses, 'm3').locked, isTrue);
  });

  test('partial module completion does not unlock dependents', () async {
    await completeLesson('m1-l1', 'm1');

    final statuses = await container.read(moduleStatusesProvider.future);
    expect(statusFor(statuses, 'm1').isComplete, isFalse);
    expect(statusFor(statuses, 'm2').locked, isTrue);
  });
}
