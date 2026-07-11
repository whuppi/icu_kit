// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): behavioral tests for IcuPercentFormat. Tagged 'experimental_percent' to
// allow exclusion from release pipelines if upstream churn breaks them.
//
//   fvm dart test test/facade/percent_format_test.dart
//   fvm dart test --tags=experimental_percent
//
// Backed by ICU4X 2.2's icu_experimental percent formatter. The shape of
// these tests will change when unicode-org/icu4x PR #7789 lands and the
// unified percent/currency/unit redesign ships.

// Diet: the public facade + literals declared in this file.
@Tags(['experimental_percent'])
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuPercentFormat — Standard display (en-US)', () {
    late final IcuPercentFormat fmt;
    setUpAll(() {
      fmt = IcuPercentFormat(locale: 'en-US');
    });

    test('integer renders with percent sign', () {
      final result = fmt.format(50);
      expect(result, contains('50'));
      expect(result, contains('%'));
    });

    test('decimal renders with US-style decimal separator', () {
      final result = fmt.format(12.5);
      expect(result, contains('12.5'));
      expect(result, contains('%'));
    });

    test('zero renders with percent sign', () {
      final result = fmt.format(0);
      expect(result, contains('0'));
      expect(result, contains('%'));
    });

    test('negative value renders with locale-correct minus', () {
      final result = fmt.format(-25);
      expect(result, contains('25'));
      expect(result, contains('%'));
      // en-US uses ASCII minus.
      expect(result, contains('-'));
    });

    test('Standard display has no leading sign for positives', () {
      final result = fmt.format(42);
      expect(
        result.startsWith('+'),
        isFalse,
        reason: 'expected no leading +, got: $result',
      );
      expect(
        result.startsWith('~'),
        isFalse,
        reason: 'expected no leading ~, got: $result',
      );
    });
  });

  group('IcuPercentFormat — Approximate display (en-US)', () {
    test('positive value renders with approximate marker', () {
      final fmt = IcuPercentFormat(
        locale: 'en-US',
        display: IcuPercentDisplay.approximate,
      );
      final result = fmt.format(12);
      // CLDR uses "~" or "≈"; assert at least one of those is present.
      expect(
        result.contains('~') || result.contains('≈'),
        isTrue,
        reason: 'expected approximate marker, got: $result',
      );
      expect(result, contains('12'));
      expect(result, contains('%'));
    });
  });

  group('IcuPercentFormat — ExplicitSign display (en-US)', () {
    late final IcuPercentFormat fmt;
    setUpAll(() {
      fmt = IcuPercentFormat(
        locale: 'en-US',
        display: IcuPercentDisplay.explicitSign,
      );
    });

    test('positive value renders with explicit plus', () {
      final result = fmt.format(7);
      expect(result, contains('+'));
      expect(result, contains('7'));
      expect(result, contains('%'));
    });

    test('negative value renders with minus (not plus)', () {
      final result = fmt.format(-5);
      expect(
        result.contains('+'),
        isFalse,
        reason: 'negative should not get +, got: $result',
      );
      expect(result, contains('5'));
      expect(result, contains('%'));
    });
  });

  group('IcuPercentFormat — French (fr) locale', () {
    test('uses comma as decimal separator', () {
      final fmt = IcuPercentFormat(locale: 'fr');
      final result = fmt.format(12.34);
      expect(result, contains('12,34'));
      expect(result, contains('%'));
    });
  });

  group('IcuPercentFormat — German (de) locale', () {
    test('uses comma as decimal separator', () {
      final fmt = IcuPercentFormat(locale: 'de');
      final result = fmt.format(12.34);
      expect(result, contains('12,34'));
      expect(result, contains('%'));
    });
  });

  group('IcuPercentFormat — Arabic numbering', () {
    test('en-u-nu-arab uses Arabic-Indic digits', () {
      final fmt = IcuPercentFormat(locale: 'en-u-nu-arab');
      final result = fmt.format(50);
      // Arabic-Indic '5' is U+0665, '0' is U+0660.
      expect(
        result.contains('٥') || result.contains('٠'),
        isTrue,
        reason: 'expected Arabic-Indic digits, got: $result',
      );
      expect(result, contains('%'));
    });
  });
}
