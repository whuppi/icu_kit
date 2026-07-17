// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): ECMA-402 `notation: "compact"`
// through the IcuCompactFormat facade — short/long display, CLDR
// significand rounding, locale correctness, grouping, formatToParts.
//
// Backed by ICU4X's CompactDecimalFormatter (icu_decimal `unstable`),
// exposed via the icu_kit capi patch.

// Diet: the public facade + literals declared in this file.
@Tags(['experimental_compact'])
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuCompactFormat — short display (en-US)', () {
    late final IcuCompactFormat fmt;
    setUpAll(() {
      fmt = IcuCompactFormat(locale: 'en-US');
    });

    test('millions abbreviate with a rounded significand', () {
      // CLDR compact rounding: 1234567 → "1.2M", not "1M".
      expect(fmt.format(1234567), '1.2M');
    });

    test('thousands abbreviate', () {
      expect(fmt.format(1234), '1.2K');
    });

    test('small values pass through un-abbreviated', () {
      expect(fmt.format(123), '123');
    });

    test('negatives keep the sign', () {
      expect(fmt.format(-1172700), '-1.2M');
    });
  });

  group('IcuCompactFormat — long display (en-US)', () {
    test('spells the magnitude word', () {
      final fmt = IcuCompactFormat(
        locale: 'en-US',
        display: IcuCompactDisplay.long,
      );
      final out = fmt.format(1234567);
      expect(out.toLowerCase(), contains('million'));
      expect(out, contains('1.2'));
    });
  });

  group('IcuCompactFormat — locale correctness', () {
    test('German uses its own abbreviation and comma', () {
      final fmt = IcuCompactFormat(locale: 'de');
      final out = fmt.format(1234567);
      // de short compact: "1,2 Mio." — comma decimal + Mio. abbreviation.
      expect(out, contains('1,2'));
      expect(out, contains('Mio'));
    });
  });

  group('IcuCompactFormat — formatToParts', () {
    test('parts concatenate to format() and carry a compact part', () {
      final fmt = IcuCompactFormat(locale: 'en-US');
      final parts = fmt.formatToParts(1234567);
      expect(parts.map((p) => p.value).join(), fmt.format(1234567));
      expect(parts.map((p) => p.type), contains(IcuNumberPartType.compact));
    });
  });
}
