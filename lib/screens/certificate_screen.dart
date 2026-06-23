import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

/// Track certificate screen (PRD section 7, ADR-008). Placeholder: client-side
/// PNG generation, cert_id, and the LinkedIn "Add to Profile" deep link are
/// built in feature work.
class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Per Astra Certificate')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.military_tech_outlined, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Certificate generation coming soon.',
                textAlign: TextAlign.center,
              ),
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
