import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../content/content_providers.dart';
import '../data/providers.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

/// Lists the lessons within a module (ADR-004), with real titles and a
/// completion checkmark derived from the live progress set.
class ModuleDetailScreen extends ConsumerWidget {
  const ModuleDetailScreen({required this.moduleId, super.key});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(moduleLessonsProvider(moduleId));
    final completed =
        ref.watch(completedLessonIdsProvider).asData?.value ?? const <String>{};

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoutes.skillTree)),
        title: Text(moduleId.toUpperCase()),
      ),
      body: lessons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load module: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Lessons for this module are coming soon.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final lesson = items[i];
              final done = completed.contains(lesson.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: done
                      ? const Icon(Icons.check_circle,
                          color: AppColors.success)
                      : CircleAvatar(child: Text('${i + 1}')),
                  title: Text(lesson.title),
                  subtitle: Text('${lesson.steps.length} steps'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.goNamed(
                    AppRoutes.lesson,
                    pathParameters: {
                      'moduleId': moduleId,
                      'lessonId': lesson.id,
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
