/// Providers that join bundled content with completion progress (ADR-007).
///
/// The skill tree's locked/unlocked state and per-module progress are *derived*
/// here from the live completed-lesson set rather than stored — this is the
/// SkillTreeNotifier responsibility from ADR-007.
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/providers.dart';
import 'models.dart';

part 'content_providers.g.dart';

/// A module plus its derived lock and completion state for the skill tree.
@immutable
class ModuleStatus {
  const ModuleStatus({
    required this.module,
    required this.locked,
    required this.completedLessons,
    required this.totalLessons,
  });

  final Module module;

  /// True when at least one prerequisite module is not yet fully complete.
  final bool locked;

  final int completedLessons;
  final int totalLessons;

  /// True only when the module has lessons and all of them are complete.
  bool get isComplete => totalLessons > 0 && completedLessons == totalLessons;
}

/// All modules with their derived lock/progress state, recomputed whenever the
/// completed-lesson set changes.
@riverpod
Future<List<ModuleStatus>> moduleStatuses(Ref ref) async {
  final content = ref.watch(contentRepositoryProvider);
  final modules = await content.loadModules();
  final completed = await ref.watch(completedLessonIdsProvider.future);

  bool moduleComplete(Module m) =>
      m.lessonIds.isNotEmpty && m.lessonIds.every(completed.contains);

  final byId = {for (final m in modules) m.id: m};

  return [
    for (final m in modules)
      ModuleStatus(
        module: m,
        locked: m.prerequisites.any((p) {
          final prereq = byId[p];
          return prereq == null || !moduleComplete(prereq);
        }),
        completedLessons: m.lessonIds.where(completed.contains).length,
        totalLessons: m.lessonIds.length,
      ),
  ];
}

/// The lessons of [moduleId] in declared order. Used by the module detail
/// screen to show real titles instead of raw ids.
@riverpod
Future<List<Lesson>> moduleLessons(Ref ref, String moduleId) async {
  final content = ref.watch(contentRepositoryProvider);
  final modules = await content.loadModules();
  final module = modules.firstWhere(
    (m) => m.id == moduleId,
    orElse: () => throw StateError('Unknown module: $moduleId'),
  );
  return content.loadLessonsForModule(module);
}
