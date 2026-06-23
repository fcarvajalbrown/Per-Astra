import 'package:flutter_test/flutter_test.dart';
import 'package:per_astra/gamification/xp.dart';

void main() {
  group('levelForXp', () {
    test('zero and negative XP is level 1', () {
      expect(levelForXp(0), 1);
      expect(levelForXp(-50), 1);
    });

    test('XP just below a threshold stays on the lower level', () {
      expect(levelForXp(99), 1);
      expect(levelForXp(249), 2);
    });

    test('XP exactly on a threshold advances the level', () {
      expect(levelForXp(100), 2);
      expect(levelForXp(250), 3);
      expect(levelForXp(4500), 10);
    });

    test('XP above the top threshold caps at the max level', () {
      expect(levelForXp(10000), 10);
    });

    test('every threshold maps to its own level', () {
      for (var i = 0; i < levelThresholds.length; i++) {
        expect(levelForXp(levelThresholds[i]), i + 1);
      }
    });
  });

  test('level thresholds are strictly increasing and start at 0', () {
    expect(levelThresholds.first, 0);
    for (var i = 1; i < levelThresholds.length; i++) {
      expect(levelThresholds[i], greaterThan(levelThresholds[i - 1]));
    }
  });
}
