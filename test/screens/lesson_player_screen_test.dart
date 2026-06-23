import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:per_astra/content/content_repository.dart';
import 'package:per_astra/data/providers.dart';
import 'package:per_astra/screens/lesson_player/lesson_player_screen.dart';

/// In-memory asset bundle so the lesson player loads deterministically in tests
/// (no real disk I/O timing to race pumpAndSettle).
class _FixtureBundle extends CachingAssetBundle {
  _FixtureBundle(this._fixtures);
  final Map<String, String> _fixtures;

  @override
  Future<ByteData> load(String key) async => ByteData(0);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _fixtures[key];
    if (value == null) throw FlutterError('No fixture for "$key"');
    return value;
  }
}

const _m1l1 = '''
{
  "id": "m1-l1",
  "moduleId": "m1",
  "title": "Prompt Structure Basics",
  "xpValue": 20,
  "steps": [
    {
      "type": "multiple_choice",
      "question": "Which prompt is more likely to produce a structured, predictable response?",
      "options": ["Tell me about dogs.", "Write three bullet points about dogs, each one sentence long.", "dogs?", "Everything about dogs, please."],
      "correctIndex": 1,
      "explanation": "Being explicit about format and length gives the model a clear target."
    },
    {
      "type": "write_prompt",
      "task": "Write a prompt that asks Claude to summarize a document in exactly three bullet points.",
      "modelAnswer": "Summarize in three bullets.",
      "hints": ["State the exact number."]
    }
  ]
}
''';

void main() {
  final repo = ContentRepository(
    bundle: _FixtureBundle({'assets/content/lessons/m1-l1.json': _m1l1}),
  );

  Future<void> pumpPlayer(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contentRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: LessonPlayerScreen(moduleId: 'm1', lessonId: 'm1-l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const correctOption =
      'Write three bullet points about dogs, each one sentence long.';

  testWidgets('shows the question and disables Continue until answered',
      (tester) async {
    await pumpPlayer(tester);

    expect(
      find.text(
        'Which prompt is more likely to produce a structured, predictable response?',
      ),
      findsOneWidget,
    );

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull); // disabled before answering
  });

  testWidgets('answering correctly reveals feedback and enables Continue',
      (tester) async {
    await pumpPlayer(tester);

    await tester.tap(find.text(correctOption));
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsOneWidget);

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull); // enabled after answering
  });

  testWidgets('Continue advances to the write-a-prompt step', (tester) async {
    await pumpPlayer(tester);

    await tester.tap(find.text(correctOption));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Write a prompt'), findsOneWidget);
    expect(find.text('Finish lesson'), findsOneWidget); // last step
  });
}
