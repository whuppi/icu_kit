// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies non-Gregorian calendar conversions:
//   * 2026-04-28 Gregorian == Reiwa 8, month 4, day 28 in Japanese calendar
//   * Hebrew calendar shows extended year ~5786
//   * Buddhist calendar adds 543 to Gregorian year
//   * Round-trip: Gregorian → Persian → Gregorian preserves the date

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuCalendar — kind getter', () {
    test('reflects construction', () {
      final c = IcuCalendar(IcuCalendarKind.japanese);
      expect(c.kind, IcuCalendarKind.japanese);
    });
  });

  group('IcuCalendarDate — Gregorian baseline', () {
    test('2026-04-28 Gregorian → year/month/day 2026/4/28', () {
      final cal = IcuCalendar(IcuCalendarKind.gregorian);
      final date = IcuCalendarDate.fromGregorian(
        year: 2026,
        month: 4,
        day: 28,
        calendar: cal,
      );
      expect(date.dayOfMonth, 28);
      expect(date.monthNumber, 4);
      expect(date.eraYearOrRelatedIso, 2026);
    });

    test('weekday computed for 2026-04-28 (Tuesday)', () {
      final cal = IcuCalendar(IcuCalendarKind.gregorian);
      final date = IcuCalendarDate.fromGregorian(
        year: 2026,
        month: 4,
        day: 28,
        calendar: cal,
      );
      expect(date.weekday, IcuWeekday.tuesday);
    });
  });

  group('IcuCalendarDate — Japanese (Reiwa era)', () {
    test('2026-04-28 Gregorian renders as Reiwa year 8', () {
      final cal = IcuCalendar(IcuCalendarKind.japanese);
      final date = IcuCalendarDate.fromGregorian(
        year: 2026,
        month: 4,
        day: 28,
        calendar: cal,
      );
      // Reiwa era started May 2019. 2026-04-28 is in Reiwa year 8.
      expect(
        date.era.toLowerCase(),
        contains('reiwa'),
        reason: 'expected Reiwa era, got: ${date.era}',
      );
      expect(date.eraYearOrRelatedIso, 8);
      expect(date.monthNumber, 4);
      expect(date.dayOfMonth, 28);
    });
  });

  group('IcuCalendarDate — Buddhist (year + 543)', () {
    test('2026-04-28 Gregorian → BE year 2569', () {
      final cal = IcuCalendar(IcuCalendarKind.buddhist);
      final date = IcuCalendarDate.fromGregorian(
        year: 2026,
        month: 4,
        day: 28,
        calendar: cal,
      );
      // Buddhist Era = Gregorian + 543. 2026 → 2569.
      expect(date.eraYearOrRelatedIso, 2569);
    });
  });

  group('IcuCalendarDate — Hebrew', () {
    test('2026-04-28 Gregorian falls in Hebrew year ~5786', () {
      final cal = IcuCalendar(IcuCalendarKind.hebrew);
      final date = IcuCalendarDate.fromGregorian(
        year: 2026,
        month: 4,
        day: 28,
        calendar: cal,
      );
      // Hebrew year transitions in autumn. April 2026 is between Tishri
      // 5786 (autumn 2025) and Tishri 5787 (autumn 2026), so it's 5786.
      expect(date.extendedYear, 5786);
    });
  });

  group('IcuCalendarDate — round-trip preservation', () {
    test('Persian round-trip preserves Gregorian date', () {
      final persian = IcuCalendar(IcuCalendarKind.persian);
      final date = IcuCalendarDate.fromGregorian(
        year: 2026,
        month: 4,
        day: 28,
        calendar: persian,
      );
      final back = date.toGregorian();
      expect(back.year, 2026);
      expect(back.month, 4);
      expect(back.day, 28);
    });

    test('Hebrew round-trip preserves Gregorian date', () {
      final hebrew = IcuCalendar(IcuCalendarKind.hebrew);
      final date = IcuCalendarDate.fromGregorian(
        year: 2024,
        month: 2,
        day: 29, // leap day
        calendar: hebrew,
      );
      final back = date.toGregorian();
      expect(back.year, 2024);
      expect(back.month, 2);
      expect(back.day, 29);
    });
  });

  group('IcuCalendarDate — leap year detection', () {
    test('2024 is a Gregorian leap year', () {
      final cal = IcuCalendar(IcuCalendarKind.gregorian);
      final date = IcuCalendarDate.fromGregorian(
        year: 2024,
        month: 6,
        day: 15,
        calendar: cal,
      );
      expect(date.isInLeapYear, isTrue);
      expect(date.daysInYear, 366);
    });

    test('2026 is not a Gregorian leap year', () {
      final cal = IcuCalendar(IcuCalendarKind.gregorian);
      final date = IcuCalendarDate.fromGregorian(
        year: 2026,
        month: 6,
        day: 15,
        calendar: cal,
      );
      expect(date.isInLeapYear, isFalse);
      expect(date.daysInYear, 365);
    });
  });

  group('IcuCalendarDate — fromDartDateTime convenience', () {
    test('Dart DateTime converts directly', () {
      final cal = IcuCalendar(IcuCalendarKind.japanese);
      final dt = DateTime(2026, 4, 28);
      final date = IcuCalendarDate.fromDartDateTime(dt, calendar: cal);
      expect(date.eraYearOrRelatedIso, 8);
    });
  });
}
