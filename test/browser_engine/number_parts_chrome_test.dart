// formatToParts on the browser-Intl engine. Its parts come from the browser's
// own Intl.NumberFormat, so we assert the SHAPE (typed parts, reconstruction)
// and the stable en-US separators — not byte-exact lists, which track the
// browser's CLDR. Byte-exact ICU4X parts are covered by
// test/facade/number_parts_test.dart (native + wasm).
@TestOn('chrome')
library;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await IcuKit.init(webEngine: WebEngine.browserIntl);
  });

  group('IcuNumberFormat.formatToParts (browser-Intl, decimal)', () {
    test('en-US emits the expected typed parts', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      final parts = fmt.formatToParts(-1234567.891);
      final types = parts.map((p) => p.type).toSet();
      expect(types, contains(IcuNumberPartType.minusSign));
      expect(types, contains(IcuNumberPartType.integer));
      expect(types, contains(IcuNumberPartType.group));
      expect(types, contains(IcuNumberPartType.decimal));
      expect(types, contains(IcuNumberPartType.fraction));
      // Stable en-US separators.
      final group = parts.firstWhere((p) => p.type == IcuNumberPartType.group);
      final decimal =
          parts.firstWhere((p) => p.type == IcuNumberPartType.decimal);
      expect(group.value, ',');
      expect(decimal.value, '.');
    });

    test('integer split at the group (integer, group, integer)', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      final parts = fmt.formatToParts(1234);
      final typesInOrder = parts.map((p) => p.type).toList();
      expect(
        typesInOrder,
        [
          IcuNumberPartType.integer,
          IcuNumberPartType.group,
          IcuNumberPartType.integer,
        ],
      );
    });

    test('reconstruction invariant over a value × locale matrix', () {
      const values = [0, -0.5, 1, 12, 1234.5, -1234567.891];
      const locales = ['en-US', 'de', 'fr', 'ar'];
      for (final locale in locales) {
        final fmt = IcuNumberFormat.decimal(locale: locale);
        for (final v in values) {
          final parts = fmt.formatToParts(v);
          expect(
            parts.map((p) => p.value).join(),
            fmt.format(v),
            reason: 'reconstruction failed for $locale / $v',
          );
        }
      }
    });

    test('every part maps to a known type (no "other")', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      for (final p in fmt.formatToParts(-1234567.891)) {
        expect(p.type, isNot(IcuNumberPartType.other),
            reason: 'unmapped rawType "${p.rawType}"');
      }
    });
  });
}
