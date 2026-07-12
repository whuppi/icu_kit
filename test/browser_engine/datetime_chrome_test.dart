// §3e dates / times / zones on the browser engine. en-US output is stable
// enough to assert substrings. Non-ISO calendars are a documented gap and
// surface as IcuUnsupportedError.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  final jan15 = DateTime.utc(2024, 1, 15, 13, 45, 30);

  group('IcuDateFormat', () {
    test('ymd medium → Jan 15, 2024', () {
      final out = IcuDateFormat.ymd(locale: 'en-US').format(jan15);
      expect(out, contains('Jan'));
      expect(out, contains('15'));
      expect(out, contains('2024'));
    });
    test('ymd long spells the month', () {
      final out = IcuDateFormat.ymd(
        locale: 'en-US',
        length: IcuDateLength.long,
      ).format(jan15);
      expect(out, contains('January'));
    });
    test('md drops the year', () {
      final out = IcuDateFormat.md(locale: 'en-US').format(jan15);
      expect(out, contains('15'));
      expect(out, isNot(contains('2024')));
    });
  });

  group('IcuTimeFormat', () {
    test('formats an hour and minute', () {
      final out = IcuTimeFormat(locale: 'en-US').format(jan15);
      expect(out, contains('45')); // minute
      expect(out.toLowerCase(), anyOf(contains('pm'), contains('1')));
    });
  });

  group('IcuDateTimeFormat', () {
    test('ymdt carries both date and time', () {
      final out = IcuDateTimeFormat.ymdt(locale: 'en-US').format(jan15);
      expect(out, contains('2024'));
      expect(out, contains('45'));
    });
  });

  group('IcuTimeZoneFormat', () {
    test('specific-long names a US eastern zone', () {
      final out =
          IcuTimeZoneFormat(
            locale: 'en-US',
            style: IcuTimeZoneStyle.specificLong,
          ).format(
            ianaTimeZoneId: 'America/New_York',
            date: jan15,
            utcOffsetSeconds: -5 * 3600,
          );
      expect(out.toLowerCase(), contains('eastern'));
    });
    test('location style throws (no Intl equivalent)', () {
      expect(
        () => IcuTimeZoneFormat(
          locale: 'en-US',
          style: IcuTimeZoneStyle.location,
        ),
        throwsA(isA<IcuUnsupportedError>()),
      );
    });
  });

  group('IcuZonedDateTimeFormat', () {
    test('ymdt appends a zone name', () {
      final out = IcuZonedDateTimeFormat.ymdt(locale: 'en-US').format(
        jan15,
        ianaTimeZoneId: 'America/New_York',
        utcOffsetSeconds: -5 * 3600,
      );
      expect(out, contains('2024'));
      // A short specific zone name like "EST" should be present.
      expect(out, matches(RegExp('E[SD]T|GMT|EST')));
    });
  });

  group('non-ISO calendars (documented gap)', () {
    test('IcuCalendar throws IcuUnsupportedError', () {
      expect(
        () => IcuCalendar(IcuCalendarKind.gregorian),
        throwsA(isA<IcuUnsupportedError>()),
      );
    });
  });
}
