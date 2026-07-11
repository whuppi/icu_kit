import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  final summer = DateTime(2026, 7, 15, 12);
  final winter = DateTime(2026, 1, 15, 12);

  group('IcuTimeZoneFormat.specificShort — DST awareness', () {
    test('Pacific summer renders PDT', () {
      final fmt = IcuTimeZoneFormat(
        locale: 'en-US',
        style: IcuTimeZoneStyle.specificShort,
      );
      final result = fmt.format(
        ianaTimeZoneId: 'America/Los_Angeles',
        date: summer,
        utcOffsetSeconds: -7 * 3600,
      );
      expect(
        result,
        contains('PDT'),
        reason: 'expected PDT for summer LA, got: $result',
      );
    });

    test('Pacific winter renders PST', () {
      final fmt = IcuTimeZoneFormat(
        locale: 'en-US',
        style: IcuTimeZoneStyle.specificShort,
      );
      final result = fmt.format(
        ianaTimeZoneId: 'America/Los_Angeles',
        date: winter,
        utcOffsetSeconds: -8 * 3600,
      );
      expect(
        result,
        contains('PST'),
        reason: 'expected PST for winter LA, got: $result',
      );
    });
  });

  group('IcuTimeZoneFormat.specificLong — full names', () {
    test('Pacific summer renders "Pacific Daylight Time"', () {
      final fmt = IcuTimeZoneFormat(
        locale: 'en-US',
        style: IcuTimeZoneStyle.specificLong,
      );
      final result = fmt.format(
        ianaTimeZoneId: 'America/Los_Angeles',
        date: summer,
        utcOffsetSeconds: -7 * 3600,
      );
      expect(result.toLowerCase(), contains('pacific'));
      expect(result.toLowerCase(), contains('daylight'));
    });
  });

  group('IcuTimeZoneFormat.localizedOffsetShort', () {
    test('Tokyo renders GMT+9', () {
      final fmt = IcuTimeZoneFormat(
        locale: 'en-US',
        style: IcuTimeZoneStyle.localizedOffsetShort,
      );
      final result = fmt.format(
        ianaTimeZoneId: 'Asia/Tokyo',
        date: summer,
        utcOffsetSeconds: 9 * 3600,
      );
      expect(result.toUpperCase(), contains('GMT'));
      expect(result, contains('9'));
    });
  });

  group('IcuTimeZoneFormat.exemplarCity', () {
    test('Asia/Tokyo renders city name', () {
      final fmt = IcuTimeZoneFormat(
        locale: 'en-US',
        style: IcuTimeZoneStyle.exemplarCity,
      );
      final result = fmt.format(
        ianaTimeZoneId: 'Asia/Tokyo',
        date: summer,
        utcOffsetSeconds: 9 * 3600,
      );
      expect(result.toLowerCase(), contains('tokyo'));
    });
  });

  group('IcuTimeZoneFormat — German locale', () {
    test('Pacific summer in de renders Pazifische Sommerzeit-style', () {
      final fmt = IcuTimeZoneFormat(
        locale: 'de',
        style: IcuTimeZoneStyle.specificLong,
      );
      final result = fmt.format(
        ianaTimeZoneId: 'America/Los_Angeles',
        date: summer,
        utcOffsetSeconds: -7 * 3600,
      );
      // German for "Pacific Daylight Time" includes "Pazifische" or
      // "Sommerzeit".
      expect(
        result.toLowerCase().contains('pazifische') ||
            result.toLowerCase().contains('sommerzeit'),
        isTrue,
        reason: 'expected German Pacific summer label, got: $result',
      );
    });
  });
}
