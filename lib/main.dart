import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PerAstraApp()));
}

/// Root of the Per Astra app: Riverpod scope + go_router + the dark theme.
class PerAstraApp extends StatelessWidget {
  const PerAstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Per Astra',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
