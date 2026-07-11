// Regenerates the postcard fixtures under `test/_corpus/postcards/`.
//
// These fixtures back the IcuData / IcuDataSource / WithProvider round-trip
// tests. Two fixture sets per locale:
//
//   * `<locale>_minimal.postcard`    — stable markers only. Covers the
//                                     plurals/decimal/datetime/locale/
//                                     IDNA facade families.
//   * `<locale>_experimental.postcard` — adds the icu_experimental
//                                     markers (currency / percent /
//                                     unit / relative-time) needed to
//                                     prove the 5 IDL-patched facades
//                                     end-to-end on the lazy path.
//
// Both are checked in. This tool exists so they can be regenerated on
// demand when ICU4X is bumped, or when a new test needs new markers.
//
// Wraps the upstream `icu4x-datagen` Rust binary located at
// `vendor/icu4x/provider/icu4x-datagen/`. Calls it via `cargo run` so
// the fixtures stay byte-for-byte reproducible against the vendored
// ICU4X (no `cargo install` step that could pin a different version).
//
// Usage from the package root:
//   fvm dart run tool/regen_test_postcards.dart
//
// Run after every ICU4X version bump or when adding a new fixture.

import 'dart:io';

/// Locales we generate fixtures for. Chosen to cover representative
/// behavior across the families our tests exercise:
///   * `en` — base English, the default fallback for many markers.
///   * `fr` — Romance language with plural rules differing from English.
///   * `ja` — CJK locale with its own number system + datetime formats.
const locales = ['en', 'fr', 'ja'];

/// Stable markers — exercise plurals + decimal + datetime + locale +
/// IDNA. No `icu_experimental` dependency, so generation does NOT need
/// the upstream datagen crate's `unstable` feature.
const stableMarkers = [
  // Plural rules (cardinal + ordinal categories).
  'PluralsCardinalV1',
  'PluralsOrdinalV1',

  // Decimal formatting symbols + grouping. Used by NumberFormat (and
  // as the foundational layer underneath the experimental currency /
  // percent / unit formatters).
  'DecimalSymbolsV1',
  'DecimalDigitsV1',

  // Datetime formatting (Gregorian only — keeps the fixture small;
  // other calendars can be added later if a test needs them). Note
  // weekdays are NOT per-calendar (they are calendar-independent).
  'DatetimeNamesMonthGregorianV1',
  'DatetimeNamesYearGregorianV1',
  'DatetimeNamesWeekdayV1',
  'DatetimeNamesDayperiodV1',
  'DatetimePatternsDateGregorianV1',
  'DatetimePatternsTimeV1',
  'DatetimePatternsGlueV1',

  // Locale fallback + canonicalization.
  'LocaleLikelySubtagsLanguageV1',
  'LocaleLikelySubtagsScriptRegionV1',

  // IDNA / UTS#46 — domain-name handling. Stable, despite living in
  // the experimental namespace upstream.
  'NormalizerUts46DataV1',
];

/// Experimental markers — needed for the 5 IDL-patched facades that
/// wrap `icu_experimental`:
///   * IcuCurrencyFormat (symbol + long forms)
///   * IcuPercentFormat
///   * IcuUnitFormat
///   * IcuRelativeTimeFormat
///
/// Generation requires `--features=unstable` on icu4x-datagen.
///
/// **Includes the stable prerequisite markers** (decimal + plurals)
/// because the experimental formatters internally call into the stable
/// decimal layer. Producing a fixture without those would cause
/// `markerNotFound` at format time even though the experimental data
/// is present. Plurals are needed for plural-correct rendering of
/// long-form currency / unit / relative-time.
///
/// **Note:** the public API for these facades is `@experimental` and
/// may rename in ICU4X 2.3+ when PR #7789 lands. When that happens,
/// regenerate after the bump and adjust the marker names here if the
/// upstream API renames them.
const experimentalMarkers = [
  // Stable prerequisites — required by every experimental formatter
  // because they delegate to icu_decimal / icu_plurals internally.
  'DecimalSymbolsV1',
  'DecimalDigitsV1',
  'PluralsCardinalV1',
  'PluralsOrdinalV1',

  // Currency (symbol + long form).
  'CurrencyEssentialsV1',
  'CurrencyExtendedDataV1',
  'CurrencyDisplaynameV1',
  'CurrencyPatternsDataV1',
  'CurrencyFractionsV1',

  // Percent.
  'PercentEssentialsV1',

  // Units. UnitsEssentialsV1 + the families a typical app cares about.
  'UnitsEssentialsV1',
  'UnitsInfoV1',
  'UnitsDisplayNamesV1',
  'UnitsNamesLengthCoreV1',
  'UnitsNamesDurationCoreV1',

  // Relative-time (covers the field-set permutations the formatter
  // can produce: long/short/narrow × second/minute/hour/day/week/
  // month/quarter/year). The tests only need a couple of these to
  // prove the WithProvider arm fires; we include the full set so the
  // fixture covers any future test addition without regen.
  'LongSecondRelativeV1',
  'LongMinuteRelativeV1',
  'LongHourRelativeV1',
  'LongDayRelativeV1',
  'LongWeekRelativeV1',
  'LongMonthRelativeV1',
  'LongYearRelativeV1',
  'ShortSecondRelativeV1',
  'ShortMinuteRelativeV1',
  'ShortHourRelativeV1',
  'ShortDayRelativeV1',
  'ShortWeekRelativeV1',
  'ShortMonthRelativeV1',
  'ShortYearRelativeV1',
  'NarrowSecondRelativeV1',
  'NarrowMinuteRelativeV1',
  'NarrowHourRelativeV1',
  'NarrowDayRelativeV1',
  'NarrowWeekRelativeV1',
  'NarrowMonthRelativeV1',
  'NarrowYearRelativeV1',
];

const datagenManifest = 'vendor/icu4x/provider/icu4x-datagen/Cargo.toml';
const outputDir = 'test/_corpus/postcards';

Future<void> main(List<String> args) async {
  // Verify we're being run from the package root. The cargo manifest
  // path is relative; running from anywhere else silently fails.
  final cargoManifest = File(datagenManifest);
  if (!cargoManifest.existsSync()) {
    stderr.writeln(
      'Run this tool from the icu_kit package root.\n'
      'Expected to find: $datagenManifest',
    );
    exit(2);
  }

  final outDir = Directory(outputDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  print('Regenerating postcard fixtures into $outputDir/');
  print('Locales: ${locales.join(', ')}');
  print('');

  // First pass: stable markers, no `unstable` feature needed.
  print('Stable markers (${stableMarkers.length}):');
  for (final locale in locales) {
    final outFile = '$outputDir/${locale}_minimal.postcard';
    await _runDatagen(
      outFile: outFile,
      markers: stableMarkers,
      locale: locale,
      unstable: false,
    );
  }

  print('');
  // Second pass: experimental markers, requires `--features=unstable`.
  print('Experimental markers (${experimentalMarkers.length}):');
  for (final locale in locales) {
    final outFile = '$outputDir/${locale}_experimental.postcard';
    await _runDatagen(
      outFile: outFile,
      markers: experimentalMarkers,
      locale: locale,
      unstable: true,
    );
  }

  print('');
  print('Done. Commit the regenerated fixtures alongside the bump.');
}

Future<void> _runDatagen({
  required String outFile,
  required List<String> markers,
  required String locale,
  required bool unstable,
}) async {
  print('→ $outFile');

  // Delete any stale fixture so the datagen tool doesn't refuse to
  // overwrite (it errors if the file exists without --overwrite).
  final f = File(outFile);
  if (f.existsSync()) f.deleteSync();

  final result = await Process.run('cargo', [
    'run',
    '--release',
    if (unstable) '--features=unstable',
    '--manifest-path',
    datagenManifest,
    '--',
    '--markers',
    ...markers,
    '--locales',
    locale,
    '--format',
    'blob',
    '--out',
    outFile,
  ], runInShell: false);

  if (result.exitCode != 0) {
    stderr.writeln('FAILED: cargo exited ${result.exitCode}');
    stderr.writeln('--- stderr ---');
    stderr.writeln(result.stderr);
    stderr.writeln('--- stdout ---');
    stderr.writeln(result.stdout);
    exit(result.exitCode);
  }

  final size = f.lengthSync();
  print('  $size bytes');
}
