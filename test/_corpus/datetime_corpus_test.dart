// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives ICU4X's own datetime test fixtures (lengths.json + japanese.json)
// through IcuDateFormat / IcuTimeFormat / IcuDateTimeFormat. Per-row
// exact match — no thresholds.
//
// Source:
//   - vendor/icu4x/components/datetime/tests/fixtures/tests/lengths.json
//   - vendor/icu4x/components/datetime/tests/fixtures/tests/japanese.json
// (vendored under test/_corpus/datetime/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

/// Parse `2020-02-20T00:12:00.000` into a Dart DateTime.
DateTime _parseValue(String iso) => DateTime.parse(iso);

/// Map ECMA-402 length string → IcuDateLength.
IcuDateLength _length(String? s) => switch (s) {
  'full' => IcuDateLength.full,
  'long' => IcuDateLength.long,
  'medium' => IcuDateLength.medium,
  'short' => IcuDateLength.short,
  _ => throw ArgumentError('unknown length: $s'),
};

/// Map ECMA-402 timeStyle short → IcuTimePrecision.
IcuTimePrecision? _timePrecisionForLength(String? s) => switch (s) {
  'full' || 'long' => IcuTimePrecision.second,
  'medium' => IcuTimePrecision.second,
  'short' => IcuTimePrecision.minute,
  null => null,
  _ => throw ArgumentError('unknown timeStyle: $s'),
};

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('DateTime — ICU4X lengths.json corpus', () {
    test('every (locale × length) cell matches expected output', () async {
      final rows = await loadJsonFixture('datetime', 'lengths') as List;
      final mismatches = <String>[];
      var verified = 0;

      for (final row in rows) {
        final input = row['input'] as Map;
        final value = _parseValue(input['value'] as String);
        final length = (input['options'] as Map)['length'] as Map;
        final dateLen = length['date'] as String?;
        final timeLen = length['time'] as String?;
        final outputs = (row['output'] as Map)['values'] as Map;

        for (final entry in outputs.entries) {
          final locale = entry.key as String;
          final expected = entry.value as String;

          final String actual;
          if (dateLen != null && timeLen != null) {
            actual = IcuDateTimeFormat.ymdt(
              locale: locale,
              length: _length(dateLen),
              precision: _timePrecisionForLength(timeLen),
            ).format(value);
          } else if (dateLen != null) {
            actual = IcuDateFormat.ymd(
              locale: locale,
              length: _length(dateLen),
            ).format(value);
          } else if (timeLen != null) {
            actual = IcuTimeFormat(
              locale: locale,
              length: _length(timeLen),
              precision: _timePrecisionForLength(timeLen),
            ).format(value);
          } else {
            mismatches.add('$locale: row has no date/time length');
            continue;
          }

          if (actual != expected) {
            mismatches.add(
              'locale=$locale date=$dateLen time=$timeLen: '
              'expected=$expected actual=$actual',
            );
            continue;
          }
          verified++;
        }
      }

      print('  lengths: verified=$verified mismatches=${mismatches.length}');
      for (final m in mismatches.take(20)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });
  });

  // Note on japanese.json (8 rows, components: era=long + year=numeric):
  //
  // We DON'T drive this corpus. Reasoning verified against the upstream
  // runner at vendor/icu4x/components/datetime/tests/datetime.rs:
  //
  //   if let Some(semantic) = fx.input.options.semantic {
  //     // ... run ...
  //   } else {
  //     eprintln!("Warning: Skipping test with no semantic skeleton");
  //     continue;
  //   }
  //
  // japanese.json's rows have only `components` (era/year), no `semantic`.
  // Upstream itself skips them. The fixture is documentation of the
  // intended ECMA-402 component-API behavior; it has no canonical Rust
  // implementation to test against. Adding a runner here would either
  // (a) reinvent ECMA-402 component synthesis we don't expose or
  // (b) hand-pick what we think the right output should be — both
  // forms of "make up tests."
  //
  // Era-handling for IcuDateFormat is covered by the lengths.json
  // corpus rows that include en-u-ca-buddhist and en-u-ca-japanese.
}
