// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): icuData / IcuDataSource / IcuKit.init / IcuKit.preloadLocale contract tests.
//
// Native side: real CLDR data is bundled at compile time. These tests
// exercise the IcuKit init/preload state machine and the IcuData/IcuDataSource
// shape — they don't require any postcard fixtures because every locale is
// resolvable through the bundled compiled-data path.

// Diet: the public data API + the vendored corpus postcards (PROVENANCE.md).
import 'dart:typed_data';

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    // Web tests need IcuKit.moduleUrl set before init. On native it's a
    // no-op setter. Path is relative to the test page URL nested under
    // package:test's secret-prefix path (see other facade tests for the
    // full explanation).
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuData — sealed class shape', () {
    test('IcuData.bundled() with no args yields BundledIcuData', () {
      final d = IcuData.bundled();
      expect(d, isA<BundledIcuData>());
      expect((d as BundledIcuData).locales, isNull);
    });

    test('IcuData.bundled(locales: [...]) carries the list', () {
      final d = IcuData.bundled(locales: ['en', 'fr']) as BundledIcuData;
      expect(d.locales, ['en', 'fr']);
    });

    test('IcuData.lazy(source) yields LazyIcuData', () {
      final src = IcuDataSource.bytes(Uint8List(0).buffer);
      final d = IcuData.lazy(src) as LazyIcuData;
      expect(d.source, same(src));
      expect(d.fallbackLocale, isNull);
    });

    test('IcuData.lazy carries fallbackLocale when set', () {
      final src = IcuDataSource.bytes(Uint8List(0).buffer);
      final d = IcuData.lazy(src, fallbackLocale: 'en') as LazyIcuData;
      expect(d.fallbackLocale, 'en');
    });

    test('IcuData.composite([...]) carries the source list', () {
      final a = IcuData.bundled(locales: ['en']);
      final b = IcuData.lazy(IcuDataSource.bytes(Uint8List(0).buffer));
      final d = IcuData.composite([a, b]) as CompositeIcuData;
      expect(d.sources, [a, b]);
    });
  });

  group('IcuDataSource — three constructors', () {
    test('IcuDataSource.bytes returns same bytes for any locale', () async {
      final blob = Uint8List.fromList([1, 2, 3]).buffer;
      final src = IcuDataSource.bytes(blob);
      expect(await src.resolve('en'), same(blob));
      expect(await src.resolve('fr'), same(blob));
    });

    test('IcuDataSource.callback delegates to user fn per locale', () async {
      final calls = <String>[];
      final src = IcuDataSource.callback((locale) async {
        calls.add(locale);
        return locale == 'fr' ? Uint8List.fromList([0xFE, 0xED]).buffer : null;
      });
      expect(await src.resolve('en'), isNull);
      expect(await src.resolve('fr'), isNotNull);
      expect(calls, ['en', 'fr']);
    });

    test('IcuDataSource.assets builds the path with default prefix', () async {
      final keys = <String>[];
      final src = IcuDataSource.assets(
        load: (key) async {
          keys.add(key);
          return ByteData(0);
        },
      );
      await src.resolve('en');
      await src.resolve('zh-Hant');
      expect(keys, ['assets/icu/en.postcard', 'assets/icu/zh-Hant.postcard']);
    });

    test('IcuDataSource.assets honors custom prefix', () async {
      final keys = <String>[];
      final src = IcuDataSource.assets(
        load: (key) async {
          keys.add(key);
          return ByteData(0);
        },
        prefix: 'custom/i18n/',
      );
      await src.resolve('ja');
      expect(keys, ['custom/i18n/ja.postcard']);
    });

    test('IcuDataSource.assets returns null when load throws', () async {
      final src = IcuDataSource.assets(
        load: (_) async {
          throw StateError('missing');
        },
      );
      expect(await src.resolve('xx'), isNull);
    });
  });

  group('IcuKit.init / preloadLocale state machine', () {
    test('IcuKit.init() with default IcuData succeeds', () async {
      await IcuKit.init();
      // Sanity: a formatter for any locale constructs without throwing.
      final f = IcuPluralRules.cardinal('en');
      expect(f.category(1), IcuPluralCategory.one);
    });

    test('init replaces active data — call twice is fine', () async {
      await IcuKit.init();
      await IcuKit.init(data: IcuData.bundled());
      // Still works after re-init.
      expect(IcuPluralRules.cardinal('fr').category(1), IcuPluralCategory.one);
    });

    test('preloadLocale is idempotent for bundled-covered locales', () async {
      await IcuKit.init();
      await IcuKit.preloadLocale('en');
      await IcuKit.preloadLocale('en'); // second call is a no-op
      // Formatters still work.
      expect(
        IcuPluralRules.cardinal('en').category(2),
        IcuPluralCategory.other,
      );
    });

    test(
      'preloadLocale on a bundled-only setup does NOT fail for any locale',
      () async {
        await IcuKit.init(data: IcuData.bundled());
        // Bundled (locales: null) covers every locale → preload short-circuits.
        await IcuKit.preloadLocale('ja');
        await IcuKit.preloadLocale('th');
        await IcuKit.preloadLocale('ar-SA');
      },
    );
  });

  group('IcuData.lazy — resolve through tree', () {
    test('lazy with bytes source preloads successfully', () async {
      // The bytes don't need to be real CLDR for this test — the resolver
      // caches them under (source, locale) and constructs an FFI provider
      // only when providerFor is called. The `init` itself doesn't decode.
      // (We don't call providerFor here — that would attempt to decode.)
      final blob = Uint8List.fromList([1, 2, 3]).buffer;
      final src = IcuDataSource.bytes(blob);
      await IcuKit.init(
        data: IcuData.composite([
          IcuData.bundled(locales: ['en']),
          IcuData.lazy(src),
        ]),
      );
      // Bundled branch covers en — no preload needed.
      await IcuKit.preloadLocale('en');
      expect(IcuPluralRules.cardinal('en').category(1), IcuPluralCategory.one);
    });
  });

  group('Locale gating via BundledIcuData(locales:)', () {
    test(
      'BundledIcuData with explicit locale list rejects uncovered locales',
      () async {
        // BundledIcuData(locales: ['en']) tells the resolver: "only en is
        // covered by the bundled layer." Asking for fr without a fallback
        // (no composite layer that handles it) → format-time error.
        await IcuKit.init(data: IcuData.bundled(locales: ['en']));
        expect(
          () => IcuPluralRules.cardinal('fr'),
          throwsA(isA<IcuDataError>()),
        );
        // But en still works.
        expect(
          IcuPluralRules.cardinal('en').category(1),
          IcuPluralCategory.one,
        );
      },
    );

    test('BundledIcuData(locales: null) covers every locale', () async {
      // The default — no restriction.
      await IcuKit.init(data: IcuData.bundled());
      expect(IcuPluralRules.cardinal('en').category(1), IcuPluralCategory.one);
      expect(
        IcuPluralRules.cardinal('zh-Hant').category(1),
        isA<IcuPluralCategory>(),
      );
    });
  });

  // Restore default state for other test files that may run after this one.
  tearDownAll(() async {
    await IcuKit.init();
  });
}
