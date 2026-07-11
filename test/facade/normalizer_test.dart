// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies all four UAX #15 normalization forms.
// Famous test cases:
//   * "é" can be one codepoint (U+00E9) or two (U+0065 U+0301).
//     NFC produces the precomposed form; NFD splits into base + mark.
//   * "ﬁ" (U+FB01, FI ligature) is unchanged in NFC/NFD but becomes
//     "fi" (two codepoints) in NFKC/NFKD.
//   * "①" (U+2460, circled digit one) becomes "1" in NFKC/NFKD.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuNormalizer.nfc — canonical composition', () {
    late final IcuNormalizer nfc;
    setUpAll(() {
      nfc = IcuNormalizer(IcuNormalizationForm.nfc);
    });

    test('"e" + combining acute → precomposed "é"', () {
      // U+0065 (LATIN SMALL LETTER E) + U+0301 (COMBINING ACUTE ACCENT)
      // NFC composes these to U+00E9.
      final decomposed = '\u{0065}\u{0301}';
      final result = nfc.normalize(decomposed);
      expect(result, '\u{00E9}'); // "é" precomposed
      expect(result.length, 1);
    });

    test('already-NFC string passes through', () {
      expect(nfc.normalize('\u{00E9}'), '\u{00E9}');
    });

    test('isNormalized true for precomposed', () {
      expect(nfc.isNormalized('\u{00E9}'), isTrue);
    });

    test('isNormalized false for decomposed', () {
      expect(nfc.isNormalized('\u{0065}\u{0301}'), isFalse);
    });
  });

  group('IcuNormalizer.nfd — canonical decomposition', () {
    late final IcuNormalizer nfd;
    setUpAll(() {
      nfd = IcuNormalizer(IcuNormalizationForm.nfd);
    });

    test('precomposed "é" → "e" + combining acute', () {
      final composed = '\u{00E9}';
      final result = nfd.normalize(composed);
      expect(result, '\u{0065}\u{0301}');
      expect(result.length, 2);
    });
  });

  group('IcuNormalizer.nfkc — compatibility composition', () {
    late final IcuNormalizer nfkc;
    setUpAll(() {
      nfkc = IcuNormalizer(IcuNormalizationForm.nfkc);
    });

    test('"ﬁ" (FI ligature) → "fi" two letters', () {
      // U+FB01 LATIN SMALL LIGATURE FI → "fi"
      expect(nfkc.normalize('\u{FB01}'), 'fi');
    });

    test('"①" → "1"', () {
      // U+2460 CIRCLED DIGIT ONE → "1"
      expect(nfkc.normalize('\u{2460}'), '1');
    });

    test('superscript "²" → "2"', () {
      // U+00B2 SUPERSCRIPT TWO → "2"
      expect(nfkc.normalize('\u{00B2}'), '2');
    });

    test('NFC ligatures are NOT decomposed by NFC alone', () {
      // To prove the difference: NFC does NOT touch "ﬁ".
      final nfcOnly = IcuNormalizer(IcuNormalizationForm.nfc);
      expect(nfcOnly.normalize('\u{FB01}'), '\u{FB01}');
    });
  });

  group('IcuNormalizer.nfkd — compatibility decomposition', () {
    test('"ﬁ" → "fi" (compat decomposition)', () {
      final nfkd = IcuNormalizer(IcuNormalizationForm.nfkd);
      expect(nfkd.normalize('\u{FB01}'), 'fi');
    });

    test('"é" → "e" + combining acute (canonical decomp also applies)', () {
      final nfkd = IcuNormalizer(IcuNormalizationForm.nfkd);
      expect(nfkd.normalize('\u{00E9}'), '\u{0065}\u{0301}');
    });
  });

  group('IcuNormalizer — form getter and isNormalizedUpTo', () {
    test('form getter reflects construction', () {
      final n = IcuNormalizer(IcuNormalizationForm.nfd);
      expect(n.form, IcuNormalizationForm.nfd);
    });

    test('isNormalizedUpTo returns full length for normalized string', () {
      final nfc = IcuNormalizer(IcuNormalizationForm.nfc);
      final s = '\u{00E9}'; // already NFC
      expect(nfc.isNormalizedUpTo(s), s.length);
    });
  });

  group('IcuNormalizer — round-trip', () {
    test('NFC → NFD → NFC is lossless for é', () {
      final nfc = IcuNormalizer(IcuNormalizationForm.nfc);
      final nfd = IcuNormalizer(IcuNormalizationForm.nfd);
      final original = '\u{00E9}';
      expect(nfc.normalize(nfd.normalize(original)), original);
    });
  });
}
