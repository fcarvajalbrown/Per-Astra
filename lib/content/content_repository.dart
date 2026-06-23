/// Loads bundled module and lesson JSON from app assets (ADR-005).
library;

import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'models.dart';

/// Reads content from the asset bundle. The [bundle] is injectable so tests can
/// supply fixtures without the real `rootBundle`.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _modulesPath = 'assets/content/modules.json';
  static String _lessonPath(String lessonId) =>
      'assets/content/lessons/$lessonId.json';

  /// Loads all modules in their declared order from `modules.json`.
  Future<List<Module>> loadModules() async {
    final raw = await _bundle.loadString(_modulesPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final modules = (decoded['modules'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return modules.map(Module.fromJson).toList(growable: false);
  }

  /// Loads a single lesson by id (e.g. `m1-l1`).
  Future<Lesson> loadLesson(String lessonId) async {
    final raw = await _bundle.loadString(_lessonPath(lessonId));
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return Lesson.fromJson(decoded);
  }

  /// Loads every lesson belonging to [module], in its declared order.
  Future<List<Lesson>> loadLessonsForModule(Module module) async {
    final lessons = <Lesson>[];
    for (final id in module.lessonIds) {
      lessons.add(await loadLesson(id));
    }
    return lessons;
  }
}
