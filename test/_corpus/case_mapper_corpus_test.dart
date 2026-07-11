// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UCD's CaseFolding.txt + SpecialCasing.txt through
// IcuCaseMapper. Per-row exact match; no thresholds.
//
// CaseFolding.txt format:
//   <code>; <status>; <mapping>; # <name>
//
// Where <status> is:
//   C — common case folding (single codepoint → single codepoint)
//   F — full case folding (single codepoint → sequence)
//   S — simple folding (subset of C; ignored when F also present)
//   T — Turkic-only folding (only for tr/az locales)
//
// Conformance contract:
//   * For every (code, status=C or F) row: fold(String.fromCharCode(code))
//     must equal mapping.
//   * For every (code, status=T) row: foldTurkic(String.fromCharCode(code))
//     must equal mapping.
//
// SpecialCasing.txt format:
//   <code>; <lower>; <title>; <upper>; (<condition>); # <name>
//
// Conformance contract for unconditional rows (no condition list):
//   * lowercase(s, locale='und') == lower
//   * uppercase(s, locale='und') == upper
//
// Conditional rows (with locale or syntax conditions like Final_Sigma)
// are skipped — they're tested via the language-specific facade tests.
//
// Source:
//   - https://www.unicode.org/Public/17.0.0/ucd/CaseFolding.txt
//   - https://www.unicode.org/Public/17.0.0/ucd/SpecialCasing.txt
// (vendored under test/_corpus/ucd/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

/// Convert a space-separated hex codepoint sequence to a Dart string.
String _hexSeqToString(String s) {
  final cps = s
      .trim()
      .split(RegExp(r'\s+'))
      .map((h) => int.parse(h, radix: 16));
  return String.fromCharCodes(cps);
}

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuCaseMapper.fold — UCD CaseFolding.txt corpus', () {
    test('every common+full row matches', () async {
      final rows = await loadUcdFixture('CaseFolding.txt');
      final cm = IcuCaseMapper();
      var verified = 0;
      final mismatches = <String>[];
      for (final row in rows) {
        if (row.length < 3) continue;
        final code = int.parse(row[0], radix: 16);
        final status = row[1];
        if (status != 'C' && status != 'F') continue;
        final expected = _hexSeqToString(row[2]);
        final actual = cm.fold(String.fromCharCode(code));
        if (actual != expected) {
          if (mismatches.length < 10) {
            mismatches.add(
              'U+${code.toRadixString(16).toUpperCase().padLeft(4, "0")} '
              '($status): expected=${expected.codeUnits} '
              'actual=${actual.codeUnits}',
            );
          }
          continue;
        }
        verified++;
      }
      print(
        '  CaseFolding (C+F): verified=$verified '
        'mismatches=${mismatches.length}',
      );
      for (final m in mismatches.take(10)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });

    test('every Turkic row matches foldTurkic', () async {
      final rows = await loadUcdFixture('CaseFolding.txt');
      final cm = IcuCaseMapper();
      var verified = 0;
      final mismatches = <String>[];
      for (final row in rows) {
        if (row.length < 3) continue;
        final code = int.parse(row[0], radix: 16);
        final status = row[1];
        if (status != 'T') continue;
        final expected = _hexSeqToString(row[2]);
        final actual = cm.foldTurkic(String.fromCharCode(code));
        if (actual != expected) {
          if (mismatches.length < 10) {
            mismatches.add(
              'U+${code.toRadixString(16).toUpperCase().padLeft(4, "0")}: '
              'expected=${expected.codeUnits} actual=${actual.codeUnits}',
            );
          }
          continue;
        }
        verified++;
      }
      print(
        '  CaseFolding (T): verified=$verified '
        'mismatches=${mismatches.length}',
      );
      for (final m in mismatches.take(10)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });
  });

  group('IcuCaseMapper — UCD SpecialCasing.txt corpus', () {
    test('every unconditional row matches lowercase + uppercase', () async {
      final rows = await loadUcdFixture('SpecialCasing.txt');
      final cm = IcuCaseMapper();
      var verified = 0;
      var skippedConditional = 0;
      final mismatches = <String>[];

      for (final row in rows) {
        // Format: code; lower; title; upper; [condition]; # comment
        // 4 fields if no condition, 5 if conditional.
        if (row.length < 4) continue;
        // If row has 5+ fields, it has a condition — skip.
        if (row.length >= 5 && row[4].trim().isNotEmpty) {
          skippedConditional++;
          continue;
        }

        final code = int.parse(row[0], radix: 16);
        final source = String.fromCharCode(code);
        final expectedLower = _hexSeqToString(row[1]);
        final expectedUpper = _hexSeqToString(row[3]);

        final actualLower = cm.lowercase(source, locale: 'und');
        if (actualLower != expectedLower) {
          if (mismatches.length < 10) {
            mismatches.add(
              'lowercase(U+${code.toRadixString(16).toUpperCase()}): '
              'expected=${expectedLower.codeUnits} '
              'actual=${actualLower.codeUnits}',
            );
          }
        } else {
          verified++;
        }

        final actualUpper = cm.uppercase(source, locale: 'und');
        if (actualUpper != expectedUpper) {
          if (mismatches.length < 10) {
            mismatches.add(
              'uppercase(U+${code.toRadixString(16).toUpperCase()}): '
              'expected=${expectedUpper.codeUnits} '
              'actual=${actualUpper.codeUnits}',
            );
          }
        } else {
          verified++;
        }
      }

      print(
        '  SpecialCasing (unconditional): verified=$verified '
        'skipped(conditional)=$skippedConditional '
        'mismatches=${mismatches.length}',
      );
      for (final m in mismatches.take(10)) {
        print('    $m');
      }
      expect(mismatches, isEmpty);
    });
  });
}
