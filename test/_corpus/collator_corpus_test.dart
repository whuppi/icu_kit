// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives ICU4X's CollationTest_CLDR_*.txt corpora through IcuCollator.
// Replicates the upstream pattern from
// vendor/icu4x/components/collator/tests/tests.rs — read the file as a
// stream of UCA-sorted hex codepoint sequences; assert each is >= the
// previous in collation order.
//
// Two variants test two alternate-handling modes (the only configurable
// axis upstream's conformance test exercises):
//   * CollationTest_CLDR_NON_IGNORABLE → AlternateHandling::NonIgnorable
//   * CollationTest_CLDR_SHIFTED       → AlternateHandling::Shifted
//
// Both use Strength::Quaternary and the default CLDR-root locale.
//
// Conformance contract:
//   For every consecutive pair (prev, curr) in the file:
//     collator.compare(prev, curr) <= 0  (i.e. prev <= curr)
//
// Source: vendor/icu4x/components/collator/tests/data/
// (vendored under test/_corpus/collator/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

/// Parse a CollationTest line into a Dart string. Returns null for
/// blank / comment lines / non-data lines / lines containing
/// non-scalar values (lone surrogates).
///
/// Upstream's own conformance test parser (vendor/icu4x/components/
/// collator/tests/tests.rs::parse_hex) uses `char::from_u32` which
/// REJECTS lone surrogate code units (0xD800..0xDFFF without a pair).
/// We mirror that: those rows aren't part of upstream's conformance
/// claim, so we don't test them either. Including them would only
/// catch divergences in undefined territory.
String? _parseHexSequence(String line) {
  final hashIdx = line.indexOf('#');
  final body = (hashIdx >= 0 ? line.substring(0, hashIdx) : line);
  final semicolonIdx = body.indexOf(';');
  final hexPart = (semicolonIdx >= 0 ? body.substring(0, semicolonIdx) : body)
      .trim();
  if (hexPart.isEmpty) return null;
  final tokens = hexPart.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  final codepoints = <int>[];
  for (final tok in tokens) {
    final cp = int.tryParse(tok, radix: 16);
    if (cp == null) return null;
    // Reject lone surrogates (matches upstream's char::from_u32).
    if (cp >= 0xD800 && cp <= 0xDFFF) return null;
    codepoints.add(cp);
  }
  if (codepoints.isEmpty) return null;
  return String.fromCharCodes(codepoints);
}

Future<List<String>> _loadCollationLines(String fileName) async {
  final raw = await loadRawText('collator', fileName);
  final result = <String>[];
  for (final line in raw.split('\n')) {
    final s = _parseHexSequence(line);
    if (s != null) result.add(s);
  }
  return result;
}

void _runVariant({
  required String fixture,
  required IcuCollatorAlternateHandling handling,
  required String label,
}) {
  test('$label — every consecutive pair is non-decreasing', () async {
    final strings = await _loadCollationLines(fixture);
    expect(
      strings.length,
      greaterThan(1000),
      reason: 'corpus drift — expected thousands of lines',
    );

    final collator = IcuCollator(
      locale: 'und',
      strength: IcuCollatorStrength.quaternary,
      alternateHandling: handling,
    );

    var verified = 0;
    final mismatches = <String>[];
    var prev = strings.first;
    for (var i = 1; i < strings.length; i++) {
      final curr = strings[i];
      final cmp = collator.compare(prev, curr);
      if (cmp > 0) {
        if (mismatches.length < 10) {
          mismatches.add(
            'line ${i + 1}: prev=${prev.codeUnits} > curr=${curr.codeUnits} '
            '(compare returned $cmp)',
          );
        }
      } else {
        verified++;
      }
      prev = curr;
    }
    print(
      '  $label: verified=$verified '
      'mismatches=${mismatches.length}',
    );
    for (final m in mismatches.take(10)) {
      print('    $m');
    }
    expect(mismatches, isEmpty);
  });
}

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuCollator — UCA conformance corpora', () {
    _runVariant(
      fixture: 'CollationTest_CLDR_NON_IGNORABLE.txt',
      handling: IcuCollatorAlternateHandling.nonIgnorable,
      label: 'NON_IGNORABLE',
    );
    _runVariant(
      fixture: 'CollationTest_CLDR_SHIFTED.txt',
      handling: IcuCollatorAlternateHandling.shifted,
      label: 'SHIFTED',
    );
  });
}
