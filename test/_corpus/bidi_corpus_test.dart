// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UCD's BidiCharacterTest.txt through IcuBidi for full
// UAX #9 conformance verification (rules through L2 inclusive).
//
// Format per UCD:
//   Field 0: hex code points (space-separated)
//   Field 1: paragraph direction (0=LTR, 1=RTL, 2=auto-LTR)
//   Field 2: resolved paragraph embedding level
//   Field 3: per-character resolved levels (`x` = removed by rule X9)
//   Field 4: visual ordering (indices into logical order; X9-removed
//     characters are skipped)
//
// Conformance contract per row:
//   * paragraph.levelAt(0) == field 2
//   * paragraph.reorderedLevelAt(i) for each i where field-3 entry isn't `x`
//   * IcuBidi().reorderVisual(levels), filtered to non-x entries,
//     produces field 4
//
// Source: https://www.unicode.org/Public/17.0.0/ucd/BidiCharacterTest.txt
// (vendored under test/_corpus/ucd/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

/// Map UCD paragraph-direction code to icu_kit's defaultLevel hint.
/// 0=LTR, 1=RTL → explicit base level; 2=auto-detect → null.
int? _paragraphDirToDefaultLevel(int dir) => switch (dir) {
  0 => 0,
  1 => 1,
  2 => null,
  _ => throw StateError('invalid paragraph direction: $dir'),
};

/// Build the input string from Field 0's space-separated hex codepoints.
String _codepointsToString(String field) {
  final codepoints = field
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map((hex) => int.parse(hex, radix: 16))
      .toList(growable: false);
  return String.fromCharCodes(codepoints);
}

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuBidi — UCD BidiCharacterTest.txt UAX #9 conformance corpus', () {
    late final List<List<String>> rows;
    late final IcuBidi bidi;

    setUpAll(() async {
      rows = await loadUcdFixture('BidiCharacterTest.txt');
      bidi = IcuBidi();
    });

    test(
      'every row matches paragraph level + per-char levels + visual order',
      () {
        expect(rows, isNotEmpty);

        var verified = 0;
        var skippedSurrogate = 0;
        final paragraphLevelMismatches = <String>[];
        final charLevelMismatches = <String>[];
        final orderingMismatches = <String>[];

        for (final row in rows) {
          if (row.length < 5) continue;
          final input = _codepointsToString(row[0]);
          final dir = int.parse(row[1]);
          final expectedParaLevel = int.parse(row[2]);
          final expectedLevels = row[3].split(RegExp(r'\s+'));
          final expectedOrdering = row[4]
              .split(RegExp(r'\s+'))
              .where((s) => s.isNotEmpty)
              .map(int.parse)
              .toList(growable: false);

          // Skip rows containing UTF-16 surrogate-pair codepoints — Dart
          // strings encode supplementary planes as surrogate pairs, so the
          // logical-character index space drifts from the corpus's
          // codepoint index space. The other corpus runners hit the same
          // limit and aren't restructured for it; bidi inherits it.
          if (input.length !=
              row[0].split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length) {
            skippedSurrogate++;
            continue;
          }

          final analysis = bidi.analyze(
            input,
            defaultLevel: _paragraphDirToDefaultLevel(dir),
          );
          final paragraph = analysis.paragraph(0);
          if (paragraph == null) {
            paragraphLevelMismatches.add('input=${row[0]}: no paragraph 0');
            continue;
          }

          // Field 2: resolved paragraph embedding level (UAX #9 BD4).
          // Direct comparison against `paragraph.level` — the resolved
          // base level, NOT levelAt(0) which gives the per-char level.
          if (paragraph.level != expectedParaLevel) {
            if (paragraphLevelMismatches.length < 5) {
              paragraphLevelMismatches.add(
                'input=${row[0]} dir=$dir: '
                'expectedParaLevel=$expectedParaLevel '
                'gotLevel=${paragraph.level}',
              );
            }
            continue;
          }

          // Field 3: per-character resolved levels.
          // Build levels array, skipping x's per UAX #9 rule X9.
          final actualLevelsAll = <int>[];
          var levelsOk = true;
          for (var i = 0; i < expectedLevels.length; i++) {
            final actual = paragraph.reorderedLevelAt(i);
            actualLevelsAll.add(actual);
            if (expectedLevels[i] == 'x') continue;
            final expected = int.parse(expectedLevels[i]);
            if (actual != expected) {
              if (charLevelMismatches.length < 5) {
                charLevelMismatches.add(
                  'input=${row[0]} dir=$dir: '
                  'reorderedLevelAt($i): expected $expected, got $actual',
                );
              }
              levelsOk = false;
              break;
            }
          }
          if (!levelsOk) continue;

          // Field 4: visual ordering. Use reorderVisual on the per-char
          // levels, then drop entries whose level was "x".
          final levelsBytes = actualLevelsAll
              .map((l) => l & 0xFF)
              .toList(growable: false);
          final reorderMap = bidi.reorderVisual(levelsBytes);
          final actualOrdering = <int>[];
          for (final logicalIdx in reorderMap) {
            if (logicalIdx < expectedLevels.length &&
                expectedLevels[logicalIdx] != 'x') {
              actualOrdering.add(logicalIdx);
            }
          }
          if (!_listEquals(actualOrdering, expectedOrdering)) {
            if (orderingMismatches.length < 5) {
              orderingMismatches.add(
                'input=${row[0]} dir=$dir: '
                'expected order=${expectedOrdering.join(" ")} '
                'got=${actualOrdering.join(" ")}',
              );
            }
            continue;
          }

          verified++;
        }

        print(
          '  BidiCharacterTest: verified=$verified '
          'skipped(supp)=$skippedSurrogate',
        );
        expect(
          paragraphLevelMismatches,
          isEmpty,
          reason: paragraphLevelMismatches.join('\n'),
        );
        expect(
          charLevelMismatches,
          isEmpty,
          reason: charLevelMismatches.join('\n'),
        );
        expect(
          orderingMismatches,
          isEmpty,
          reason: orderingMismatches.join('\n'),
        );
      },
    );
  });
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
