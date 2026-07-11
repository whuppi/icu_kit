// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies time-only formatting across multiple locales, lengths, and
// hour-cycle locale extensions.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  // Use a fixed wall-clock time so tests are reproducible.
  // 14:32:07.500 → afternoon, easy to verify AM/PM rendering.
  final t = DateTime(2026, 4, 28, 14, 32, 7, 500);

  group('IcuTimeFormat — English (en-US) renders 12-hour with AM/PM', () {
    test('short includes hour + minute + PM marker', () {
      final fmt = IcuTimeFormat(locale: 'en-US', length: IcuDateLength.short);
      final result = fmt.format(t);
      // 14:32 = "2:32" in 12h with PM. Be loose — assertion checks the
      // 12-hour conversion happened (hour "2" present, "14" absent).
      expect(
        result,
        contains('2:32'),
        reason: 'expected 2:32 PM-shape, got: $result',
      );
      expect(
        result.toUpperCase(),
        contains('PM'),
        reason: 'expected PM marker, got: $result',
      );
    });
  });

  group('IcuTimeFormat — German (de) renders 24-hour', () {
    test('short uses 24-hour clock without AM/PM', () {
      final fmt = IcuTimeFormat(locale: 'de', length: IcuDateLength.short);
      final result = fmt.format(t);
      expect(
        result,
        contains('14:32'),
        reason: 'expected 14:32 in 24h, got: $result',
      );
      expect(result.toUpperCase(), isNot(contains('PM')));
    });
  });

  group('IcuTimeFormat — hour-cycle locale override', () {
    test('en-u-hc-h23 forces 24-hour even on en-US', () {
      final fmt = IcuTimeFormat(
        locale: 'en-US-u-hc-h23',
        length: IcuDateLength.short,
      );
      final result = fmt.format(t);
      expect(
        result,
        contains('14'),
        reason: 'expected 24h with -u-hc-h23, got: $result',
      );
      expect(result.toUpperCase(), isNot(contains('PM')));
    });
  });

  group('IcuTimeFormat — precision', () {
    test('precision: hour renders only hour', () {
      final fmt = IcuTimeFormat(
        locale: 'en-US',
        precision: IcuTimePrecision.hour,
      );
      final result = fmt.format(t);
      // Just "2 PM" or similar — no minute.
      expect(
        result,
        isNot(contains('32')),
        reason: 'expected no minute when precision: hour, got: $result',
      );
    });

    test('precision: second includes seconds', () {
      final fmt = IcuTimeFormat(
        locale: 'en-US',
        precision: IcuTimePrecision.second,
      );
      final result = fmt.format(t);
      expect(
        result,
        contains('07'),
        reason: 'expected seconds in output, got: $result',
      );
    });
  });
}
