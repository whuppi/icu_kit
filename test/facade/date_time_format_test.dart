// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies combined date + time output via every field-set, plus
// hour-cycle and length variations.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  // 2026-04-28 14:32:07.500 — Tuesday afternoon.
  final dt = DateTime(2026, 4, 28, 14, 32, 7, 500);

  group('IcuDateTimeFormat.ymdt — English (en-US)', () {
    test('short renders date + 12h time', () {
      final fmt = IcuDateTimeFormat.ymdt(
        locale: 'en-US',
        length: IcuDateLength.short,
      );
      final result = fmt.format(dt);
      // Should include "26" (year), "2:32" (time), "PM"
      expect(result, contains('26'));
      expect(result, contains('2:32'));
      expect(result.toUpperCase(), contains('PM'));
    });

    test('long renders full month + full time', () {
      final fmt = IcuDateTimeFormat.ymdt(
        locale: 'en-US',
        length: IcuDateLength.long,
      );
      final result = fmt.format(dt);
      expect(result, contains('April'));
      expect(result, contains('2026'));
      expect(result, contains('2:32'));
    });
  });

  group('IcuDateTimeFormat.ymdt — German (de) renders 24h', () {
    test('short uses 24-hour clock', () {
      final fmt = IcuDateTimeFormat.ymdt(
        locale: 'de',
        length: IcuDateLength.short,
      );
      final result = fmt.format(dt);
      expect(result, contains('14:32'));
      expect(result.toUpperCase(), isNot(contains('PM')));
    });
  });

  group('IcuDateTimeFormat.ymdet — includes weekday', () {
    test('en-US long includes "Tuesday"', () {
      final fmt = IcuDateTimeFormat.ymdet(
        locale: 'en-US',
        length: IcuDateLength.long,
      );
      final result = fmt.format(dt);
      expect(result.toLowerCase(), contains('tuesday'));
    });
  });

  group('IcuDateTimeFormat.dt — day + time only', () {
    test('en-US renders without month or year', () {
      final fmt = IcuDateTimeFormat.dt(locale: 'en-US');
      final result = fmt.format(dt);
      expect(result, isNot(contains('Apr')));
      expect(result, isNot(contains('2026')));
      expect(result, contains('2:32'));
    });
  });

  group('IcuDateTimeFormat.et — weekday + time', () {
    test('en-US renders without month/day/year', () {
      final fmt = IcuDateTimeFormat.et(locale: 'en-US');
      final result = fmt.format(dt);
      expect(result, isNot(contains('2026')));
      expect(result, contains('2:32'));
    });
  });

  group('IcuDateTimeFormat — precision overrides default', () {
    test('precision: hour drops the minute', () {
      final fmt = IcuDateTimeFormat.ymdt(
        locale: 'en-US',
        precision: IcuTimePrecision.hour,
      );
      final result = fmt.format(dt);
      expect(result, isNot(contains(':32')));
    });

    test('precision: second includes seconds', () {
      final fmt = IcuDateTimeFormat.ymdt(
        locale: 'en-US',
        precision: IcuTimePrecision.second,
      );
      final result = fmt.format(dt);
      expect(result, contains('07'));
    });
  });
}
