// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UCD's GraphemeBreakTest.txt + WordBreakTest.txt +
// SentenceBreakTest.txt + LineBreakTest.txt through IcuSegmenter +
// IcuLineSegmenter. Per-row exact match of break positions; no
// thresholds.
//
// Format per UCD auxiliary tests:
//   ÷ <hex> × <hex> ÷ <hex> ÷  # comment
//
// Where ÷ (U+00F7) marks a break and × (U+00D7) marks a non-break. The
// expected break positions are the indices (in the codepoint sequence)
// where ÷ appears.
//
// Source:
//   https://www.unicode.org/Public/17.0.0/ucd/auxiliary/{Grapheme,Word,Sentence,Line}BreakTest.txt
// (vendored under test/_corpus/ucd/auxiliary/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

class _BreakRow {
  // UTF-16 code-unit boundaries
  _BreakRow(this.input, this.expectedBoundaries);
  final String input;
  final List<int> expectedBoundaries;
}

/// Parse one UCD break-test row into (input string, expected boundaries).
/// Returns null if the row can't be parsed.
_BreakRow? _parseRow(String line) {
  // Strip trailing comment.
  final hashIdx = line.indexOf('#');
  final body = (hashIdx >= 0 ? line.substring(0, hashIdx) : line).trim();
  if (body.isEmpty) return null;

  final inputBuffer = StringBuffer();
  final boundaries = <int>[];
  final tokens = body.split(RegExp(r'\s+'));

  // Each row alternates: separator, codepoint, separator, codepoint, …
  // Starts with ÷ (always a leading break) and ends with ÷.
  for (final tok in tokens) {
    if (tok.isEmpty) continue;
    if (tok == '÷') {
      // Break opportunity at current position.
      boundaries.add(inputBuffer.length);
    } else if (tok == '×') {
      // No break — nothing to do.
    } else {
      // Hex codepoint.
      final cp = int.parse(tok, radix: 16);
      inputBuffer.writeCharCode(cp);
    }
  }
  return _BreakRow(inputBuffer.toString(), boundaries);
}

Future<List<_BreakRow>> _loadBreakRows(String fileName) async {
  final raw = await loadUcdRawText('auxiliary/$fileName');
  final rows = <_BreakRow>[];
  for (final line in raw.split('\n')) {
    final row = _parseRow(line);
    if (row != null) rows.add(row);
  }
  return rows;
}

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuSegmenter — UCD GraphemeBreakTest.txt corpus', () {
    test('every row matches expected break positions', () async {
      final rows = await _loadBreakRows('GraphemeBreakTest.txt');
      expect(rows, isNotEmpty);
      final segmenter = IcuSegmenter.grapheme();
      var verified = 0;
      final mismatches = <String>[];
      for (final row in rows) {
        final actual = segmenter.boundaries(row.input);
        if (!_listEquals(actual, row.expectedBoundaries)) {
          if (mismatches.length < 10) {
            mismatches.add(
              'input=${row.input.codeUnits} '
              'expected=${row.expectedBoundaries} '
              'actual=$actual',
            );
          }
          continue;
        }
        verified++;
      }
      print('  Grapheme: verified=$verified mismatches=${mismatches.length}');
      for (final m in mismatches.take(10)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });
  });

  group('IcuSegmenter — UCD WordBreakTest.txt corpus', () {
    test('every row matches expected break positions', () async {
      final rows = await _loadBreakRows('WordBreakTest.txt');
      expect(rows, isNotEmpty);
      // Per upstream's own conformance test
      // (vendor/icu4x/components/segmenter/tests/spec_test.rs:
      //   "Default word segmenter isn't UAX29 rule. Swedish is UAX29 rule."):
      // ICU4X's default Word segmenter uses dictionary-based
      // segmentation, not UAX #29. To pass UCD WordBreakTest.txt we
      // must construct with a UAX29 content locale; Swedish is the
      // canonical pure-UAX29 choice.
      final segmenter = IcuSegmenter.word(locale: 'sv');
      var verified = 0;
      final mismatches = <String>[];
      for (final row in rows) {
        final actual = segmenter.boundaries(row.input);
        if (!_listEquals(actual, row.expectedBoundaries)) {
          if (mismatches.length < 10) {
            mismatches.add(
              'input=${row.input.codeUnits} '
              'expected=${row.expectedBoundaries} '
              'actual=$actual',
            );
          }
          continue;
        }
        verified++;
      }
      print('  Word: verified=$verified mismatches=${mismatches.length}');
      for (final m in mismatches.take(10)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });
  });

  group('IcuSegmenter — UCD SentenceBreakTest.txt corpus', () {
    test('every row matches expected break positions', () async {
      final rows = await _loadBreakRows('SentenceBreakTest.txt');
      expect(rows, isNotEmpty);
      final segmenter = IcuSegmenter.sentence();
      var verified = 0;
      final mismatches = <String>[];
      for (final row in rows) {
        final actual = segmenter.boundaries(row.input);
        if (!_listEquals(actual, row.expectedBoundaries)) {
          if (mismatches.length < 10) {
            mismatches.add(
              'input=${row.input.codeUnits} '
              'expected=${row.expectedBoundaries} '
              'actual=$actual',
            );
          }
          continue;
        }
        verified++;
      }
      print('  Sentence: verified=$verified mismatches=${mismatches.length}');
      for (final m in mismatches.take(10)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });
  });

  group('IcuLineSegmenter — UCD LineBreakTest.txt corpus', () {
    test('every row matches expected break positions', () async {
      final rows = await _loadBreakRows('LineBreakTest.txt');
      expect(rows, isNotEmpty);
      final segmenter = IcuLineSegmenter.auto();
      var verified = 0;
      final mismatches = <String>[];
      for (final row in rows) {
        // LineBreakTest convention: rows start with `×` (no break at
        // position 0), so leading 0 is NOT in expectedBoundaries.
        // breakOpportunities() also omits the leading 0 — they match.
        //
        // ICU4X's UTF-16 segmenter returns mid-surrogate breaks (between
        // high+low halves of a supplementary codepoint), confirmed
        // upstream against `segment_utf16`. UCD breaks are
        // codepoint-indexed and never enumerate mid-surrogate
        // positions. Filter them out — both halves of a surrogate
        // pair are part of one codepoint, so any "break" inside is an
        // artifact of the UTF-16 representation, not a real semantic
        // boundary.
        final raw = segmenter.breakOpportunities(row.input).toList();
        final actual = raw.where((pos) {
          if (pos == 0 || pos >= row.input.length) return true;
          final code = row.input.codeUnitAt(pos);
          // 0xDC00..0xDFFF = trailing (low) surrogate; if pos lands
          // on one, it's a mid-codepoint position — drop.
          return !(code >= 0xDC00 && code <= 0xDFFF);
        }).toList();
        if (!_listEquals(actual, row.expectedBoundaries)) {
          if (mismatches.length < 10) {
            mismatches.add(
              'input=${row.input.codeUnits} '
              'expected=${row.expectedBoundaries} '
              'actual=$actual',
            );
          }
          continue;
        }
        verified++;
      }
      print('  Line: verified=$verified mismatches=${mismatches.length}');
      for (final m in mismatches.take(10)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });
  });
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
