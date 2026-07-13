// formatToParts across the number facades. Runs on the VM (native FFI) and,
// under `make test-web`, in real Chrome against the wasm engine — native and
// wasm produce byte-identical parts, so the exact-list expects hold on both.
// The browser-Intl engine's parts are the browser's own; that path is covered
// by test/browser_engine/number_parts_chrome_test.dart.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

/// `(type, value)` pairs for terse expects.
List<(IcuNumberPartType, String)> pairs(List<IcuNumberPart> parts) => [
  for (final p in parts) (p.type, p.value),
];

/// The reconstruction invariant: concatenating every part's value == format().
void expectReconstructs(List<IcuNumberPart> parts, String formatted) {
  expect(parts.map((p) => p.value).join(), formatted);
}

void main() {
  setUpAll(() async {
    // On chrome this points init at the served wasm module; a no-op on the VM.
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuNumberPart value equality', () {
    test('identically-constructed parts are equal and hash equal', () {
      const a = IcuNumberPart(
        type: IcuNumberPartType.integer,
        rawType: 'integer',
        value: '42',
      );
      const b = IcuNumberPart(
        type: IcuNumberPartType.integer,
        rawType: 'integer',
        value: '42',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('any differing field breaks equality', () {
      const base = IcuNumberPart(
        type: IcuNumberPartType.integer,
        rawType: 'integer',
        value: '42',
      );
      expect(
        base,
        isNot(
          const IcuNumberPart(
            type: IcuNumberPartType.group,
            rawType: 'group',
            value: '42',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const IcuNumberPart(
            type: IcuNumberPartType.integer,
            rawType: 'integer',
            value: '7',
          ),
        ),
      );
    });

    test('a real part list round-trips through equals', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      final first = fmt.formatToParts(1234.5);
      final second = fmt.formatToParts(1234.5);
      expect(first, second);
    });
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
      final decimal = parts.firstWhere(
        (p) => p.type == IcuNumberPartType.decimal,
      );
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
        expect(
          p.type,
          isNot(IcuNumberPartType.other),
          reason: 'unmapped rawType "${p.rawType}"',
        );
      }
    });

    test('NaN and infinities throw, matching format()', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      // ICU4X's Decimal rejects non-finite doubles at construction; both
      // entry points share the conversion, so both throw — never garbage
      // parts. Type-agnostic: native throws DecimalLimitError, wasm
      // surfaces the JS binding's error.
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(() => fmt.format(v), throwsA(anything), reason: 'format($v)');
        expect(
          () => fmt.formatToParts(v),
          throwsA(anything),
          reason: 'formatToParts($v)',
        );
      }
    });

    test('negative zero keeps its typed minus sign', () {
      final fmt = IcuNumberFormat.decimal(locale: 'en-US');
      final parts = fmt.formatToParts(-0.0);
      expect(pairs(parts), [
        (IcuNumberPartType.minusSign, '-'),
        (IcuNumberPartType.integer, '0'),
      ]);
      expectReconstructs(parts, fmt.format(-0.0));
    });
  });

  group('IcuNumberPartType.fromRawType', () {
    test('maps every known wire name to its enum value', () {
      const known = {
        'integer': IcuNumberPartType.integer,
        'group': IcuNumberPartType.group,
        'decimal': IcuNumberPartType.decimal,
        'fraction': IcuNumberPartType.fraction,
        'minusSign': IcuNumberPartType.minusSign,
        'plusSign': IcuNumberPartType.plusSign,
        'percentSign': IcuNumberPartType.percentSign,
        'approximatelySign': IcuNumberPartType.approximatelySign,
        'currency': IcuNumberPartType.currency,
        'unit': IcuNumberPartType.unit,
        'literal': IcuNumberPartType.literal,
      };
      known.forEach(
        (raw, type) => expect(IcuNumberPartType.fromRawType(raw), type),
      );
    });

    test('unrecognized wire names fall back to other', () {
      // The escape hatch for part types a future engine reports that this
      // version doesn't model — the wire name survives in rawType.
      expect(
        IcuNumberPartType.fromRawType('futureType'),
        IcuNumberPartType.other,
      );
      // Matching is exact — wire names are case-sensitive.
      expect(IcuNumberPartType.fromRawType('Integer'), IcuNumberPartType.other);
    });
  });

  group('IcuCurrencyFormat.formatToParts', () {
    test('USD en-US types the symbol as currency', () {
      final fmt = IcuCurrencyFormat.symbol(locale: 'en-US');
      final parts = fmt.formatToParts(1234.56, currencyCode: 'USD');
      final currency = parts.firstWhere(
        (p) => p.type == IcuNumberPartType.currency,
      );
      expect(currency.value, '\$');
      final types = parts.map((p) => p.type).toSet();
      expect(
        types,
        containsAll([
          IcuNumberPartType.currency,
          IcuNumberPartType.integer,
          IcuNumberPartType.group,
          IcuNumberPartType.decimal,
          IcuNumberPartType.fraction,
        ]),
      );
      expectReconstructs(parts, fmt.format(1234.56, currencyCode: 'USD'));
    }, tags: ['experimental_currency']);

    test(
      'JPY (0-fraction) has no decimal or fraction parts',
      () {
        final fmt = IcuCurrencyFormat.symbol(locale: 'en-US');
        final parts = fmt.formatToParts(1234, currencyCode: 'JPY');
        final types = parts.map((p) => p.type).toSet();
        expect(types, contains(IcuNumberPartType.currency));
        expect(types, isNot(contains(IcuNumberPartType.decimal)));
        expect(types, isNot(contains(IcuNumberPartType.fraction)));
        expectReconstructs(parts, fmt.format(1234, currencyCode: 'JPY'));
      },
      tags: ['experimental_currency'],
    );

    test(
      'long form: the name is one currency part with interior spaces',
      () {
        final fmt = IcuCurrencyFormat.long(
          locale: 'en-US',
          currencyCode: 'USD',
        );
        final parts = fmt.formatToParts(1);
        final currency = parts.firstWhere(
          (p) => p.type == IcuNumberPartType.currency,
        );
        // "US dollar" is a SINGLE currency part (interior space kept).
        expect(currency.value.toLowerCase(), contains('dollar'));
        expect(
          parts.where((p) => p.type == IcuNumberPartType.currency).length,
          1,
        );
        expectReconstructs(parts, fmt.format(1));
      },
      tags: ['experimental_currency'],
    );
  });

  group('IcuPercentFormat.formatToParts', () {
    test('en-US positive: integer + percentSign', () {
      final fmt = IcuPercentFormat(locale: 'en-US');
      final parts = fmt.formatToParts(42);
      final types = parts.map((p) => p.type).toList();
      expect(types, contains(IcuNumberPartType.integer));
      expect(types, contains(IcuNumberPartType.percentSign));
      final pct = parts.firstWhere(
        (p) => p.type == IcuNumberPartType.percentSign,
      );
      expect(pct.value, '%');
      expectReconstructs(parts, fmt.format(42));
    }, tags: ['experimental_percent']);

    test('negative types the minus sign', () {
      final fmt = IcuPercentFormat(locale: 'en-US');
      final parts = fmt.formatToParts(-42);
      expect(parts.map((p) => p.type), contains(IcuNumberPartType.minusSign));
      expectReconstructs(parts, fmt.format(-42));
    }, tags: ['experimental_percent']);

    test('explicit-sign positive types the plus sign', () {
      final fmt = IcuPercentFormat(
        locale: 'en-US',
        display: IcuPercentDisplay.explicitSign,
      );
      final parts = fmt.formatToParts(42);
      expect(parts.map((p) => p.type), contains(IcuNumberPartType.plusSign));
      expectReconstructs(parts, fmt.format(42));
    }, tags: ['experimental_percent']);

    test(
      'approximate display types the approximately sign',
      () {
        final fmt = IcuPercentFormat(
          locale: 'en-US',
          display: IcuPercentDisplay.approximate,
        );
        final parts = fmt.formatToParts(42);
        expect(
          parts.map((p) => p.type),
          contains(IcuNumberPartType.approximatelySign),
        );
        expectReconstructs(parts, fmt.format(42));
      },
      tags: ['experimental_percent'],
    );
  });

  group('IcuUnitFormat.formatToParts', () {
    test('meter short: number parts + a unit part', () {
      final fmt = IcuUnitFormat(locale: 'en-US', unit: 'meter');
      final parts = fmt.formatToParts(5);
      final types = parts.map((p) => p.type).toSet();
      expect(types, contains(IcuNumberPartType.integer));
      expect(types, contains(IcuNumberPartType.unit));
      expectReconstructs(parts, fmt.format(5));
    }, tags: ['experimental_unit']);

    test(
      'reconstruction holds with a grouped fractional value',
      () {
        final fmt = IcuUnitFormat(locale: 'en-US', unit: 'meter');
        final parts = fmt.formatToParts(12345.67);
        expectReconstructs(parts, fmt.format(12345.67));
      },
      tags: ['experimental_unit'],
    );
  });
}
