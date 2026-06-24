import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../content/content_providers.dart';
import '../data/providers.dart';
import '../gamification/xp.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

/// Home screen: the full skill tree of modules (ADR-004, PRD section 7).
///
/// Lock and progress state are derived from the live completed-lesson set via
/// [moduleStatusesProvider] (the SkillTreeNotifier role in ADR-007): a module
/// unlocks once all its prerequisite modules are fully complete.
class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(moduleStatusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Per Astra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: statuses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Failed to load content: $e')),
        data: (modules) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _XpHeader(),
            const SizedBox(height: 16),
            for (final status in modules)
              _ModuleCard(status: status),
          ],
        ),
      ),
    );
  }
}

/// Shows the learner's level and total XP from the live profile row.
class _XpHeader extends ConsumerWidget {
  const _XpHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final xp = profile?.totalXp ?? 0;
    final level = profile?.level ?? 1;

    final lowerThreshold = levelThresholds[level - 1];
    final hasNext = level < levelThresholds.length;
    final nextThreshold = hasNext ? levelThresholds[level] : lowerThreshold;
    final span = nextThreshold - lowerThreshold;
    final progress = (hasNext && span > 0)
        ? ((xp - lowerThreshold) / span).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level $level',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text('$xp XP'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppRadii.defaultRadius)),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.secondary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasNext
                  ? '${nextThreshold - xp} XP to level ${level + 1}'
                  : 'Max level reached',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.status});

  final ModuleStatus status;

  @override
  Widget build(BuildContext context) {
    final module = status.module;
    final locked = status.locked;

    final (icon, iconColor) = switch (status) {
      _ when locked => (Icons.lock_outline, Colors.grey),
      _ when status.isComplete => (Icons.check_circle, AppColors.success),
      _ => (Icons.auto_awesome, AppColors.secondary),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(module.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(module.description),
            if (status.totalLessons > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${status.completedLessons}/${status.totalLessons} lessons',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        isThreeLine: status.totalLessons > 0,
        trailing: locked ? null : const Icon(Icons.chevron_right),
        enabled: !locked,
        onTap: locked
            ? null
            : () => context.goNamed(
                  AppRoutes.module,
                  pathParameters: {'moduleId': module.id},
                ),
      ),
    );
  }
}
