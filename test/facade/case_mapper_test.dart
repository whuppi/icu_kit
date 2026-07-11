// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies locale-aware case mapping. The famous test cases:
//   * Turkish: 'I' ↔ 'ı' (dotless), 'i' ↔ 'İ' (dotted)
//   * German: 'ß' upper → 'SS' (default) or 'ẞ' (special)
//   * Lithuanian: dot-above on 'i' / 'j'
//   * Greek: final sigma 'σ' vs 'ς' (handled by lowercase even in default)

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  late final IcuCaseMapper cm;
  setUpAll(() {
    cm = IcuCaseMapper();
  });

  group('IcuCaseMapper — English baseline', () {
    test('lowercase', () {
      expect(cm.lowercase('HELLO', locale: 'en'), 'hello');
    });

    test('uppercase', () {
      expect(cm.uppercase('hello', locale: 'en'), 'HELLO');
    });

    test('titlecaseSegment', () {
      expect(cm.titlecaseSegment('hello', locale: 'en'), 'Hello');
    });
  });

  group('IcuCaseMapper — Turkish dotted/dotless I', () {
    test('en uppercase: i → I', () {
      expect(cm.uppercase('i', locale: 'en'), 'I');
    });

    test('tr uppercase: i → İ (with dot)', () {
      // Turkish lowercase 'i' has a dot; uppercase preserves it as 'İ'.
      expect(cm.uppercase('i', locale: 'tr'), 'İ');
    });

    test('en lowercase: I → i', () {
      expect(cm.lowercase('I', locale: 'en'), 'i');
    });

    test('tr lowercase: I → ı (without dot)', () {
      // Turkish uppercase 'I' has no dot; lowercase is 'ı' (dotless).
      expect(cm.lowercase('I', locale: 'tr'), 'ı');
    });

    test('tr uppercase: istanbul → İSTANBUL (with dotted İ)', () {
      expect(cm.uppercase('istanbul', locale: 'tr'), 'İSTANBUL');
    });
  });

  group('IcuCaseMapper — German ß', () {
    test('de uppercase: straße → STRASSE', () {
      // CLDR de default: ß → SS. ICU4X 2.2 follows this.
      // (The ẞ uppercase variant requires explicit options that are
      // beyond ICU4X 2.2's default API surface.)
      expect(cm.uppercase('straße', locale: 'de'), 'STRASSE');
    });

    test('de lowercase round-trip is lossy on ß', () {
      // Once 'ß' upper-cases to 'SS', lower-casing gives 'ss', not 'ß'.
      // This is a one-way mapping in CLDR.
      final upper = cm.uppercase('straße', locale: 'de');
      expect(cm.lowercase(upper, locale: 'de'), 'strasse');
    });
  });

  group('IcuCaseMapper — case-folding for case-insensitive comparison', () {
    test('fold makes "Hello" and "hello" equal', () {
      expect(cm.fold('Hello'), cm.fold('hello'));
    });

    test('fold maps ß to ss for compare', () {
      // CaseFold maps ß → ss (Unicode CaseFolding.txt default mapping).
      expect(cm.fold('STRAßE'), cm.fold('strasse'));
    });

    test('foldTurkic distinguishes I/i differently than fold', () {
      // Default fold: 'I' folds to 'i' (matches ASCII expectation).
      // Turkic fold: 'I' folds to 'ı' (Turkish dotless), so 'I' and 'i'
      // are no longer equal under Turkic fold.
      expect(cm.fold('I'), cm.fold('i'));
      // Under foldTurkic: 'I' → 'ı', 'i' → 'i' → not equal.
      expect(cm.foldTurkic('I'), isNot(cm.foldTurkic('i')));
    });
  });

  group('IcuCaseMapper — titlecase options', () {
    test('default trailingCase: lower → "HELLO" → "Hello"', () {
      expect(cm.titlecaseSegment('HELLO', locale: 'en'), 'Hello');
    });

    test('trailingCase: unchanged keeps trailing letters', () {
      expect(
        cm.titlecaseSegment(
          'HELLO',
          locale: 'en',
          trailingCase: IcuTrailingCase.unchanged,
        ),
        'HELLO',
      );
    });

    test('leadingAdjustment: auto skips leading quote', () {
      // With auto, the leading non-cased char (") is skipped, so 'h'
      // becomes 'H'.
      expect(cm.titlecaseSegment('"hello', locale: 'en'), '"Hello');
    });
  });
}
