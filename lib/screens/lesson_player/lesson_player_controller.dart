/// Ephemeral state for playing through a lesson's steps (ADR-004, ADR-007).
///
/// The lesson player's internal step flow is driven by this Riverpod notifier,
/// not by the router. State lives only while a lesson is open. Persisting XP and
/// completion (ProgressNotifier, ADR-007) is handled separately.
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../content/models.dart';
import '../../data/providers.dart';
import '../../gamification/xp.dart';

part 'lesson_player_controller.g.dart';

/// Snapshot of progress through a single lesson.
@immutable
class LessonPlayerState {
  const LessonPlayerState({
    required this.lesson,
    required this.stepIndex,
    required this.revealed,
    required this.selectedOptionIndex,
    required this.correctCount,
    required this.allFirstTryCorrect,
  });

  factory LessonPlayerState.initial(Lesson lesson) => LessonPlayerState(
        lesson: lesson,
        stepIndex: 0,
        revealed: false,
        selectedOptionIndex: null,
        correctCount: 0,
        allFirstTryCorrect: true,
      );

  final Lesson lesson;

  /// Index of the step currently shown.
  final int stepIndex;

  /// Whether the current step's feedback (correct answer / explanation) is shown.
  final bool revealed;

  /// The option the learner tapped on the current multiple-choice step.
  final int? selectedOptionIndex;

  /// Number of multiple-choice questions answered correctly.
  final int correctCount;

  /// True while every multiple-choice answer so far was correct on first tap.
  /// Drives [xpFirstTryBonus] (ADR-007).
  final bool allFirstTryCorrect;

  LessonStep get currentStep => lesson.steps[stepIndex];
  int get totalSteps => lesson.steps.length;
  bool get isLastStep => stepIndex >= lesson.steps.length - 1;

  int get multipleChoiceCount =>
      lesson.steps.whereType<MultipleChoiceStep>().length;

  /// Session XP preview: the lesson base plus a first-try bonus when all
  /// multiple-choice answers were correct on first tap. Day/module bonuses are
  /// applied by the progress notifier, not previewed here.
  int get xpPreview =>
      lesson.xpValue +
      (allFirstTryCorrect && multipleChoiceCount > 0 ? xpFirstTryBonus : 0);

  LessonPlayerState copyWith({
    int? stepIndex,
    bool? revealed,
    int? selectedOptionIndex,
    bool clearSelection = false,
    int? correctCount,
    bool? allFirstTryCorrect,
  }) {
    return LessonPlayerState(
      lesson: lesson,
      stepIndex: stepIndex ?? this.stepIndex,
      revealed: revealed ?? this.revealed,
      selectedOptionIndex:
          clearSelection ? null : (selectedOptionIndex ?? this.selectedOptionIndex),
      correctCount: correctCount ?? this.correctCount,
      allFirstTryCorrect: allFirstTryCorrect ?? this.allFirstTryCorrect,
    );
  }
}

@riverpod
class LessonPlayerController extends _$LessonPlayerController {
  @override
  Future<LessonPlayerState> build(String lessonId) async {
    final repo = ref.watch(contentRepositoryProvider);
    final lesson = await repo.loadLesson(lessonId);
    return LessonPlayerState.initial(lesson);
  }

  /// Records the learner's choice on the current multiple-choice step and
  /// reveals feedback. No-op if already revealed or not on an MC step.
  void selectOption(int index) {
    final current = state.asData?.value;
    if (current == null || current.revealed) return;
    final step = current.currentStep;
    if (step is! MultipleChoiceStep) return;

    final correct = index == step.correctIndex;
    state = AsyncData(
      current.copyWith(
        selectedOptionIndex: index,
        revealed: true,
        correctCount: current.correctCount + (correct ? 1 : 0),
        allFirstTryCorrect: current.allFirstTryCorrect && correct,
      ),
    );
  }

  /// Advances to the next step. Returns true when the lesson is finished
  /// (no further steps).
  bool advance() {
    final current = state.asData?.value;
    if (current == null) return false;
    if (current.isLastStep) return true;
    state = AsyncData(
      current.copyWith(
        stepIndex: current.stepIndex + 1,
        revealed: false,
        clearSelection: true,
      ),
    );
    return false;
  }
}
