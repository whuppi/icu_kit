// §3c plurals on the browser engine. CLDR categories are spec-defined, so
// exact for en (one/other) and a few others.
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  test('en cardinal: 1 → one, 2 → other', () {
    final pr = IcuPluralRules.cardinal('en');
    expect(pr.category(1), IcuPluralCategory.one);
    expect(pr.category(2), IcuPluralCategory.other);
  });

  test('en ordinal: 1 → one, 2 → two, 3 → few, 4 → other', () {
    final pr = IcuPluralRules.ordinal('en');
    expect(pr.category(1), IcuPluralCategory.one);
    expect(pr.category(2), IcuPluralCategory.two);
    expect(pr.category(3), IcuPluralCategory.few);
    expect(pr.category(4), IcuPluralCategory.other);
  });

  test('ar cardinal uses the full category set', () {
    final pr = IcuPluralRules.cardinal('ar');
    expect(pr.category(0), IcuPluralCategory.zero);
    expect(pr.category(1), IcuPluralCategory.one);
    expect(pr.category(2), IcuPluralCategory.two);
  });
}
