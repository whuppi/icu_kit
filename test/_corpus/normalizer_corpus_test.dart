// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UCD's NormalizationTest.txt through IcuNormalizer for
// every form (NFC / NFD / NFKC / NFKD).
//
// Format per UAX #15:
//   source ; NFC ; NFD ; NFKC ; NFKD
//
// Conformance invariants the runner verifies (a subset of UAX #15's full
// suite — only the c1 → cN forward transformations our facade exposes):
//   NFC(source)  == c2 (NFC)
//   NFD(source)  == c3 (NFD)
//   NFKC(source) == c4 (NFKC)
//   NFKD(source) == c5 (NFKD)
//
// Source: https://www.unicode.org/Public/17.0.0/ucd/NormalizationTest.txt
// (vendored under test/_corpus/ucd/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

String _hexListToString(String hexList) {
  if (hexList.isEmpty) return '';
  final codepoints = hexList
      .split(' ')
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

  group('IcuNormalizer — full UCD NormalizationTest.txt corpus', () {
    late final List<List<String>> rows;
    late final IcuNormalizer nfc;
    late final IcuNormalizer nfd;
    late final IcuNormalizer nfkc;
    late final IcuNormalizer nfkd;

    setUpAll(() async {
      // Drop the @PartN section headers — they're metadata, not data rows.
      final raw = await loadUcdFixture('NormalizationTest.txt');
      rows = raw.where((r) => r.length >= 5 && !r[0].startsWith('@')).toList();
      nfc = IcuNormalizer(IcuNormalizationForm.nfc);
      nfd = IcuNormalizer(IcuNormalizationForm.nfd);
      nfkc = IcuNormalizer(IcuNormalizationForm.nfkc);
      nfkd = IcuNormalizer(IcuNormalizationForm.nfkd);
    });

    test('every row passes the c1 → c{N} conformance invariants', () {
      expect(
        rows.length,
        greaterThan(15000),
        reason: 'corpus drift — expected ~20k rows, got ${rows.length}',
      );

      var verified = 0;
      for (final row in rows) {
        final source = _hexListToString(row[0]);
        final expectedNfc = _hexListToString(row[1]);
        final expectedNfd = _hexListToString(row[2]);
        final expectedNfkc = _hexListToString(row[3]);
        final expectedNfkd = _hexListToString(row[4]);

        expect(
          nfc.normalize(source),
          expectedNfc,
          reason:
              'NFC: source=${source.codeUnits} '
              'expected=${expectedNfc.codeUnits}',
        );
        expect(
          nfd.normalize(source),
          expectedNfd,
          reason:
              'NFD: source=${source.codeUnits} '
              'expected=${expectedNfd.codeUnits}',
        );
        expect(
          nfkc.normalize(source),
          expectedNfkc,
          reason:
              'NFKC: source=${source.codeUnits} '
              'expected=${expectedNfkc.codeUnits}',
        );
        expect(
          nfkd.normalize(source),
          expectedNfkd,
          reason:
              'NFKD: source=${source.codeUnits} '
              'expected=${expectedNfkd.codeUnits}',
        );
        verified++;
      }
      print(
        '  Normalizer: $verified rows × 4 forms = '
        '${verified * 4} assertions passed',
      );
    });
  });
}
