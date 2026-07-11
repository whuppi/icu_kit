// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies UTS #46 + RFC 3492 IDNA processing: domain-name conversion
// between Unicode and ASCII Punycode.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  late final IcuIdna idna;
  setUpAll(() {
    idna = IcuIdna.url();
  });

  group('IcuIdna.toAscii — encode to Punycode', () {
    test('ASCII-only domain passes through unchanged', () {
      expect(idna.toAscii('example.com'), 'example.com');
    });

    test('Japanese domain encodes to xn-- prefix', () {
      // 日本.jp → "xn--wgv71a.jp"
      expect(idna.toAscii('日本.jp'), 'xn--wgv71a.jp');
    });

    test('German umlaut encodes', () {
      // münchen.de → "xn--mnchen-3ya.de"
      expect(idna.toAscii('münchen.de'), 'xn--mnchen-3ya.de');
    });

    test('Cyrillic domain encodes', () {
      // россия.рф (Russia) → encoded form
      final result = idna.toAscii('россия.рф');
      expect(result, contains('xn--'));
      expect(result, isNot(contains('россия')));
    });

    test('uppercase ASCII normalizes to lowercase', () {
      // UTS #46 lowercase normalization.
      expect(idna.toAscii('EXAMPLE.COM'), 'example.com');
    });
  });

  group('IcuIdna.toUnicode — decode from Punycode', () {
    test('ASCII domain passes through', () {
      expect(idna.toUnicode('example.com'), 'example.com');
    });

    test('xn--wgv71a.jp decodes to 日本.jp', () {
      expect(idna.toUnicode('xn--wgv71a.jp'), '日本.jp');
    });

    test('xn--mnchen-3ya.de decodes to münchen.de', () {
      expect(idna.toUnicode('xn--mnchen-3ya.de'), 'münchen.de');
    });
  });

  group('IcuIdna — round-trip', () {
    test('Unicode → ASCII → Unicode preserves the domain', () {
      const original = '例え.テスト';
      final ascii = idna.toAscii(original);
      final back = idna.toUnicode(ascii);
      expect(back, original);
    });

    test('multiple labels round-trip', () {
      const original = 'sub.例え.com';
      final ascii = idna.toAscii(original);
      final back = idna.toUnicode(ascii);
      expect(back, original);
    });
  });

  group('IcuIdna — error reporting', () {
    test('toAscii on garbled Punycode throws IcuIdnaError', () {
      // "xn--" prefix with invalid Punycode payload.
      expect(
        () => idna.toAscii('xn--invalid-punycode-zzz'),
        throwsA(isA<IcuIdnaError>()),
      );
    });

    test('error carries domain + operation', () {
      try {
        idna.toAscii('xn--invalid-punycode-zzz');
        fail('expected IcuIdnaError');
      } on IcuIdnaError catch (e) {
        expect(e.domain, 'xn--invalid-punycode-zzz');
        expect(e.operation, 'toAscii');
        expect(e.kind, IcuIdnaErrorKind.invalid);
      }
    });
  });

  group('IcuIdna — common real-world domains', () {
    test('Bücher.de (German bookstore-style)', () {
      final ascii = idna.toAscii('Bücher.de');
      expect(ascii, 'xn--bcher-kva.de');
      expect(idna.toUnicode(ascii), 'bücher.de');
    });

    test('παράδειγμα.gr (Greek "example")', () {
      // Greek "παράδειγμα" = "example".
      final ascii = idna.toAscii('παράδειγμα.gr');
      expect(ascii, contains('xn--'));
      expect(idna.toUnicode(ascii), 'παράδειγμα.gr');
    });
  });

  group('IcuIdna.strict — UTS #46 / RFC 5891 strict mode', () {
    late final IcuIdna strict;
    setUpAll(() {
      strict = IcuIdna.strict();
    });

    test('valid domain passes through', () {
      expect(strict.toAscii('example.com'), 'example.com');
      expect(strict.toAscii('日本.jp'), 'xn--wgv71a.jp');
    });

    test('rejects empty label (foo..bar)', () {
      expect(() => strict.toAscii('foo..bar'), throwsA(isA<IcuIdnaError>()));
    });

    test('rejects oversized label (>63 bytes)', () {
      // 70-char single label exceeds DNS 63-byte limit.
      final tooLong = 'x' * 70;
      expect(
        () => strict.toAscii('$tooLong.com'),
        throwsA(isA<IcuIdnaError>()),
      );
    });

    test('lenient mode accepts what strict rejects', () {
      // foo..bar — empty label. URL-mode passes through; strict rejects.
      expect(idna.toAscii('foo..bar'), 'foo..bar');
      expect(() => strict.toAscii('foo..bar'), throwsA(isA<IcuIdnaError>()));
    });
  });
}
