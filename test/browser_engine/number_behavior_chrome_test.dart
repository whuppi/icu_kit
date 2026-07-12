// §3b numbers on the browser engine. en-US decimal grouping is deterministic
// (comma thousands, period decimal), so assert exact; currency/percent/unit
// are experimental + browser-varying, so assert structurally.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  group('IcuNumberFormat.decimal (stable)', () {
    test('en-US groups and keeps fraction digits', () {
      expect(
        IcuNumberFormat.decimal(locale: 'en-US').format(1234567.89),
        '1,234,567.89',
      );
    });
    test('useGrouping:false drops separators', () {
      expect(
        IcuNumberFormat.decimal(
          locale: 'en-US',
          useGrouping: false,
        ).format(1234.5),
        '1234.5',
      );
    });
    test('integer formats without a decimal point', () {
      expect(
        IcuNumberFormat.decimal(locale: 'en-US').format(1000000),
        '1,000,000',
      );
    });
    test('preserves precision beyond double (string path)', () {
      // A 19-digit int would lose its last digits through JS Number.
      expect(
        IcuNumberFormat.decimal(
          locale: 'en-US',
          useGrouping: false,
        ).format(1234567890123456),
        '1234567890123456',
      );
    });
    test('fr groups with a non-comma separator', () {
      final out = IcuNumberFormat.decimal(locale: 'fr').format(1234567);
      expect(out, isNot(contains(',')));
      expect(out.replaceAll(RegExp(r'[\s  ]'), ''), '1234567');
    });
  });

  group('experimental formatters (structural)', () {
    test('currency symbol contains a digit run', () {
      final out = IcuCurrencyFormat.symbol(
        locale: 'en-US',
      ).format(1234.56, currencyCode: 'USD');
      expect(out, contains('1'));
      expect(out, contains('234'));
    }, tags: ['experimental_currency']);

    test('percent formats value as-is (no ×100)', () {
      // icu4x: 42 → "42%", NOT "4200%".
      final out = IcuPercentFormat(locale: 'en-US').format(42);
      expect(out, contains('42'));
      expect(out, contains('%'));
      expect(out, isNot(contains('4200')));
    }, tags: ['experimental_percent']);

    test('unit formats with the unit', () {
      final out = IcuUnitFormat(locale: 'en-US', unit: 'hour').format(5);
      expect(out, contains('5'));
      expect(out.toLowerCase(), contains('h'));
    }, tags: ['experimental_unit']);
  });
}
