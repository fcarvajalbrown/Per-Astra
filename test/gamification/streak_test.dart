import 'package:flutter_test/flutter_test.dart';
import 'package:per_astra/gamification/streak.dart';

void main() {
  DateTime day(int y, int m, int d) => DateTime(y, m, d, 10, 30);

  group('isoDate / dayGap', () {
    test('isoDate zero-pads month and day', () {
      expect(isoDate(DateTime(2026, 6, 9)), '2026-06-09');
    });

    test('dayGap counts whole local calendar days', () {
      expect(dayGap('2026-06-20', day(2026, 6, 20)), 0);
      expect(dayGap('2026-06-20', day(2026, 6, 21)), 1);
      expect(dayGap('2026-06-20', day(2026, 6, 23)), 3);
    });
  });

  group('advanceStreak', () {
    test('first lesson ever starts the streak at 1', () {
      final s = advanceStreak(const StreakState.empty(), day(2026, 6, 23));
      expect(s.currentStreak, 1);
      expect(s.longestStreak, 1);
      expect(s.lastActiveDate, '2026-06-23');
    });

    test('same-day completion is a no-op', () {
      const before = StreakState(
        currentStreak: 3,
        longestStreak: 5,
        lastActiveDate: '2026-06-23',
        freezeCount: 0,
      );
      final after = advanceStreak(before, day(2026, 6, 23));
      expect(after.currentStreak, 3);
      expect(after.lastActiveDate, '2026-06-23');
    });

    test('next-day completion extends the streak', () {
      const before = StreakState(
        currentStreak: 3,
        longestStreak: 3,
        lastActiveDate: '2026-06-22',
        freezeCount: 0,
      );
      final after = advanceStreak(before, day(2026, 6, 23));
      expect(after.currentStreak, 4);
      expect(after.longestStreak, 4);
      expect(after.lastActiveDate, '2026-06-23');
    });

    test('a one-day gap is rescued by one freeze', () {
      // last active 2026-06-20, now 2026-06-22 => gap 2, missedDays 1.
      const before = StreakState(
        currentStreak: 6,
        longestStreak: 6,
        lastActiveDate: '2026-06-20',
        freezeCount: 2,
      );
      final after = advanceStreak(before, day(2026, 6, 22));
      expect(after.currentStreak, 7);
      expect(after.freezeCount, 1); // one freeze spent
    });

    test('a multi-day gap spends one freeze per missed day', () {
      // gap 3 => missedDays 2, needs 2 freezes.
      const before = StreakState(
        currentStreak: 4,
        longestStreak: 4,
        lastActiveDate: '2026-06-20',
        freezeCount: 2,
      );
      final after = advanceStreak(before, day(2026, 6, 23));
      expect(after.currentStreak, 5);
      expect(after.freezeCount, 0);
    });

    test('not enough freezes resets the streak and keeps longest', () {
      const before = StreakState(
        currentStreak: 9,
        longestStreak: 9,
        lastActiveDate: '2026-06-20',
        freezeCount: 1, // need 2
      );
      final after = advanceStreak(before, day(2026, 6, 23));
      expect(after.currentStreak, 1);
      expect(after.freezeCount, 0);
      expect(after.longestStreak, 9);
    });
  });
}
