import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../content/models.dart';
import '../data/providers.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

/// Home screen: the full skill tree of modules (ADR-004, PRD section 7).
///
/// Lock state here is a placeholder (a module is treated as locked when it has
/// unmet prerequisites). The real derivation from completed lessons lives in the
/// SkillTreeNotifier (ADR-007) and will replace this in feature work.
class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(contentRepositoryProvider);

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
      body: FutureBuilder<List<Module>>(
        future: repo.loadModules(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load content: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final modules = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: modules.length,
            itemBuilder: (context, i) {
              final module = modules[i];
              final locked = module.prerequisites.isNotEmpty;
              return _ModuleCard(module: module, locked: locked);
            },
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.locked});

  final Module module;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          locked ? Icons.lock_outline : Icons.auto_awesome,
          color: locked ? Colors.grey : AppColors.secondary,
        ),
        title: Text(module.title),
        subtitle: Text(module.description),
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
