// CHARTER — this suite alone proves the LEAN binary end to end, the one
// flavor the main suite (always fat) can never exercise. This package's
// pubspec flips the single switch (`bundleCldrData: false`), so the build
// hook produces icu_capi WITHOUT compiled data, and:
//
//   (a) the flavor probe DETECTS the lean binary — hasCompiledData is
//       false, with no dart-define telling it so;
//   (b) init() without lazy data throws IcuMissingDataError AT INIT —
//       the old half-flipped-switch failure (missing-symbol crash at the
//       first format call) is dead by construction;
//   (c) the postcard/provider arm carries real formatting on the lean
//       binary: en postcard in, correctly grouped decimal out.
//
// Diet: the public icu_kit surface + the repo's corpus postcards.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

ByteBuffer _loadPostcard(String locale) {
  // CWD is this fixture package's root (test_fixtures/lean_smoke/).
  final f = File('../../test/_corpus/postcards/${locale}_minimal.postcard');
  if (!f.existsSync()) {
    throw StateError(
      'Postcard fixture missing: ${f.path}\n'
      'Run `fvm dart run tool/regen_test_postcards.dart` from the repo root.',
    );
  }
  return f.readAsBytesSync().buffer;
}

void main() {
  test('the probe detects the lean binary — no define, ground truth', () {
    expect(IcuKit.hasCompiledData, isFalse);
  });

  test('init without lazy data fails AT INIT, actionably', () {
    expect(
      () => IcuKit.init(),
      throwsA(
        isA<IcuMissingDataError>().having(
          (e) => e.message,
          'message',
          contains('LEAN'),
        ),
      ),
    );
  });

  test('postcards carry real formatting on the lean binary', () async {
    await IcuKit.init(
      data: IcuData.lazy(IcuDataSource.bytes(_loadPostcard('en'))),
    );
    await IcuKit.preloadLocale('en');

    expect(
      IcuNumberFormat.decimal(locale: 'en').format(1234567.89),
      '1,234,567.89',
    );
    expect(IcuPluralRules.cardinal('en').category(1), IcuPluralCategory.one);
  });

  test('uncovered locale on the lean binary throws, never garbles', () async {
    await IcuKit.init(
      data: IcuData.lazy(IcuDataSource.bytes(_loadPostcard('en'))),
    );
    await IcuKit.preloadLocale('en');

    expect(
      () => IcuNumberFormat.decimal(locale: 'ja').format(1),
      throwsA(isA<IcuError>()),
    );
  });

  // A full BundledIcuData() layer in a composite must be INERT on the lean
  // binary — it resolves to compiled data, which doesn't exist here, so the
  // lazy layer has to serve instead. Before the resolver learned to gate
  // the bundled layer on the detected flavor, this config called a
  // compiled-data-only FFI symbol and died with "symbol not found" — the
  // exact bug example_lean surfaced. Pure-lazy (the tests above) never hit
  // it; the composite is the portable production shape (README §"Bundle
  // size" Configuration 4).
  test(
    'composite([BundledIcuData(), lazy]) serves from lazy on lean',
    () async {
      await IcuKit.init(
        data: IcuData.composite([
          const BundledIcuData(),
          IcuData.lazy(IcuDataSource.bytes(_loadPostcard('en'))),
        ]),
      );
      await IcuKit.preloadLocale('en');

      expect(
        IcuNumberFormat.decimal(locale: 'en').format(1234567.89),
        '1,234,567.89',
      );
    },
  );
}
