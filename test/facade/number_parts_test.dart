// formatToParts across the number facades. Runs on the VM (native FFI) and,
// under `make test-web`, in real Chrome against the wasm engine — native and
// wasm produce byte-identical parts, so the exact-list expects hold on both.
// The browser-Intl engine's parts are the browser's own; that path is covered
// by test/browser_engine/number_parts_chrome_test.dart.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

/// `(type, value)` pairs for terse expects.
List<(IcuNumberPartType, String)> pairs(List<IcuNumberPart> parts) =>
    [for (final p in parts) (p.type, p.value)];

/// The reconstruction invariant: concatenating every part's value == format().
void expectReconstructs(List<IcuNumberPart> parts, String formatted) {
  expect(parts.map((p) => p.value).join(), formatted);
}

void main() {
  setUpAll(() async {
    await IcuKit.init();
  });

  group('IcuNumberFormat.formatToParts (decimal)', () {
    test('en-US negative with grouping splits integer at the group', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      final parts = fmt.formatToParts(-1234567.891);
      expect(pairs(parts), [
        (IcuNumberPartType.minusSign, '-'),
        (IcuNumberPartType.integer, '1'),
        (IcuNumberPartType.group, ','),
        (IcuNumberPartType.integer, '234'),
        (IcuNumberPartType.group, ','),
        (IcuNumberPartType.integer, '567'),
        (IcuNumberPartType.decimal, '.'),
        (IcuNumberPartType.fraction, '891'),
      ]);
      expectReconstructs(parts, fmt.format(-1234567.891));
    });

    test('de uses "." for group and "," for decimal', () {
      final fmt = IcuNumberFormat.decimal(locale: 'de');
      final parts = fmt.formatToParts(1234.5);
      final group = parts.firstWhere((p) => p.type == IcuNumberPartType.group);
      final decimal =
          parts.firstWhere((p) => p.type == IcuNumberPartType.decimal);
      expect(group.value, '.');
      expect(decimal.value, ',');
      expectReconstructs(parts, fmt.format(1234.5));
    });

    test('an integer value has no decimal or fraction parts', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      final parts = fmt.formatToParts(42);
      expect(pairs(parts), [(IcuNumberPartType.integer, '42')]);
    });

    test('en-u-nu-arab keeps integer typing with Arabic-Indic digits', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-u-nu-arab');
      final parts = fmt.formatToParts(123);
      // Digits render as Arabic-Indic but the part is still an integer.
      expect(parts.single.type, IcuNumberPartType.integer);
      expect(parts.single.value, isNot('123')); // not ASCII digits
      expectReconstructs(parts, fmt.format(123));
    });

    test('reconstruction invariant over a value × locale matrix', () {
      const values = [0, -0.5, 1, 12, 1234.5, -1234567.891, 1e15];
      const locales = ['en-US', 'de', 'hi', 'ar', 'fr'];
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

    test('every part maps to a known type (no "other" for decimal)', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      for (final p in fmt.formatToParts(-1234567.891)) {
        expect(p.type, isNot(IcuNumberPartType.other),
            reason: 'unmapped rawType "${p.rawType}"');
      }
    });
  });
}
