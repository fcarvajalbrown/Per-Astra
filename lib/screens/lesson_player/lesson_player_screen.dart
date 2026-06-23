import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../content/models.dart';
import '../../routing/app_router.dart';
import 'lesson_player_controller.dart';
import 'multiple_choice_view.dart';

/// Plays a lesson's steps in order: multiple-choice questions with immediate
/// feedback, then write-a-prompt (placeholder for now). Internal step state is
/// Riverpod, not router state (ADR-004).
class LessonPlayerScreen extends ConsumerWidget {
  const LessonPlayerScreen({
    required this.moduleId,
    required this.lessonId,
    super.key,
  });

  final String moduleId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(lessonPlayerControllerProvider(lessonId));
    final controller =
        ref.read(lessonPlayerControllerProvider(lessonId).notifier);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.goNamed(
            AppRoutes.module,
            pathParameters: {'moduleId': moduleId},
          ),
        ),
        title: asyncState.maybeWhen(
          data: (s) => Text(s.lesson.title),
          orElse: () => Text(lessonId),
        ),
        bottom: asyncState.maybeWhen(
          data: (s) => PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (s.stepIndex + 1) / s.totalSteps,
            ),
          ),
          orElse: () => null,
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load lesson: $e')),
        data: (state) => _StepBody(
          state: state,
          onSelect: controller.selectOption,
        ),
      ),
      bottomNavigationBar: asyncState.maybeWhen(
        data: (state) => _ContinueBar(
          enabled: _canContinue(state),
          isLast: state.isLastStep,
          onContinue: () {
            final finished = controller.advance();
            if (finished) context.goNamed(AppRoutes.lessonComplete);
          },
        ),
        orElse: () => null,
      ),
    );
  }

  /// Multiple-choice requires an answer before continuing; other steps don't.
  bool _canContinue(LessonPlayerState state) =>
      state.currentStep is! MultipleChoiceStep || state.revealed;
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.state, required this.onSelect});

  final LessonPlayerState state;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep;
    return switch (step) {
      MultipleChoiceStep() => MultipleChoiceView(
          step: step,
          revealed: state.revealed,
          selectedIndex: state.selectedOptionIndex,
          onSelect: onSelect,
        ),
      WritePromptStep() => _WritePromptPlaceholder(step: step),
    };
  }
}

/// Temporary view for write-a-prompt steps. The text input, model-answer
/// reveal, and self-evaluation (ADR-005) arrive in the next slice.
class _WritePromptPlaceholder extends StatelessWidget {
  const _WritePromptPlaceholder({required this.step});

  final WritePromptStep step;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Write a prompt', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(step.task),
        const SizedBox(height: 24),
        const Text(
          'The write-a-prompt input and self-evaluation are coming soon. '
          'Continue to finish the lesson.',
        ),
      ],
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.enabled,
    required this.isLast,
    required this.onContinue,
  });

  final bool enabled;
  final bool isLast;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? onContinue : null,
            child: Text(isLast ? 'Finish lesson' : 'Continue'),
          ),
        ),
      ),
    );
  }
}
