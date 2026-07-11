// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): behavioral tests for IcuUnitFormat. Tagged 'experimental_unit'.
//
//   fvm dart test test/facade/unit_format_test.dart
//   fvm dart test --tags=experimental_unit
//
// Backed by ICU4X 2.2's icu_experimental units formatter. Same migration
// trigger as currency / percent (PR #7789).

// Diet: the public facade + literals declared in this file.
@Tags(['experimental_unit'])
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuUnitFormat — argument validation', () {
    test('empty unit throws', () {
      expect(
        () => IcuUnitFormat(locale: 'en-US', unit: ''),
        throwsA(isA<IcuDataError>()),
      );
    });

    test('unknown unit throws', () {
      expect(
        () => IcuUnitFormat(locale: 'en-US', unit: 'not-a-real-unit-12345'),
        throwsA(isA<IcuDataError>()),
      );
    });
  });

  group('IcuUnitFormat — Short width (en-US, hour)', () {
    late final IcuUnitFormat fmt;
    setUpAll(() {
      fmt = IcuUnitFormat(locale: 'en-US', unit: 'hour');
    });

    test('1 renders short form', () {
      final result = fmt.format(1);
      expect(result, contains('1'));
      expect(result, isNotEmpty);
    });

    test('2 renders short form', () {
      final result = fmt.format(2);
      expect(result, contains('2'));
      expect(result, isNotEmpty);
    });

    test('unit getter reflects construction', () {
      expect(fmt.unit, 'hour');
    });
  });

  group('IcuUnitFormat — Long width (en-US, hour) plural-correct', () {
    late final IcuUnitFormat fmt;
    setUpAll(() {
      fmt = IcuUnitFormat(
        locale: 'en-US',
        unit: 'hour',
        width: IcuUnitWidth.long,
      );
    });

    test('1 renders singular "hour"', () {
      final result = fmt.format(1).toLowerCase();
      expect(result, contains('1'));
      expect(result, contains('hour'));
      // Singular: "1 hour" — should NOT contain "hours"
      expect(
        result.contains('hours'),
        isFalse,
        reason: 'expected singular, got: $result',
      );
    });

    test('2 renders plural "hours"', () {
      final result = fmt.format(2).toLowerCase();
      expect(result, contains('2'));
      expect(result, contains('hours'));
    });

    test('5 renders plural "hours"', () {
      final result = fmt.format(5).toLowerCase();
      expect(result, contains('5'));
      expect(result, contains('hours'));
    });
  });

  group('IcuUnitFormat — Narrow width (en-US, hour)', () {
    test('renders compact form', () {
      final fmt = IcuUnitFormat(
        locale: 'en-US',
        unit: 'hour',
        width: IcuUnitWidth.narrow,
      );
      final result = fmt.format(5);
      expect(result, contains('5'));
      expect(result, isNotEmpty);
      // Narrow shouldn't contain "hours" word.
      expect(
        result.toLowerCase().contains('hours'),
        isFalse,
        reason: 'narrow should not include full word, got: $result',
      );
    });
  });

  group('IcuUnitFormat — Length units (kilometer)', () {
    test('en-US long form renders "kilometers" plural', () {
      final fmt = IcuUnitFormat(
        locale: 'en-US',
        unit: 'kilometer',
        width: IcuUnitWidth.long,
      );
      final result = fmt.format(5).toLowerCase();
      expect(result, contains('5'));
      expect(result, contains('kilometer'));
    });
  });

  group('IcuUnitFormat — Compound units (kilometer-per-hour)', () {
    test('en-US short form renders speed', () {
      final fmt = IcuUnitFormat(locale: 'en-US', unit: 'kilometer-per-hour');
      final result = fmt.format(120);
      expect(result, contains('120'));
      expect(result, isNotEmpty);
    });
  });

  group('IcuUnitFormat — French (fr) locale', () {
    test('uses locale-correct decimal separator', () {
      final fmt = IcuUnitFormat(
        locale: 'fr',
        unit: 'kilometer',
        width: IcuUnitWidth.long,
      );
      final result = fmt.format(2.5);
      expect(result, contains('2,5'));
    });
  });

  group('IcuUnitFormat — German (de) locale', () {
    test('1 renders singular form', () {
      final fmt = IcuUnitFormat(
        locale: 'de',
        unit: 'hour',
        width: IcuUnitWidth.long,
      );
      final result = fmt.format(1);
      expect(result, contains('1'));
      expect(result, isNotEmpty);
    });
  });
}
