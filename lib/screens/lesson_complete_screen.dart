import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../gamification/lesson_completion.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

/// Shown after a lesson: XP earned (with breakdown), streak update, level-ups,
/// and any badges unlocked (PRD section 7, ADR-007). Reads the last completion
/// result recorded by [LessonCompletion].
class LessonCompleteScreen extends ConsumerWidget {
  const LessonCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(lessonCompletionProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                const Text('Lesson complete!', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 24),
                if (result != null) _Summary(result: result),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.goNamed(AppRoutes.skillTree),
                  child: const Text('Back to skill tree'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.result});

  final LessonCompletionResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '+${result.xpEarned} XP',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        _XpBreakdown(result: result),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _Chip(
              icon: Icons.local_fire_department,
              label: '${result.currentStreak}-day streak',
              highlight: result.streakIncreased,
              color: AppColors.error,
            ),
            if (result.leveledUp)
              _Chip(
                icon: Icons.trending_up,
                label: 'Level ${result.levelAfter}',
                highlight: true,
                color: AppColors.primary,
              ),
            if (result.freezesAwarded > 0)
              _Chip(
                icon: Icons.ac_unit,
                label: '+${result.freezesAwarded} freeze'
                    '${result.freezesAwarded > 1 ? 's' : ''}',
                highlight: true,
                color: AppColors.primary,
              ),
          ],
        ),
        if (result.badgesEarned.isNotEmpty) ...[
          const SizedBox(height: 20),
          for (final badge in result.badgesEarned)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Chip(
                icon: Icons.workspace_premium,
                label: _badgeLabel(badge),
                highlight: true,
                color: AppColors.secondary,
              ),
            ),
        ],
      ],
    );
  }

  static String _badgeLabel(String badgeId) {
    if (badgeId == 'track_developer_v1_complete') {
      return 'Developer Track complete!';
    }
    return 'Module badge unlocked';
  }
}

class _XpBreakdown extends StatelessWidget {
  const _XpBreakdown({required this.result});

  final LessonCompletionResult result;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int)>[
      ('Lesson', result.lessonXp),
      ('First try', result.firstTryBonus),
      ('Daily bonus', result.dailyBonus),
      ('Module bonus', result.moduleBonus),
    ].where((r) => r.$2 > 0).toList();

    if (rows.isEmpty) {
      return Text(
        'No new XP — you have already completed this lesson today.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: [
        for (final (label, xp) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                Text(
                  '+$xp',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.highlight,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool highlight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.16) : AppColors.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadii.defaultRadius),
        ),
        border: Border.all(
          color: highlight ? color : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: highlight ? color : Colors.white54),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
