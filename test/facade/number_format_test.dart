// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): loads the icu_capi native library via the build hook, exercises the Dart
// facade, and verifies CLDR-correct decimal formatting across multiple
// locales (separators, grouping strategies).

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuNumberFormat — English (en-US)', () {
    late final IcuNumberFormat fmt;
    setUpAll(() {
      fmt = IcuNumberFormat.decimal(locale: 'en-US');
    });

    test('integer with grouping', () {
      expect(fmt.format(1234567), '1,234,567');
    });

    test('decimal with grouping', () {
      expect(fmt.format(1234567.89), '1,234,567.89');
    });

    test('small number unchanged', () {
      expect(fmt.format(42), '42');
    });

    test('zero', () => expect(fmt.format(0), '0'));

    test('negative number', () {
      expect(fmt.format(-1234.5), '-1,234.5');
    });
  });

  group('IcuNumberFormat — French (fr) uses thin space + comma', () {
    late final IcuNumberFormat fmt;
    setUpAll(() {
      fmt = IcuNumberFormat.decimal(locale: 'fr');
    });

    test('integer', () {
      // French CLDR groups with U+202F (NARROW NO-BREAK SPACE) and uses
      // ',' as the decimal separator.
      final result = fmt.format(1234567);
      // Strip the actual whitespace char to compare loose; spec'd in CLDR.
      expect(result.replaceAll(RegExp(r'\s'), ''), '1234567');
      // The grouping char IS a whitespace of some kind:
      expect(result, isNot(equals('1234567')));
    });

    test('decimal separator is comma', () {
      final result = fmt.format(1234.56);
      expect(
        result.endsWith(',56'),
        isTrue,
        reason: 'expected comma separator, got: $result',
      );
    });
  });

  group('IcuNumberFormat — German (de) uses period for grouping', () {
    late final IcuNumberFormat fmt;
    setUpAll(() {
      fmt = IcuNumberFormat.decimal(locale: 'de');
    });

    test('grouping uses period, decimal uses comma', () {
      // German: "1.234.567,89" — opposite of en-US.
      expect(fmt.format(1234567.89), '1.234.567,89');
    });
  });

  group('IcuNumberFormat — useGrouping option', () {
    test('useGrouping: false → no separators', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US', useGrouping: false);
      expect(fmt.format(1234567), '1234567');
    });

    test('useGrouping: true → forces grouping even on small locales', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US', useGrouping: true);
      expect(fmt.format(1234), '1,234');
    });
  });

  group('IcuNumberFormat — IcuGroupingStrategy.min2 (4-digit threshold)', () {
    test('min2 does NOT group 4-digit numbers', () {
      final fmt = IcuNumberFormat.decimal(
        locale: 'en-US',
        groupingStrategy: IcuGroupingStrategy.min2,
      );
      // min2 = "group when there are at least 2 groups of 3 digits"
      // → 4-digit numbers (1 group) are not grouped; 5+ digit numbers are.
      expect(fmt.format(1234), '1234');
      expect(fmt.format(12345), '12,345');
    });
  });

  group('IcuNumberFormat — digit shaping (E2 fraction + integer)', () {
    late final IcuNumberFormat fmt;
    setUpAll(() {
      fmt = IcuNumberFormat.decimal(locale: 'en-US', useGrouping: false);
    });

    test('minimumFractionDigits pads trailing zeros', () {
      expect(fmt.format(1, minimumFractionDigits: 2), '1.00');
      expect(fmt.format(1.5, minimumFractionDigits: 3), '1.500');
    });

    test('maximumFractionDigits rounds half away from zero', () {
      // ECMA-402 default rounding is halfExpand, not ICU4X's half-even:
      // 2.5 → 3 (not 2), 0.125 → 0.13 (not 0.12).
      expect(fmt.format(2.5, maximumFractionDigits: 0), '3');
      expect(fmt.format(0.125, maximumFractionDigits: 2), '0.13');
      expect(fmt.format(1.567, maximumFractionDigits: 2), '1.57');
    });

    test('min + max fraction digits together', () {
      // Round to at most 2, pad to at least 2.
      expect(
        fmt.format(1.5, minimumFractionDigits: 2, maximumFractionDigits: 2),
        '1.50',
      );
      expect(
        fmt.format(1.567, minimumFractionDigits: 2, maximumFractionDigits: 2),
        '1.57',
      );
    });

    test('minimumIntegerDigits left-pads with zeros', () {
      expect(fmt.format(42, minimumIntegerDigits: 5), '00042');
      expect(fmt.format(1234.5, minimumIntegerDigits: 6), '001234.5');
    });

    test('negative values shape correctly', () {
      expect(fmt.format(-2.5, maximumFractionDigits: 0), '-3');
      expect(fmt.format(-1, minimumFractionDigits: 2), '-1.00');
    });

    test('no digit options → unchanged round-trip', () {
      expect(fmt.format(1234.5), '1234.5');
      expect(fmt.format(1.567), '1.567');
    });
  });
}
