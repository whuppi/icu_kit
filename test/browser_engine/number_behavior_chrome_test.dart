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

    test('currency Code width renders the ISO code, not the symbol', () {
      // Exercises the CurrencyWidth.code round-trip through the browser Intl
      // shim: Dart enum → JS 'Code' sentinel → currencyDisplay: 'code'.
      final out = IcuCurrencyFormat.symbol(
        locale: 'en-US',
        width: IcuCurrencyWidth.code,
      ).format(1234.56, currencyCode: 'USD');
      expect(out, contains('USD'));
      expect(out, contains('234'));
      expect(out, isNot(contains(r'$')));
    }, tags: ['experimental_currency']);

    test('percent formats value as-is (no ×100)', () {
      // icu4x: 42 → "42%", NOT "4200%".
      final out = IcuPercentFormat(locale: 'en-US').format(42);
      expect(out, contains('42'));
      expect(out, contains('%'));
      expect(out, isNot(contains('4200')));
    }, tags: ['experimental_percent']);

    test('currency useGrouping: false drops separators (browser Intl)', () {
      final plain = IcuCurrencyFormat.symbol(locale: 'en-US', useGrouping: false)
          .format(1234567, currencyCode: 'USD');
      expect(plain, contains('1234567'));
      expect(plain, isNot(contains('1,234')));
    }, tags: ['experimental_currency']);

    test('percent useGrouping: false drops separators (browser Intl)', () {
      final plain =
          IcuPercentFormat(locale: 'en-US', useGrouping: false).format(1234);
      expect(plain, contains('1234'));
      expect(plain, isNot(contains('1,234')));
    }, tags: ['experimental_percent']);

    test('unit useGrouping: false drops separators (browser Intl)', () {
      final plain = IcuUnitFormat(
        locale: 'en-US',
        unit: 'meter',
        useGrouping: false,
      ).format(1234567);
      expect(plain, contains('1234567'));
      expect(plain, isNot(contains('1,234')));
    }, tags: ['experimental_unit']);

    test('roundingMode: nine ECMA-402 modes reach Intl', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      String r(num v, IcuRoundingMode mode) =>
          fmt.format(v, maximumFractionDigits: 0, roundingMode: mode);
      expect(r(1.1, IcuRoundingMode.ceil), '2');
      expect(r(1.9, IcuRoundingMode.floor), '1');
      expect(r(2.5, IcuRoundingMode.halfEven), '2');
      expect(r(-1.9, IcuRoundingMode.trunc), '-1');
    });

    test('signDisplay reaches Intl (always / never / exceptZero)', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      expect(fmt.format(5, signDisplay: IcuSignDisplay.always), '+5');
      expect(fmt.format(-5, signDisplay: IcuSignDisplay.never), '5');
      expect(fmt.format(0, signDisplay: IcuSignDisplay.exceptZero), '0');
    });

    test('trailingZeroDisplay: stripIfInteger reaches Intl', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      expect(
        fmt.format(
          5,
          minimumFractionDigits: 2,
          trailingZeroDisplay: IcuTrailingZeroDisplay.stripIfInteger,
        ),
        '5',
      );
      expect(
        fmt.format(
          5.5,
          minimumFractionDigits: 2,
          trailingZeroDisplay: IcuTrailingZeroDisplay.stripIfInteger,
        ),
        '5.50',
      );
    });

    test('roundingIncrement reaches Intl (25 @ 2fd, 50 @ 2fd, 5 @ 0fd)', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      expect(
        fmt.format(
          1.13,
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
          roundingIncrement: 25,
        ),
        '1.25',
      );
      expect(
        fmt.format(
          1.13,
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
          roundingIncrement: 50,
        ),
        '1.00',
      );
      expect(
        fmt.format(12, maximumFractionDigits: 0, roundingIncrement: 5),
        '10',
      );
    });

    test('minSig on a large integer maps to significant digits, '
        'not a negative fraction bound', () {
      // padEnd(magnitudeEnd - minSig + 1) is a POSITIVE position here; the
      // shim must express it as minimumSignificantDigits — a negative
      // minimumFractionDigits would be an Intl RangeError.
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      expect(fmt.format(1234, minimumSignificantDigits: 2), '1,234');
    });

    test('long currency useGrouping: false drops separators (browser Intl)', () {
      final plain = IcuCurrencyFormat.long(
        locale: 'en-US',
        currencyCode: 'USD',
        useGrouping: false,
      ).format(1234567);
      expect(plain, contains('1234567'));
      expect(plain, isNot(contains('1,234')));
    }, tags: ['experimental_currency']);

    test(
      'percent affix survives a prefix-% locale (Turkish)',
      () {
        // Turkish puts the percent sign BEFORE the number ("%42"), exercising
        // _percentAffix's before-branch that the en-US suffix test doesn't —
        // a structural guard against Intl part-grouping changes dropping the sign.
        final out = IcuPercentFormat(locale: 'tr').format(42);
        expect(out, contains('42'));
        expect(out, contains('%'));
      },
      tags: ['experimental_percent'],
    );

    test(
      'a unit outside the browser Intl set throws (ICU4X has more)',
      () {
        // furlong is a real CLDR/ICU4X unit but NOT ECMA-402 sanctioned, so the
        // browser engine rejects it — as a typed IcuUnsupportedError at creation,
        // not a raw JS RangeError at format time.
        expect(
          () => IcuUnitFormat(locale: 'en-US', unit: 'furlong'),
          throwsA(isA<IcuUnsupportedError>()),
        );
      },
      tags: ['experimental_unit'],
    );

    test('unit formats with the unit', () {
      final out = IcuUnitFormat(locale: 'en-US', unit: 'hour').format(5);
      expect(out, contains('5'));
      expect(out.toLowerCase(), contains('h'));
    }, tags: ['experimental_unit']);
  });
}
