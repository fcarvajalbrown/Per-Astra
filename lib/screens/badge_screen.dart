import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

/// Badge unlock screen (PRD section 7, ADR-008). Placeholder: the generated
/// shareable badge image and LinkedIn share flow are built in feature work.
class BadgeScreen extends StatelessWidget {
  const BadgeScreen({required this.badgeId, super.key});

  final String badgeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badge unlocked')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium_outlined, size: 72),
              const SizedBox(height: 16),
              Text(badgeId, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(AppRoutes.skillTree),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
