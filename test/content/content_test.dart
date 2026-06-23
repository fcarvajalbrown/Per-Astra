import 'package:flutter_test/flutter_test.dart';
import 'package:per_astra/content/content_repository.dart';
import 'package:per_astra/content/models.dart';

void main() {
  // Allows rootBundle to serve the assets declared in pubspec.yaml.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('model parsing', () {
    test('parses a multiple_choice step', () {
      final step = LessonStep.fromJson(const {
        'type': 'multiple_choice',
        'question': 'q?',
        'options': ['a', 'b'],
        'correctIndex': 1,
        'explanation': 'because',
      });
      expect(step, isA<MultipleChoiceStep>());
      expect((step as MultipleChoiceStep).correctIndex, 1);
    });

    test('parses a write_prompt step with default empty hints', () {
      final step = LessonStep.fromJson(const {
        'type': 'write_prompt',
        'task': 'do it',
        'modelAnswer': 'the answer',
      });
      expect(step, isA<WritePromptStep>());
      expect((step as WritePromptStep).hints, isEmpty);
    });

    test('throws on an unknown step type', () {
      expect(
        () => LessonStep.fromJson(const {'type': 'mystery'}),
        throwsFormatException,
      );
    });

    test('throws when correctIndex is out of range', () {
      expect(
        () => LessonStep.fromJson(const {
          'type': 'multiple_choice',
          'question': 'q?',
          'options': ['a', 'b'],
          'correctIndex': 5,
          'explanation': 'e',
        }),
        throwsFormatException,
      );
    });
  });

  group('ContentRepository against bundled assets', () {
    final repo = ContentRepository();

    test('loads all four modules with the prerequisite chain', () async {
      final modules = await repo.loadModules();
      expect(modules.map((m) => m.id), ['m1', 'm2', 'm3', 'm4']);
      expect(modules.first.prerequisites, isEmpty);
      expect(modules[1].prerequisites, ['m1']);
      expect(modules.first.lessonIds, ['m1-l1', 'm1-l2']);
    });

    test('loads module 1 lessons and their steps', () async {
      final modules = await repo.loadModules();
      final lessons = await repo.loadLessonsForModule(modules.first);
      expect(lessons.map((l) => l.id), ['m1-l1', 'm1-l2']);
      expect(lessons.first.moduleId, 'm1');
      expect(lessons.first.steps, isNotEmpty);
      expect(lessons.first.steps.first, isA<MultipleChoiceStep>());
      expect(lessons.first.steps.last, isA<WritePromptStep>());
    });
  });
}
