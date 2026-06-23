import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

/// Plays a lesson's steps (multiple-choice then write-a-prompt).
///
/// Placeholder: the real step flow, scoring, and self-evaluation (ADR-005,
/// ADR-007) are built in feature work. Internal step state will be Riverpod, not
/// router state (ADR-004).
class LessonPlayerScreen extends StatelessWidget {
  const LessonPlayerScreen({
    required this.moduleId,
    required this.lessonId,
    super.key,
  });

  final String moduleId;
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.goNamed(
            AppRoutes.module,
            pathParameters: {'moduleId': moduleId},
          ),
        ),
        title: Text(lessonId),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Lesson player coming soon.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.goNamed(AppRoutes.lessonComplete),
                child: const Text('Complete lesson'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
