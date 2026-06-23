import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

/// Shown after a lesson: XP earned, streak update, and a continue action
/// (PRD section 7). Placeholder until gamification is wired (ADR-007).
class LessonCompleteScreen extends StatelessWidget {
  const LessonCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 72),
              const SizedBox(height: 16),
              const Text('Lesson complete!', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(AppRoutes.skillTree),
                child: const Text('Back to skill tree'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
