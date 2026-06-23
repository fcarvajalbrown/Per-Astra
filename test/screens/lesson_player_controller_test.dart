import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:per_astra/content/models.dart';
import 'package:per_astra/screens/lesson_player/lesson_player_controller.dart';

void main() {
  // Lets the ContentRepository read the bundled seed lesson asset.
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  LessonPlayerController controllerFor(String id) =>
      container.read(lessonPlayerControllerProvider(id).notifier);
  LessonPlayerState stateFor(String id) =>
      container.read(lessonPlayerControllerProvider(id)).requireValue;

  test('loads the lesson and starts on the first step', () async {
    final state = await container
        .read(lessonPlayerControllerProvider('m1-l1').future);
    expect(state.stepIndex, 0);
    expect(state.currentStep, isA<MultipleChoiceStep>());
    expect(state.allFirstTryCorrect, isTrue);
  });

  test('a correct first answer keeps the first-try bonus and reveals feedback',
      () async {
    await container.read(lessonPlayerControllerProvider('m1-l1').future);
    final step = stateFor('m1-l1').currentStep as MultipleChoiceStep;

    controllerFor('m1-l1').selectOption(step.correctIndex);

    final s = stateFor('m1-l1');
    expect(s.revealed, isTrue);
    expect(s.correctCount, 1);
    expect(s.allFirstTryCorrect, isTrue);
    expect(s.xpPreview, greaterThan(s.lesson.xpValue)); // bonus included
  });

  test('a wrong answer clears the first-try bonus', () async {
    await container.read(lessonPlayerControllerProvider('m1-l1').future);
    final step = stateFor('m1-l1').currentStep as MultipleChoiceStep;
    final wrong = (step.correctIndex + 1) % step.options.length;

    controllerFor('m1-l1').selectOption(wrong);

    final s = stateFor('m1-l1');
    expect(s.revealed, isTrue);
    expect(s.correctCount, 0);
    expect(s.allFirstTryCorrect, isFalse);
    expect(s.xpPreview, s.lesson.xpValue); // no bonus
  });

  test('selecting again after reveal is a no-op', () async {
    await container.read(lessonPlayerControllerProvider('m1-l1').future);
    final step = stateFor('m1-l1').currentStep as MultipleChoiceStep;

    controllerFor('m1-l1').selectOption(step.correctIndex);
    controllerFor('m1-l1').selectOption(
      (step.correctIndex + 1) % step.options.length,
    );

    expect(stateFor('m1-l1').selectedOptionIndex, step.correctIndex);
    expect(stateFor('m1-l1').correctCount, 1);
  });

  test('advance walks steps and reports completion on the last step', () async {
    final initial = await container
        .read(lessonPlayerControllerProvider('m1-l1').future);
    expect(initial.totalSteps, 2);

    final finishedAtStep0 = controllerFor('m1-l1').advance();
    expect(finishedAtStep0, isFalse);
    expect(stateFor('m1-l1').stepIndex, 1);
    expect(stateFor('m1-l1').revealed, isFalse);
    expect(stateFor('m1-l1').selectedOptionIndex, isNull);

    final finishedAtStep1 = controllerFor('m1-l1').advance();
    expect(finishedAtStep1, isTrue);
  });
}
