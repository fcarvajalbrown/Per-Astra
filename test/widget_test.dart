// Smoke test: the app boots to the skill tree and renders the seed modules.

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:per_astra/main.dart';

void main() {
  testWidgets('boots to the skill tree and lists modules', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PerAstraApp()));
    await tester.pumpAndSettle();

    expect(find.text('Per Astra'), findsOneWidget);
    expect(find.text('Prompt Fundamentals'), findsOneWidget);
    expect(find.text('Role Prompting + Few-Shot'), findsOneWidget);
  });
}
