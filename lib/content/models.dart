/// Content models for modules and lessons (ADR-005).
///
/// These mirror the JSON schema bundled under `assets/content/`. Parsing is
/// hand-written (no codegen) so the shape stays obvious to content contributors
/// reading the JSON in the repo.
library;

import 'package:flutter/foundation.dart';

/// A skill-tree module: a group of ordered lessons gated by prerequisites.
///
/// Schema note (extends ADR-005's "id, title, description, prerequisites"):
/// modules also carry an ordered [lessonIds] list. Bundled assets cannot be
/// reliably directory-listed at runtime, so membership and ordering are declared
/// explicitly here rather than inferred from filenames.
@immutable
class Module {
  const Module({
    required this.id,
    required this.title,
    required this.description,
    required this.prerequisites,
    required this.lessonIds,
  });

  final String id;
  final String title;
  final String description;

  /// Module ids that must be fully completed before this module unlocks.
  final List<String> prerequisites;

  /// Ordered lesson ids belonging to this module.
  final List<String> lessonIds;

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      prerequisites:
          (json['prerequisites'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
      lessonIds: (json['lessonIds'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
    );
  }
}

/// A single lesson: an ordered list of [LessonStep]s and the XP it awards.
@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.xpValue,
    required this.steps,
  });

  final String id;
  final String moduleId;
  final String title;
  final int xpValue;
  final List<LessonStep> steps;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawSteps = (json['steps'] as List<dynamic>).cast<Map<String, dynamic>>();
    return Lesson(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      title: json['title'] as String,
      xpValue: json['xpValue'] as int,
      steps: rawSteps.map(LessonStep.fromJson).toList(growable: false),
    );
  }
}

/// Base type for a step within a lesson. Sealed so the lesson player can switch
/// exhaustively over the known step kinds.
@immutable
sealed class LessonStep {
  const LessonStep();

  /// Dispatches on the `type` discriminator from the JSON.
  factory LessonStep.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'multiple_choice' => MultipleChoiceStep.fromJson(json),
      'write_prompt' => WritePromptStep.fromJson(json),
      _ => throw FormatException('Unknown lesson step type: $type'),
    };
  }
}

/// A multiple-choice question with immediate feedback (PRD "learn" part).
@immutable
class MultipleChoiceStep extends LessonStep {
  const MultipleChoiceStep({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory MultipleChoiceStep.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>).cast<String>();
    final correctIndex = json['correctIndex'] as int;
    if (correctIndex < 0 || correctIndex >= options.length) {
      throw FormatException(
        'correctIndex $correctIndex out of range for ${options.length} options',
      );
    }
    return MultipleChoiceStep(
      question: json['question'] as String,
      options: options,
      correctIndex: correctIndex,
      explanation: json['explanation'] as String,
    );
  }
}

/// A prompt-writing challenge self-evaluated against a vetted model answer
/// (PRD "apply" part; no live grader in v1, ADR-002).
@immutable
class WritePromptStep extends LessonStep {
  const WritePromptStep({
    required this.task,
    required this.modelAnswer,
    required this.hints,
  });

  final String task;
  final String modelAnswer;
  final List<String> hints;

  factory WritePromptStep.fromJson(Map<String, dynamic> json) {
    return WritePromptStep(
      task: json['task'] as String,
      modelAnswer: json['modelAnswer'] as String,
      hints: (json['hints'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
    );
  }
}
