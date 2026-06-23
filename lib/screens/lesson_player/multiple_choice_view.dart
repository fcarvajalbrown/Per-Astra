import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../theme/app_theme.dart';

/// Renders a multiple-choice question with immediate feedback (ADR-010 colors).
///
/// Before [revealed]: tappable options. After a tap: the correct option turns
/// green, a wrong selection turns red, and the explanation is shown.
class MultipleChoiceView extends StatelessWidget {
  const MultipleChoiceView({
    required this.step,
    required this.revealed,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final MultipleChoiceStep step;
  final bool revealed;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(step.question, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        for (var i = 0; i < step.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionTile(
              label: step.options[i],
              state: _stateFor(i),
              onTap: revealed ? null : () => onSelect(i),
            ),
          ),
        if (revealed) ...[
          const SizedBox(height: 8),
          _ExplanationBox(
            correct: selectedIndex == step.correctIndex,
            explanation: step.explanation,
          ),
        ],
      ],
    );
  }

  _OptionState _stateFor(int i) {
    if (!revealed) return _OptionState.idle;
    if (i == step.correctIndex) return _OptionState.correct;
    if (i == selectedIndex) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (border, icon) = switch (state) {
      _OptionState.idle => (AppColors.primary, null),
      _OptionState.correct => (AppColors.success, Icons.check_circle),
      _OptionState.wrong => (AppColors.error, Icons.cancel),
      _OptionState.dimmed => (Colors.white24, null),
    };

    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.5 : 1,
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadii.defaultRadius),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadii.defaultRadius),
          ),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadii.defaultRadius),
              ),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  const _ExplanationBox({required this.correct, required this.explanation});

  final bool correct;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadii.defaultRadius),
        ),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? 'Correct' : 'Not quite',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(explanation),
        ],
      ),
    );
  }
}
