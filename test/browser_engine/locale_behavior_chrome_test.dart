// §3a locale family, behaviorally, on the browser engine. Locale algebra
// (canonicalization, likely-subtags, direction) is ECMA-402-defined and
// data-driven from the browser's CLDR, so these are stable enough to assert
// as values — unlike formatted numbers/dates, which vary by browser.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  test('engine reports browser-intl', () {
    expect(IcuKit.engine, 'browser-intl');
  });

  group('IcuLocale.parse', () {
    test('normalizes a valid tag', () {
      expect(IcuLocale.parse('en-us').toString(), 'en-US');
    });
    test('bad tag throws IcuLocaleParseError', () {
      expect(
        () => IcuLocale.parse('!!nope!!'),
        throwsA(isA<IcuLocaleParseError>()),
      );
    });
  });

  group('IcuLocaleCanonicalizer', () {
    test("'Pl' → 'pl'", () {
      expect(IcuLocaleCanonicalizer().canonicalize('Pl'), 'pl');
    });
    test("'eN-uS' → 'en-US'", () {
      expect(IcuLocaleCanonicalizer().canonicalize('eN-uS'), 'en-US');
    });
  });

  group('IcuLocaleExpander', () {
    test('maximize en adds Latn + a region', () {
      final m = IcuLocaleExpander().maximize('en');
      expect(m, contains('Latn'));
      expect(m, startsWith('en-Latn-'));
    });
    test("minimize 'en-Latn-US' → 'en'", () {
      expect(IcuLocaleExpander().minimize('en-Latn-US'), 'en');
    });
    test('minimizeFavorScript shrinks and does not crash', () {
      expect(
        IcuLocaleExpander().minimizeFavorScript('en-Latn-US').length,
        lessThanOrEqualTo('en-Latn-US'.length),
      );
    });
  });

  group('IcuLocaleDirectionality', () {
    test('ar is rtl', () {
      expect(
        IcuLocaleDirectionality().directionOf('ar'),
        IcuLocaleDirection.rightToLeft,
      );
    });
    test('en is ltr', () {
      expect(
        IcuLocaleDirectionality().directionOf('en'),
        IcuLocaleDirection.leftToRight,
      );
    });
    test('he is rtl', () {
      expect(
        IcuLocaleDirectionality().directionOf('he'),
        IcuLocaleDirection.rightToLeft,
      );
    });
  });

  group('IcuLocaleFallbacker', () {
    test("chain('en-Latn-US') → [en-Latn-US, en-US, en]", () {
      expect(IcuLocaleFallbacker().chain('en-Latn-US').toList(), [
        'en-Latn-US',
        'en-US',
        'en',
      ]);
    });
    test('chain starts with the input and ends at the bare language', () {
      final chain = IcuLocaleFallbacker().chain('en-Latn-US').toList();
      expect(chain.first, 'en-Latn-US');
      expect(chain.last, 'en');
    });
  });
}
