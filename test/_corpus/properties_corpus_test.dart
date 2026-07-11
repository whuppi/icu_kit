// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UCD's DerivedCoreProperties.txt + PropList.txt corpora
// through IcuProperties for the binary properties our facade exposes.
//
// Format per UAX #44:
//   <hex_or_range>  ; <PropertyName>  # <comment>
//
// Range form: `0030..0039 ; Property` means every codepoint from 0x30
// through 0x39 inclusive has the property.
//
// Conformance: every codepoint listed in the corpus must report
// IcuProperties.has(cp, property) == true. Codepoints NOT listed are
// not tested (the corpus is positive-only — it doesn't enumerate the
// negative space).
//
// Source:
//   - https://www.unicode.org/Public/17.0.0/ucd/DerivedCoreProperties.txt
//   - https://www.unicode.org/Public/17.0.0/ucd/PropList.txt
// (vendored under test/_corpus/ucd/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

/// Maps UCD property names to icu_kit's enum, only for properties
/// our facade actually exposes via `IcuBinaryProperty`. Names not in
/// this map are silently ignored — the corpus contains many properties
/// (e.g. ID_Compat_Math_Continue, NFC_Inert) that ICU4X exposes but
/// our facade doesn't yet.
const _propertyMap = <String, IcuBinaryProperty>{
  // DerivedCoreProperties.txt
  'Alphabetic': IcuBinaryProperty.alphabetic,
  'Lowercase': IcuBinaryProperty.lowercase,
  'Uppercase': IcuBinaryProperty.uppercase,
  'Cased': IcuBinaryProperty.cased,
  'Case_Ignorable': IcuBinaryProperty.caseIgnorable,
  'Math': IcuBinaryProperty.math,
  'ID_Start': IcuBinaryProperty.idStart,
  'ID_Continue': IcuBinaryProperty.idContinue,
  'XID_Start': IcuBinaryProperty.xidStart,
  'XID_Continue': IcuBinaryProperty.xidContinue,
  'Default_Ignorable_Code_Point': IcuBinaryProperty.defaultIgnorableCodePoint,
  'Grapheme_Base': IcuBinaryProperty.graphemeBase,
  'Grapheme_Extend': IcuBinaryProperty.graphemeExtend,

  // PropList.txt
  'White_Space': IcuBinaryProperty.whiteSpace,
  'Bidi_Control': IcuBinaryProperty.bidiControl,
  'Join_Control': IcuBinaryProperty.joinControl,
  'Dash': IcuBinaryProperty.dash,
  // 'Hyphen' is deprecated per UAX #44; not aliased to Dash here.
  'Quotation_Mark': IcuBinaryProperty.quotationMark,
  'Terminal_Punctuation': IcuBinaryProperty.terminalPunctuation,
  'Hex_Digit': IcuBinaryProperty.hexDigit,
  'ASCII_Hex_Digit': IcuBinaryProperty.asciiHexDigit,
  'Ideographic': IcuBinaryProperty.ideographic,
  'Diacritic': IcuBinaryProperty.diacritic,
  'Extender': IcuBinaryProperty.extender,
  'Soft_Dotted': IcuBinaryProperty.softDotted,
  'Noncharacter_Code_Point': IcuBinaryProperty.noncharacterCodePoint,
  // Logical_Order_Exception, Prepended_Concatenation_Mark — no
  // equivalent in our IcuBinaryProperty enum; intentionally absent
  // from this map so the unmapped-property branch skips them.
  'Sentence_Terminal': IcuBinaryProperty.sentenceTerminal,
  'Variation_Selector': IcuBinaryProperty.variationSelector,
  'Pattern_White_Space': IcuBinaryProperty.patternWhiteSpace,
  'Pattern_Syntax': IcuBinaryProperty.patternSyntax,
  'Regional_Indicator': IcuBinaryProperty.regionalIndicator,
  'Radical': IcuBinaryProperty.radical,
  'Unified_Ideograph': IcuBinaryProperty.unifiedIdeograph,
  'Deprecated': IcuBinaryProperty.deprecated,
};

/// Parse a UCD codepoint or range field into a list of integers.
///
/// `0030` → [0x30]
/// `0030..0039` → [0x30, 0x31, ..., 0x39]
List<int> _expandRange(String field) {
  final dotIdx = field.indexOf('..');
  if (dotIdx < 0) {
    return [int.parse(field, radix: 16)];
  }
  final start = int.parse(field.substring(0, dotIdx), radix: 16);
  final end = int.parse(field.substring(dotIdx + 2), radix: 16);
  return [for (var c = start; c <= end; c++) c];
}

/// Strip trailing `# comment` from a UCD field. corpus_loader strips
/// `#` only at the beginning of a line, so each individual field still
/// has its trailing inline comment.
String _stripInlineComment(String s) {
  final idx = s.indexOf('#');
  if (idx < 0) return s.trim();
  return s.substring(0, idx).trim();
}

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuProperties — UCD binary property corpora', () {
    test('every DerivedCoreProperties.txt row matches', () async {
      final rows = await loadUcdFixture('DerivedCoreProperties.txt');
      var verified = 0;
      var skippedUnmappedProperty = 0;
      final mismatches = <String>[];

      for (final row in rows) {
        if (row.length < 2) continue;
        final propName = _stripInlineComment(row[1]);
        final property = _propertyMap[propName];
        if (property == null) {
          skippedUnmappedProperty++;
          continue;
        }
        final codepoints = _expandRange(row[0]);
        for (final cp in codepoints) {
          if (!IcuProperties.has(cp, property)) {
            if (mismatches.length < 10) {
              mismatches.add(
                'U+${cp.toRadixString(16).toUpperCase().padLeft(4, "0")}: '
                'UCD says $propName, IcuProperties.has returned false',
              );
            }
            continue;
          }
          verified++;
        }
      }
      print(
        '  DerivedCoreProperties: verified=$verified '
        'skipped(unmapped)=$skippedUnmappedProperty '
        'mismatches=${mismatches.length}',
      );
      expect(mismatches, isEmpty);
    });

    test('every PropList.txt row matches', () async {
      final rows = await loadUcdFixture('PropList.txt');
      var verified = 0;
      var skippedUnmappedProperty = 0;
      final mismatches = <String>[];

      for (final row in rows) {
        if (row.length < 2) continue;
        final propName = _stripInlineComment(row[1]);
        final property = _propertyMap[propName];
        if (property == null) {
          skippedUnmappedProperty++;
          continue;
        }
        final codepoints = _expandRange(row[0]);
        for (final cp in codepoints) {
          if (!IcuProperties.has(cp, property)) {
            if (mismatches.length < 10) {
              mismatches.add(
                'U+${cp.toRadixString(16).toUpperCase().padLeft(4, "0")}: '
                'UCD says $propName, IcuProperties.has returned false',
              );
            }
            continue;
          }
          verified++;
        }
      }
      print(
        '  PropList: verified=$verified '
        'skipped(unmapped)=$skippedUnmappedProperty '
        'mismatches=${mismatches.length}',
      );
      expect(mismatches, isEmpty);
    });
  });
}
