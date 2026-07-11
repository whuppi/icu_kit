// Unit tests for the marker preset resolver (lib/src/hook/marker_presets.dart),
// the single source of truth shared by bin/slice.dart and hook/build.dart.
//
// These run against the REAL vendored registry (present in dev/CI — the
// build hook needs it too), so they prove the prefix rules expand to real
// marker names. They do NOT invoke datagen (that needs cargo + network and
// is covered by the manual slice verification in docs/PLAN_DATA_DIAL.md
// Phase 1).
@TestOn('vm')
library;

import 'dart:io';

import 'package:icu_kit/src/hook/marker_presets.dart';
import 'package:test/test.dart';

void main() {
  final vendor = Directory('vendor/icu4x');

  setUpAll(() {
    if (!File('${vendor.path}/provider/registry/src/lib.rs').existsSync()) {
      fail(
        'vendor/icu4x submodule missing — run `git submodule update --init`. '
        'The marker preset tests read the registry live.',
      );
    }
  });

  test('registry universe is read and non-trivial', () {
    final universe = readMarkerUniverse(vendor);
    // icu4x 2.2 has ~306 markers; guard against a broken read (0/1) or a
    // regex that suddenly matches half the file.
    expect(universe.length, greaterThan(200));
    expect(universe.length, lessThan(500));
    expect(universe, contains('DecimalSymbolsV1'));
    expect(universe, contains('SegmenterBreakWordV1'));
    expect(universe, everyElement(matches(r'^[A-Z][A-Za-z0-9]+V\d+$')));
  });

  test('every preset expands to a non-empty subset of the registry', () {
    final universe = readMarkerUniverse(vendor).toSet();
    for (final name in markerPresets.keys) {
      final resolved = resolveMarkerSpec(name, vendor);
      expect(resolved, isNotEmpty, reason: 'preset "$name" is empty');
      // No invented names — every resolved marker exists in the registry
      // (this is what stops a bad prefix producing a name datagen rejects).
      for (final m in resolved) {
        expect(universe, contains(m), reason: '"$m" not in registry ($name)');
      }
    }
  });

  test('format-core stays in sync with regen_test_postcards stableMarkers', () {
    // The postcard round-trip tests prove that exact set works end to end;
    // format-core must not drift from it. Extract stableMarkers from the
    // tool file and compare.
    final tool = File('tool/regen_test_postcards.dart').readAsStringSync();
    final block = RegExp(
      r'const stableMarkers = \[(.*?)\];',
      dotAll: true,
    ).firstMatch(tool);
    expect(block, isNotNull, reason: 'stableMarkers block not found in tool');
    final stable = RegExp(
      r"'([A-Za-z0-9]+V\d+)'",
    ).allMatches(block!.group(1)!).map((m) => m.group(1)!).toSet();
    final formatCore = resolveMarkerSpec('format-core', vendor).toSet();
    expect(
      formatCore,
      equals(stable),
      reason:
          'format-core preset and regen stableMarkers have diverged — '
          'update both (they must stay identical)',
    );
  });

  test('kit is the union of format-extended, text, and locale', () {
    final kit = resolveMarkerSpec('kit', vendor).toSet();
    final union = {
      ...resolveMarkerSpec('format-extended', vendor),
      ...resolveMarkerSpec('text', vendor),
      ...resolveMarkerSpec('locale', vendor),
    };
    expect(kit, equals(union));
  });

  test('"all" is the datagen keyword, passed through untouched', () {
    expect(resolveMarkerSpec('all', vendor), equals(['all']));
  });

  test('exact comma-separated marker names pass through', () {
    expect(
      resolveMarkerSpec('DecimalSymbolsV1, PluralsCardinalV1', vendor),
      equals(['DecimalSymbolsV1', 'PluralsCardinalV1']),
    );
  });

  test('a mistyped preset errors with the preset list, not silently', () {
    expect(
      () => resolveMarkerSpec('format-cor', vendor),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('Unknown preset'), contains('format-core')),
        ),
      ),
    );
  });

  test('markerPresetNames lists every preset plus all', () {
    expect(markerPresetNames, containsAll(markerPresets.keys));
    expect(markerPresetNames, contains('all'));
  });
}
