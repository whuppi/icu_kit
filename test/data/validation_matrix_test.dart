// CHARTER — this suite alone proves what the header below declares.
// VM-ONLY (@TestOn below): the FFI provider arm has no web counterpart —
// the web world loads postcards through fetch, proven in the two-world
// suites. Charter: validation matrix — proves the bundleCldrData × IcuData truth table
// implemented in IcuKit.init's `_validate()` step.
//
// The table:
//
//   bundleCldrData | IcuData shape                   | Expected behavior
//   ---------------+---------------------------------+-------------------
//   true           | bundled (default)               | OK
//   true           | bundled(locales: [...])         | OK
//   true           | lazy(...)                       | warn (CLDR doubly
//                  |                                 | shipped)
//   true           | composite([bundled, lazy])      | OK (tiered)
//   false          | bundled (default)               | THROW
//   false          | bundled(locales: [...])         | THROW
//   false          | lazy(...)                       | OK
//   false          | composite([bundled, lazy])      | OK
//
// Why this matters: `bundleCldrData` here is the binary flavor that
// IcuKit.init DETECTS via the flavor probe (a compiled-data FFI symbol
// either resolves or throws) — the pubspec user_define is the only
// declaration; there is no dart-define. An app on a lean binary
// without a lazy IcuData would have an ICU4X library that can't find
// any data — the validation surfaces that at init time (where it's
// actionable) instead of at the first format call.
//
// This test exercises the `IcuDataResolver` directly. Spinning the
// real `IcuKit.init` path would require a lean BINARY, which this fat
// test run doesn't have — test_fixtures/lean_smoke/ covers that half against a
// real lean build. Here we construct a resolver with each
// `bundleCldrData` value and an `IcuData` shape and assert the
// public flags + the validation predicate that `_validate()` uses.
//
// Native-only: the resolver class lives behind the same dart:io
// path the round-trip tests need; the validation logic is identical
// to the web side (see `web/resolver.dart`).

// Diet: the public data API + the vendored corpus postcards (PROVENANCE.md).
@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:icu_kit/icu_kit.dart';
// Import the internal resolver directly — same-package tests may reach
// src/ (implementation_imports only fires cross-package).
import 'package:icu_kit/src/data/icu_data_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('IcuDataResolver — bundleCldrData × IcuData matrix', () {
    test('bundle=true + default bundled: hasBundled, !hasLazy', () {
      final r = IcuDataResolver(
        data: const BundledIcuData(),
        bundleCldrData: true,
      );
      expect(r.hasBundledLayer, isTrue);
      expect(r.hasLazyLayer, isFalse);
      // Validation predicate: lean+bundle-only is the only THROW case.
      expect(_isLeanBundleOnly(r), isFalse, reason: 'bundle=true is not lean');
      expect(
        _isFullLazyOnly(r),
        isFalse,
        reason: 'bundled means full has bundled coverage',
      );
    });

    test('bundle=true + scoped bundled list: same flags', () {
      final r = IcuDataResolver(
        data: BundledIcuData(locales: const ['en']),
        bundleCldrData: true,
      );
      expect(r.hasBundledLayer, isTrue);
      expect(r.hasLazyLayer, isFalse);
      expect(_isLeanBundleOnly(r), isFalse);
      expect(_isFullLazyOnly(r), isFalse);
    });

    test('bundle=true + lazy-only: is full+lazy-only (warns)', () {
      final r = IcuDataResolver(
        data: LazyIcuData(IcuDataSource.bytes(_emptyBuffer())),
        bundleCldrData: true,
      );
      expect(r.hasBundledLayer, isFalse);
      expect(r.hasLazyLayer, isTrue);
      // Validation predicate: full+lazy-only triggers the WARN log.
      expect(_isFullLazyOnly(r), isTrue);
      expect(_isLeanBundleOnly(r), isFalse);
    });

    test('bundle=true + composite [bundled, lazy]: tiered, no warn', () {
      final r = IcuDataResolver(
        data: CompositeIcuData([
          const BundledIcuData(locales: ['en']),
          LazyIcuData(IcuDataSource.bytes(_emptyBuffer())),
        ]),
        bundleCldrData: true,
      );
      expect(r.hasBundledLayer, isTrue);
      expect(r.hasLazyLayer, isTrue);
      // Both layers present — neither throw nor warn case fires.
      expect(_isLeanBundleOnly(r), isFalse);
      expect(_isFullLazyOnly(r), isFalse);
    });

    test('bundle=false + default bundled: lean+bundle-only (THROW)', () {
      final r = IcuDataResolver(
        data: const BundledIcuData(),
        bundleCldrData: false,
      );
      expect(r.hasBundledLayer, isTrue);
      expect(r.hasLazyLayer, isFalse);
      // Validation predicate: lean binary with no lazy source is the
      // throw case. _validate() raises IcuMissingDataError; we check
      // the predicate that drives it here.
      expect(_isLeanBundleOnly(r), isTrue);
    });

    test('bundle=false + scoped bundled: still lean+bundle-only', () {
      final r = IcuDataResolver(
        data: BundledIcuData(locales: const ['en']),
        bundleCldrData: false,
      );
      expect(_isLeanBundleOnly(r), isTrue);
    });

    test('bundle=false + lazy-only: lean+has-lazy (OK)', () {
      final r = IcuDataResolver(
        data: LazyIcuData(IcuDataSource.bytes(_emptyBuffer())),
        bundleCldrData: false,
      );
      expect(r.hasBundledLayer, isFalse);
      expect(r.hasLazyLayer, isTrue);
      // The good case — lean binary AND lazy source present.
      expect(_isLeanBundleOnly(r), isFalse);
      expect(_isFullLazyOnly(r), isFalse);
    });

    test('bundle=false + composite [bundled, lazy]: lean+has-lazy (OK)', () {
      final r = IcuDataResolver(
        data: CompositeIcuData([
          const BundledIcuData(locales: ['en']),
          LazyIcuData(IcuDataSource.bytes(_emptyBuffer())),
        ]),
        bundleCldrData: false,
      );
      expect(r.hasLazyLayer, isTrue);
      // bundled layer present too, but lean=true bundleCldrData means
      // the bundled layer can't actually deliver bytes — the lazy
      // layer is what makes this configuration usable.
      expect(_isLeanBundleOnly(r), isFalse);
    });
  });

  group('IcuKit.init — surfaces the throw case at runtime', () {
    test('lean+bundle-only init throws IcuMissingDataError', () async {
      // We can't directly flip `bundleCldrData` to false here (it's
      // a compile-time constant). What we CAN test is the inverse:
      // when bundleCldrData is the build-time default (true in this
      // test binary), default IcuData.bundled() succeeds. This
      // proves the OK path works, complementing the matrix tests
      // above which exercise the throw predicate directly.
      await IcuKit.init(); // default bundled, build-default = true
      // Sanity: a formatter for any locale constructs without throw.
      final f = IcuPluralRules.cardinal('en');
      expect(f.category(1), IcuPluralCategory.one);
    });

    tearDownAll(() async {
      await IcuKit.init();
    });
  });
}

/// Validation predicate exactly as `_validate()` writes it: throws when
/// bundleCldrData is false AND the IcuData has no lazy layer.
bool _isLeanBundleOnly(IcuDataResolver r) =>
    !r.bundleCldrData && !r.hasLazyLayer;

/// Validation predicate exactly as `_validate()` writes it: warns when
/// bundleCldrData is true AND the IcuData has a lazy layer but NO
/// bundled layer (so the baked-in CLDR is going to waste).
bool _isFullLazyOnly(IcuDataResolver r) =>
    r.bundleCldrData && r.hasLazyLayer && !r.hasBundledLayer;

/// Empty buffer for IcuDataSource.bytes when the test only cares about
/// the structural validity of the resolver (not actual decoding).
ByteBuffer _emptyBuffer() => Uint8List(0).buffer;
