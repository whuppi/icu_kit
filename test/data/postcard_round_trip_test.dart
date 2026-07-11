// CHARTER — this suite alone proves what the header below declares.
// VM-ONLY (@TestOn below): the FFI provider arm has no web counterpart —
// the web world loads postcards through fetch, proven in the two-world
// suites. Charter: real postcard round-trip tests — proves the IcuData / IcuDataSource /
// preloadLocale machinery actually decodes ICU4X postcard bytes and
// constructs working facades from them.
//
// The previous data tests (`icu_data_test.dart`) only exercised the
// *shape* of IcuData/IcuDataSource — that the constructors carry their
// arguments, that the resolver short-circuits for bundled-only setups,
// etc. They never fed real postcard bytes through the FFI provider.
//
// This file does. Each test loads one of the postcard fixtures from
// `test/_corpus/postcards/`, hands it to a real IcuDataSource, calls
// IcuKit.init + preloadLocale, then constructs a formatter that
// would only succeed if the postcard was decoded and the FFI provider
// actually accepted the bytes.
//
// Native-only: postcard decoding lives behind dart:io path resolution
// for fixture loading. The web bootstrap of icu_kit is covered by
// icu_kit's own facade tests on chrome (the data layer machinery is
// the same; only the byte source differs).

// Diet: the public data API + the vendored corpus postcards (PROVENANCE.md).
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

/// Reads a fixture postcard from `test/_corpus/postcards/`.
///
/// Returns the raw bytes ready to feed into an IcuDataSource.
ByteBuffer _loadFixture(String locale) {
  // dart test sets the cwd to the package root, so the relative path
  // is stable across `dart test` and `dart test path/to/file.dart`.
  final f = File('test/_corpus/postcards/${locale}_minimal.postcard');
  if (!f.existsSync()) {
    throw StateError(
      'Postcard fixture missing: ${f.path}\n'
      'Run `fvm dart run tool/regen_test_postcards.dart` to generate.',
    );
  }
  return f.readAsBytesSync().buffer;
}

void main() {
  // Restore default state after this whole file runs so other test
  // files inherit a clean IcuKit.
  tearDownAll(() async {
    await IcuKit.init();
  });

  group('IcuDataSource.bytes — single in-memory blob', () {
    test('en postcard decodes and powers IcuPluralRules.cardinal', () async {
      final blob = _loadFixture('en');

      // Lean-mode setup: NO bundled data covering 'en', so the only
      // source of truth is the postcard we just loaded. If the FFI
      // provider rejects the bytes, formatter construction throws.
      await IcuKit.init(
        data: IcuData.composite([
          // Bundled layer scoped to a non-existent locale so it doesn't
          // accidentally cover 'en' (would mask whether the postcard
          // path actually fired).
          IcuData.bundled(locales: const ['xx-Bogus']),
          IcuData.lazy(IcuDataSource.bytes(blob)),
        ]),
      );

      // preloadLocale must succeed — proves the resolver fetched bytes
      // from the source AND the FFI provider accepted them.
      await IcuKit.preloadLocale('en');

      // Formatter construction must succeed AND categorize correctly,
      // matching CLDR's English plural rules.
      final f = IcuPluralRules.cardinal('en');
      expect(f.category(1), IcuPluralCategory.one);
      expect(f.category(2), IcuPluralCategory.other);
      expect(f.category(0), IcuPluralCategory.other);
    });

    test('fr postcard decodes and powers IcuPluralRules.cardinal', () async {
      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: const ['xx-Bogus']),
          IcuData.lazy(IcuDataSource.bytes(_loadFixture('fr'))),
        ]),
      );
      await IcuKit.preloadLocale('fr');

      final f = IcuPluralRules.cardinal('fr');
      // French treats 0 + 1 as 'one', everything else as 'other'.
      expect(f.category(0), IcuPluralCategory.one);
      expect(f.category(1), IcuPluralCategory.one);
      expect(f.category(2), IcuPluralCategory.other);
    });

    test('ja postcard decodes and powers IcuPluralRules.cardinal', () async {
      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: const ['xx-Bogus']),
          IcuData.lazy(IcuDataSource.bytes(_loadFixture('ja'))),
        ]),
      );
      await IcuKit.preloadLocale('ja');

      final f = IcuPluralRules.cardinal('ja');
      // Japanese has only 'other' — singular/plural is not grammatically
      // marked. CLDR returns 'other' for every count.
      expect(f.category(0), IcuPluralCategory.other);
      expect(f.category(1), IcuPluralCategory.other);
      expect(f.category(42), IcuPluralCategory.other);
    });

    test('fallbackLocale routes the FFI provider but data-marker keys are '
        'still locale-scoped', () async {
      // When IcuData.lazy(fallbackLocale: 'en') is set and a non-'en'
      // locale is requested without its own preload, the resolver
      // hands the en-postcard provider to ICU4X. BUT ICU4X's data
      // layer keys by exact locale — feeding it an en-only provider
      // and asking for fr-marked data still fails.
      //
      // This test pins that contract: the fallback gives the
      // *provider*, not data-key fallback. Apps that want graceful
      // degradation must either:
      //   * Use a postcard built with multi-locale data, OR
      //   * Use IcuData.composite with bundled covering the fallback.
      //
      // Documenting this here so a future bump that changes the
      // semantics surfaces as a test failure.
      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: const ['xx-Bogus']),
          IcuData.lazy(
            IcuDataSource.bytes(_loadFixture('en')),
            fallbackLocale: 'en',
          ),
        ]),
      );
      await IcuKit.preloadLocale('en');

      // Asking for fr surfaces an IcuDataError because the en-only
      // postcard does not contain fr-keyed data even though the
      // resolver produced an FFI provider for it.
      expect(() => IcuPluralRules.cardinal('fr'), throwsA(isA<IcuDataError>()));
      // Meanwhile the en formatter still works — the postcard does
      // contain en data.
      expect(IcuPluralRules.cardinal('en').category(1), IcuPluralCategory.one);
    });
  });

  group('IcuDataSource.callback — per-locale dispatch', () {
    test(
      'callback receives locale tag and returns matching postcard',
      () async {
        // Track which locales the callback was asked about. Proves the
        // resolver actually queries by locale rather than guessing.
        final asked = <String>[];

        await IcuKit.init(
          data: IcuData.composite([
            IcuData.bundled(locales: const ['xx-Bogus']),
            IcuData.lazy(
              IcuDataSource.callback((locale) async {
                asked.add(locale);
                // Map locale → fixture. Returning null for unknown locales
                // is the standard "I don't have data for this" signal.
                switch (locale) {
                  case 'en':
                    return _loadFixture('en');
                  case 'fr':
                    return _loadFixture('fr');
                  case 'ja':
                    return _loadFixture('ja');
                  default:
                    return null;
                }
              }),
            ),
          ]),
        );

        await IcuKit.preloadLocale('en');
        await IcuKit.preloadLocale('fr');

        // The callback must have been invoked exactly once per requested
        // locale. The resolver's per-locale cache keeps repeat calls
        // from re-fetching.
        expect(asked, ['en', 'fr']);

        // And the formatters constructed from the callback-supplied bytes
        // must work — same correctness check as the bytes path.
        expect(
          IcuPluralRules.cardinal('en').category(1),
          IcuPluralCategory.one,
        );
        expect(
          IcuPluralRules.cardinal('fr').category(0),
          IcuPluralCategory.one,
        );
      },
    );

    test('callback returning null surfaces as missing-data error', () async {
      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: const ['xx-Bogus']),
          IcuData.lazy(IcuDataSource.callback((_) async => null)),
        ]),
      );

      // No fallback configured + every callback returns null => the
      // preload step itself should fail loudly.
      expect(
        () => IcuKit.preloadLocale('en'),
        throwsA(isA<IcuMissingDataError>()),
      );
    });
  });

  group('IcuDataSource.assets — prefix-based key resolution', () {
    test('assets source loads en postcard via supplied loader', () async {
      // The `assets` constructor builds keys of the form
      // `<prefix><locale>.postcard` and calls our `load(key)` callback.
      // We mimic Flutter's `rootBundle.load` shape (returns ByteData)
      // and route the key to the right fixture.
      final keysAsked = <String>[];

      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: const ['xx-Bogus']),
          IcuData.lazy(
            IcuDataSource.assets(
              // Default prefix is `assets/icu/`.
              load: (key) async {
                keysAsked.add(key);
                // Map the key back to one of our fixtures.
                if (key == 'assets/icu/en.postcard') {
                  return ByteData.view(_loadFixture('en'));
                }
                if (key == 'assets/icu/fr.postcard') {
                  return ByteData.view(_loadFixture('fr'));
                }
                throw StateError('Unexpected key: $key');
              },
            ),
          ),
        ]),
      );

      await IcuKit.preloadLocale('en');
      await IcuKit.preloadLocale('fr');

      expect(keysAsked, ['assets/icu/en.postcard', 'assets/icu/fr.postcard']);

      // Formatters must work for both preloaded locales.
      expect(
        IcuPluralRules.cardinal('en').category(2),
        IcuPluralCategory.other,
      );
      expect(IcuPluralRules.cardinal('fr').category(0), IcuPluralCategory.one);
    });

    test('assets source honors a custom prefix', () async {
      final keysAsked = <String>[];

      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: const ['xx-Bogus']),
          IcuData.lazy(
            IcuDataSource.assets(
              prefix: 'cldr/v1/',
              load: (key) async {
                keysAsked.add(key);
                if (key == 'cldr/v1/ja.postcard') {
                  return ByteData.view(_loadFixture('ja'));
                }
                throw StateError('Unexpected key: $key');
              },
            ),
          ),
        ]),
      );

      await IcuKit.preloadLocale('ja');

      expect(keysAsked, ['cldr/v1/ja.postcard']);
      expect(
        IcuPluralRules.cardinal('ja').category(1),
        IcuPluralCategory.other,
      );
    });
  });

  group('IcuData.composite — multi-source resolution', () {
    test(
      'first matching source wins, later sources are not consulted',
      () async {
        // Two callback sources. The first answers 'en'; the second is a
        // sentinel that should NEVER be called for 'en'. If the resolver
        // fired source #2 for 'en', the test fails.
        final secondAsked = <String>[];

        await IcuKit.init(
          data: IcuData.composite([
            IcuData.bundled(locales: const ['xx-Bogus']),
            IcuData.lazy(
              IcuDataSource.callback((locale) async {
                return locale == 'en' ? _loadFixture('en') : null;
              }),
            ),
            IcuData.lazy(
              IcuDataSource.callback((locale) async {
                secondAsked.add(locale);
                return null;
              }),
            ),
          ]),
        );

        await IcuKit.preloadLocale('en');

        // Source #1 resolved 'en' first; the resolver must not have
        // consulted source #2.
        expect(secondAsked, isEmpty);
        expect(
          IcuPluralRules.cardinal('en').category(1),
          IcuPluralCategory.one,
        );
      },
    );

    test('first source returning null falls through to the second', () async {
      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: const ['xx-Bogus']),
          // First source has nothing.
          IcuData.lazy(IcuDataSource.callback((_) async => null)),
          // Second source has 'fr'.
          IcuData.lazy(
            IcuDataSource.callback((locale) async {
              return locale == 'fr' ? _loadFixture('fr') : null;
            }),
          ),
        ]),
      );

      await IcuKit.preloadLocale('fr');

      // Composite walked past source #1, then source #2 satisfied the
      // load. The formatter works.
      expect(IcuPluralRules.cardinal('fr').category(0), IcuPluralCategory.one);
    });
  });
}
