// Binary-flavor probe — asks the linked icu_capi library whether it
// carries compiled CLDR data, by resolving one compiled-data-gated FFI
// symbol. Ground truth: the symbol either exists in the binary or it
// doesn't; no build flag can lie about it.
//
// This is what makes `bundleCldrData` a SINGLE-door setting: the
// pubspec user_define picks which binary the build hook produces, and
// the runtime DETECTS what it got — there is no second declaration to
// forget (build hooks cannot set dart-defines; this probe replaces the
// old `--dart-define=icu_kit.bundleCldrData` contract).

import 'dart:ffi' as ffi;

import '../../errors/icu_error.dart';

/// The probe target: `PluralRules::create_cardinal` is gated by
/// `#[cfg(feature = "compiled_data")]` in the vendored
/// `ffi/capi/src/pluralrules.rs` — one of the ~426 compiled-data gates.
/// It has existed since ICU4X 1.3 introduced compiled data and every
/// fat build exports it. Do NOT swap this for a niche symbol: the probe
/// must be present in every `compiled_data` build regardless of which
/// formatters a future feature-trim keeps.
///
/// The declared C signature is deliberately simplified — the probe only
/// takes the symbol's ADDRESS (never calls it), and `Native.addressOf`
/// doesn't check the signature against the native side.
@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Opaque>)>(
  symbol: 'icu4x_PluralRules_create_cardinal_mv1',
  assetId: 'package:icu_kit/src/runtime/native/bindings/lib.g.dart',
)
external ffi.Pointer<ffi.Void> _compiledDataProbe(ffi.Pointer<ffi.Opaque> l);

/// The baseline: `Locale::from_string` exists in EVERY flavor (fat and
/// lean, no feature gate). When even this fails to resolve, the library
/// isn't loaded at all — a missing-native-assets condition the probe
/// must NOT read as "lean binary", or every later FFI call dies with a
/// misleading error while the probe claims success.
@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Opaque>)>(
  symbol: 'icu4x_Locale_from_string_mv1',
  assetId: 'package:icu_kit/src/runtime/native/bindings/lib.g.dart',
)
external ffi.Pointer<ffi.Void> _baselineProbe(ffi.Pointer<ffi.Opaque> l);

bool? _cached;

/// True when the linked icu_capi binary was built with the
/// `compiled_data` cargo feature (the default, `bundleCldrData: true`);
/// false for the lean binary.
///
/// Resolving a missing `@Native` symbol throws a catchable
/// [ArgumentError] ("Couldn't resolve native function ... symbol not
/// found") — that catch IS the lean detection. Result is cached; the
/// binary can't change mid-process.
bool binaryHasCompiledData() {
  return _cached ??= _probe();
}

bool _probe() {
  try {
    ffi.Native.addressOf<
      ffi.NativeFunction<
        ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Opaque>)
      >
    >(_compiledDataProbe);
    return true;
  } on ArgumentError catch (e) {
    // Compiled-data symbol absent. Lean binary — or no binary at all.
    // Confirm the library is actually loaded before concluding "lean".
    try {
      ffi.Native.addressOf<
        ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Opaque>)
        >
      >(_baselineProbe);
    } on ArgumentError {
      throw IcuLoadError(
        'native',
        StateError(
          'icu_capi is not loaded: no native asset is registered for this '
          'process, so every FFI call would fail. Run from a resolved '
          'package (`dart pub get` first) so the build hook\'s asset '
          'mapping reaches the runtime. Probe error: $e',
        ),
      );
    }
    return false;
  }
}
