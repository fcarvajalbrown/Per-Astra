import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

/// Settings: notification time and profile (ADR-004, ADR-009). Placeholder
/// until preferences are wired to user_profile (ADR-006).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoutes.skillTree)),
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Settings coming soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
