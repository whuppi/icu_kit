// §3d list / relative-time / display-names on the browser engine. en-US
// output is stable enough for these to assert as values.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  group('IcuListFormat', () {
    test("and: [a, b, c] → 'a, b, and c'", () {
      expect(
        IcuListFormat.and(locale: 'en-US').format(['a', 'b', 'c']),
        'a, b, and c',
      );
    });
    test("or: [a, b] → 'a or b'", () {
      expect(IcuListFormat.or(locale: 'en-US').format(['a', 'b']), 'a or b');
    });
  });

  group('IcuRelativeTimeFormat', () {
    test('day -1 auto → yesterday', () {
      final f = IcuRelativeTimeFormat(
        locale: 'en-US',
        unit: IcuRelativeTimeUnit.day,
        numeric: IcuRelativeTimeNumeric.auto,
      );
      expect(f.format(-1), 'yesterday');
    });
    test('day -3 always → "3 days ago"', () {
      final f = IcuRelativeTimeFormat(
        locale: 'en-US',
        unit: IcuRelativeTimeUnit.day,
      );
      expect(f.format(-3), '3 days ago');
    });
  });

  group('IcuRegionDisplayNames', () {
    test("DE → 'Germany'", () {
      expect(IcuRegionDisplayNames(locale: 'en-US').of('DE'), 'Germany');
    });
    test("JP → 'Japan'", () {
      expect(IcuRegionDisplayNames(locale: 'en-US').of('JP'), 'Japan');
    });
  });

  group('IcuLocaleDisplayNames', () {
    test("de → 'German'", () {
      expect(IcuLocaleDisplayNames(locale: 'en-US').of('de'), 'German');
    });
  });
}
