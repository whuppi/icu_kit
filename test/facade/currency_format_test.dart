// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): all cases tagged 'experimental_currency' so they can be excluded from
// release pipelines if upstream churn breaks them. Run with:
//
//   fvm dart test test/currency_format_test.dart
//   fvm dart test --tags=experimental_currency
//
// Backed by ICU4X 2.2's icu_experimental currency formatter. The shape of
// these tests will change when unicode-org/icu4x PR #7789 lands.

// Diet: the public facade + literals declared in this file.
@Tags(['experimental_currency'])
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuCurrencyFormat.symbol — argument validation', () {
    test('format without currencyCode throws', () {
      final fmt = IcuCurrencyFormat.symbol(locale: 'en-US');
      expect(() => fmt.format(100), throwsA(isA<IcuDataError>()));
    });

    test('format with non-3-letter currency code throws', () {
      final fmt = IcuCurrencyFormat.symbol(locale: 'en-US');
      expect(
        () => fmt.format(100, currencyCode: 'US'),
        throwsA(isA<IcuDataError>()),
      );
      expect(
        () => fmt.format(100, currencyCode: 'USDX'),
        throwsA(isA<IcuDataError>()),
      );
    });
  });

  group('IcuCurrencyFormat.symbol — Short width (en-US)', () {
    late final IcuCurrencyFormat fmt;
    setUpAll(() {
      fmt = IcuCurrencyFormat.symbol(
        locale: 'en-US',
        width: IcuCurrencyWidth.short,
      );
    });

    test('USD renders with dollar sign + grouping', () {
      final result = fmt.format(1234.56, currencyCode: 'USD');
      expect(result, contains('\$'));
      expect(result, contains('1,234'));
    });

    test('EUR renders with currency symbol', () {
      final result = fmt.format(99.5, currencyCode: 'EUR');
      // The exact symbol depends on locale; en-US uses 'EUR' or '€'.
      // We just assert it's non-empty and includes the value.
      expect(result, isNotEmpty);
      expect(result, contains('99'));
    });

    test('digit shaping flows through the currency facade', () {
      // Proves format()'s digit params reach the shared shaper: pad to 2
      // fraction digits, round half away from zero.
      expect(
        fmt.format(5, currencyCode: 'USD', minimumFractionDigits: 2),
        contains('5.00'),
      );
      expect(
        fmt.format(1.005, currencyCode: 'USD', maximumFractionDigits: 2),
        contains('1.01'),
      );
    });
  });

  group('IcuCurrencyFormat.symbol — Code width (en-US)', () {
    late final IcuCurrencyFormat fmt;
    setUpAll(() {
      fmt = IcuCurrencyFormat.symbol(
        locale: 'en-US',
        width: IcuCurrencyWidth.code,
      );
    });

    test('renders the ISO code with a space (¤¤ alpha pattern)', () {
      final out = fmt.format(1234.56, currencyCode: 'USD');
      expect(out, contains('USD'));
      expect(out, contains('1,234.56'));
      // The alpha-next-to-number pattern puts a (non-break) space between the
      // code and the number — not "USD1,234.56".
      expect(out, isNot(contains('USD1')));
    });

    test('EUR code', () {
      expect(fmt.format(99.5, currencyCode: 'EUR'), contains('EUR'));
    });
  });

  group('IcuCurrencyFormat.symbol — useGrouping (en-US)', () {
    test('useGrouping: false drops the thousands separators', () {
      final grouped = IcuCurrencyFormat.symbol(locale: 'en-US')
          .format(1234567, currencyCode: 'USD');
      expect(grouped, contains('1,234,567'));

      final plain = IcuCurrencyFormat.symbol(locale: 'en-US', useGrouping: false)
          .format(1234567, currencyCode: 'USD');
      expect(plain, contains('1234567'));
      expect(plain, isNot(contains('1,234')));
    }, tags: ['experimental_currency']);
  });

  group('IcuCurrencyFormat.symbol — Narrow width (en-US)', () {
    test('Narrow EUR renders compact symbol', () {
      final fmt = IcuCurrencyFormat.symbol(
        locale: 'en-US',
        width: IcuCurrencyWidth.narrow,
      );
      final result = fmt.format(42, currencyCode: 'EUR');
      expect(result, isNotEmpty);
      expect(result, contains('42'));
    });
  });

  group('IcuCurrencyFormat.long — argument validation', () {
    test('non-3-letter currency code throws at construction', () {
      expect(
        () => IcuCurrencyFormat.long(locale: 'en-US', currencyCode: 'US'),
        throwsA(isA<IcuDataError>()),
      );
    });
  });

  group('IcuCurrencyFormat.long — English (en-US) USD', () {
    late final IcuCurrencyFormat fmt;
    setUpAll(() {
      fmt = IcuCurrencyFormat.long(locale: 'en-US', currencyCode: 'USD');
    });

    test('1 USD renders singular form', () {
      final result = fmt.format(1);
      expect(result.toLowerCase(), contains('dollar'));
      expect(result, contains('1'));
      // Singular: "1 US dollar" — no trailing 's' on dollar
      expect(
        result.endsWith('s'),
        isFalse,
        reason: 'expected singular, got: $result',
      );
    });

    test('2 USD renders plural form', () {
      final result = fmt.format(2);
      expect(result.toLowerCase(), contains('dollar'));
      expect(result, contains('2'));
      // Plural: "2 US dollars"
      expect(
        result.endsWith('s'),
        isTrue,
        reason: 'expected plural, got: $result',
      );
    });

    test('pinnedCurrencyCode reflects construction code', () {
      expect(fmt.pinnedCurrencyCode, 'USD');
    });

    test('useGrouping: false drops separators on the long form', () {
      final grouped = IcuCurrencyFormat.long(locale: 'en-US', currencyCode: 'USD')
          .format(1234567);
      expect(grouped, contains('1,234,567'));

      final plain = IcuCurrencyFormat.long(
        locale: 'en-US',
        currencyCode: 'USD',
        useGrouping: false,
      ).format(1234567);
      expect(plain, contains('1234567'));
      expect(plain, isNot(contains('1,234')));
    });
  });

  group('IcuCurrencyFormat.symbol — pinnedCurrencyCode is null', () {
    test('symbol-style instances are not pinned', () {
      final fmt = IcuCurrencyFormat.symbol(locale: 'en-US');
      expect(fmt.pinnedCurrencyCode, isNull);
    });
  });
}
