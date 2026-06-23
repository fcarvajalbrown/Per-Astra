import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../content/models.dart';
import '../data/providers.dart';
import '../routing/app_router.dart';

/// Lists the lessons within a module (ADR-004). Placeholder list; completion
/// state and XP will be layered on in feature work.
class ModuleDetailScreen extends ConsumerWidget {
  const ModuleDetailScreen({required this.moduleId, super.key});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(contentRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoutes.skillTree)),
        title: Text(moduleId.toUpperCase()),
      ),
      body: FutureBuilder<List<Module>>(
        future: repo.loadModules(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final module =
              snapshot.data!.where((m) => m.id == moduleId).firstOrNull;
          if (module == null) {
            return Center(child: Text('Unknown module: $moduleId'));
          }
          if (module.lessonIds.isEmpty) {
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
            itemCount: module.lessonIds.length,
            itemBuilder: (context, i) {
              final lessonId = module.lessonIds[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(lessonId),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.goNamed(
                    AppRoutes.lesson,
                    pathParameters: {'moduleId': moduleId, 'lessonId': lessonId},
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
