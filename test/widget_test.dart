// Smoke test: the app boots to the skill tree and renders the seed modules.

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:per_astra/data/database.dart';
import 'package:per_astra/data/providers.dart';
import 'package:per_astra/main.dart';

void main() {
  testWidgets('boots to the skill tree and lists modules', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const PerAstraApp(),
      ),
    );
    // pumpAndSettle is unusable here: the level-progress bar runs a repeating
    // animation controller, so the tree never "settles". The skill tree also
    // waits on drift's stream, which emits via real async I/O that fake-time
    // pumps don't advance. So alternate runAsync (lets the real I/O progress)
    // with pump (rebuilds), polling until the seed content renders.
    for (var i = 0; i < 50; i++) {
      if (find.text('Prompt Fundamentals').evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(find.text('Per Astra'), findsOneWidget);
    expect(find.text('Prompt Fundamentals'), findsOneWidget);
    expect(find.text('Role Prompting + Few-Shot'), findsOneWidget);

    // Unmount so the ProviderScope disposes the drift stream providers, then
    // flush the zero-duration cleanup timer drift schedules on close —
    // otherwise the framework flags a pending timer after teardown.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
