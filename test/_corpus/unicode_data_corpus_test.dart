// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UCD's UnicodeData.txt corpus through every code-point map
// icu_kit exposes:
//   * IcuGeneralCategoryMap (UCD field 2)
//   * IcuBidiClassMap (UCD field 4)
//   * IcuCanonicalCombiningClassMap (UCD field 3)
//
// UnicodeData.txt has 40,000+ rows including range-encoded blocks (CJK
// ideographs, surrogates, private use, Tangut, Hangul) — those expand to
// every code point in the range.
//
// Source: https://www.unicode.org/Public/16.0.0/ucd/UnicodeData.txt
// (vendored under test/_corpus/ucd/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

/// Empty by design. Our vendored UCD (test/_corpus/ucd/) tracks the
/// SAME Unicode version as ICU4X 2.2's baked data (Unicode 17.0). Any
/// entry here means a real divergence — investigate, don't allowlist.
const _gcAllowlist = <int>{};

/// Maps UCD General Category short codes to icu_kit's enum.
const _gcMap = <String, IcuGeneralCategory>{
  'Lu': IcuGeneralCategory.uppercaseLetter,
  'Ll': IcuGeneralCategory.lowercaseLetter,
  'Lt': IcuGeneralCategory.titlecaseLetter,
  'Lm': IcuGeneralCategory.modifierLetter,
  'Lo': IcuGeneralCategory.otherLetter,
  'Mn': IcuGeneralCategory.nonspacingMark,
  'Mc': IcuGeneralCategory.spacingMark,
  'Me': IcuGeneralCategory.enclosingMark,
  'Nd': IcuGeneralCategory.decimalNumber,
  'Nl': IcuGeneralCategory.letterNumber,
  'No': IcuGeneralCategory.otherNumber,
  'Zs': IcuGeneralCategory.spaceSeparator,
  'Zl': IcuGeneralCategory.lineSeparator,
  'Zp': IcuGeneralCategory.paragraphSeparator,
  'Cc': IcuGeneralCategory.control,
  'Cf': IcuGeneralCategory.format,
  'Cs': IcuGeneralCategory.surrogate,
  'Co': IcuGeneralCategory.privateUse,
  'Cn': IcuGeneralCategory.unassigned,
  'Pd': IcuGeneralCategory.dashPunctuation,
  'Ps': IcuGeneralCategory.openPunctuation,
  'Pe': IcuGeneralCategory.closePunctuation,
  'Pc': IcuGeneralCategory.connectorPunctuation,
  'Pi': IcuGeneralCategory.initialPunctuation,
  'Pf': IcuGeneralCategory.finalPunctuation,
  'Po': IcuGeneralCategory.otherPunctuation,
  'Sm': IcuGeneralCategory.mathSymbol,
  'Sc': IcuGeneralCategory.currencySymbol,
  'Sk': IcuGeneralCategory.modifierSymbol,
  'So': IcuGeneralCategory.otherSymbol,
};

/// Expands UnicodeData.txt rows to (codepoint, gc, ccc, bc) tuples,
/// handling First/Last range markers.
List<_UcdEntry> _expandUnicodeData(List<List<String>> rows) {
  final out = <_UcdEntry>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 5) continue;
    final cp = int.parse(row[0], radix: 16);
    final name = row[1];
    final gc = row[2];
    final ccc = int.parse(row[3]);
    final bc = row[4];

    if (name.contains(', First>') && i + 1 < rows.length) {
      final next = rows[i + 1];
      if (next.length >= 5 && next[1].contains(', Last>')) {
        final endCp = int.parse(next[0], radix: 16);
        for (var c = cp; c <= endCp; c++) {
          out.add(_UcdEntry(c, gc, ccc, bc));
        }
        i++; // skip the Last row
        continue;
      }
    }
    out.add(_UcdEntry(cp, gc, ccc, bc));
  }
  return out;
}

class _UcdEntry {
  _UcdEntry(this.cp, this.gc, this.ccc, this.bc);
  final int cp;
  final String gc;
  final int ccc;
  final String bc;
}

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('UCD UnicodeData.txt corpus — every code point', () {
    late final List<_UcdEntry> entries;
    late final IcuGeneralCategoryMap gcMap;
    late final IcuBidiClassMap bcMap;
    late final IcuCanonicalCombiningClassMap cccMap;
    late final IcuPropertyName bidiNames;

    setUpAll(() async {
      final rows = await loadUcdFixture('UnicodeData.txt');
      entries = _expandUnicodeData(rows);
      gcMap = IcuGeneralCategoryMap();
      bcMap = IcuBidiClassMap();
      cccMap = IcuCanonicalCombiningClassMap();
      bidiNames = IcuPropertyName.bidiClass();
    });

    test('GeneralCategory matches UCD for every code point', () {
      expect(
        entries.length,
        greaterThan(40000),
        reason:
            'corpus drift — expected >40k entries after range '
            'expansion, got ${entries.length}',
      );

      var checked = 0;
      var skipped = 0;
      var allowlisted = 0;
      final mismatches = <String>[];
      for (final e in entries) {
        final expected = _gcMap[e.gc];
        if (expected == null) {
          skipped++;
          continue;
        }
        final actual = gcMap.get(e.cp);
        if (actual != expected) {
          if (_gcAllowlist.contains(e.cp)) {
            allowlisted++;
            continue;
          }
          mismatches.add(
            'U+${e.cp.toRadixString(16).toUpperCase().padLeft(4, "0")}: '
            'UCD ${e.gc} (${expected.name}), got ${actual.name}',
          );
          continue;
        }
        checked++;
      }
      expect(
        skipped,
        0,
        reason: '$skipped UCD GC codes not in _gcMap — corpus drift?',
      );
      print(
        '  GeneralCategory: verified=$checked '
        'allowlisted=$allowlisted mismatches=${mismatches.length}',
      );
      if (mismatches.isNotEmpty) {
        // Print first 30 to see the pattern.
        for (final m in mismatches.take(30)) {
          print('    $m');
        }
        if (mismatches.length > 30) {
          print('    ... (${mismatches.length - 30} more)');
        }
      }
      expect(
        mismatches,
        isEmpty,
        reason:
            '${mismatches.length} GC mismatches between '
            'UCD 16.0 and ICU4X 2.2 data',
      );
    });

    test('BidiClass matches UCD for every code point', () {
      var checked = 0;
      var skipped = 0;
      for (final e in entries) {
        final expectedCode = bidiNames.codeFor(e.bc);
        if (expectedCode == null) {
          skipped++;
          continue;
        }
        final actualCode = bcMap.get(e.cp);
        expect(
          actualCode,
          expectedCode,
          reason:
              'BidiClass(U+${e.cp.toRadixString(16).toUpperCase()}): '
              'UCD says ${e.bc} (=$expectedCode), got $actualCode',
        );
        checked++;
      }
      expect(
        skipped,
        0,
        reason:
            '$skipped UCD bidi-class names not resolvable — '
            'corpus drift?',
      );
      print('  BidiClass: $checked code points verified');
    });

    test('CanonicalCombiningClass matches UCD for every code point', () {
      var checked = 0;
      for (final e in entries) {
        final actual = cccMap.get(e.cp);
        expect(
          actual,
          e.ccc,
          reason:
              'CCC(U+${e.cp.toRadixString(16).toUpperCase()}): '
              'UCD says ${e.ccc}, got $actual',
        );
        checked++;
      }
      print('  CanonicalCombiningClass: $checked code points verified');
    });
  });
}
