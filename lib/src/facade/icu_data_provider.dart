// The low-level primitive behind IcuData.lazy: it wraps a sliced CLDR data
// blob (a "postcard") so ICU4X opaques read locale data at runtime instead
// of from the compiled-in set. Most apps never touch it directly —
// IcuKit.init(data: IcuData.lazy(...)) constructs and threads providers for
// you. Reach for it only to feed a `*WithProvider` binding by hand. It does
// not shrink a fat binary; the binary size lever is the build (`bundleCldrData`).
//
// Generate a postcard with the slice tool, sized by marker preset:
//
//   dart run icu_kit:slice --locales=en,fr --markers=format-core \
//     --out=assets/icu/app_data.postcard
//
// Then, at app start:
//
//   final bytes = await rootBundle.load('assets/icu/app_data.postcard');
//   final provider = IcuDataProvider.fromBytes(bytes.buffer);
//
// Pass `provider` to any ICU4X opaque with a `*WithProvider` constructor in
// the generated bindings. Dispatch routes every facade through the provider
// arm on a lean binary, so lazy data works for every facade.

import 'dart:typed_data';

import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';

/// Custom CLDR data provider — STABLE.
///
/// Wraps a postcard blob produced by the slice tool (`icu_kit:slice`). Most
/// apps don't need this; on a fat binary the default `compiled_data` provider
/// built into icu_capi is used implicitly by every facade.
final class IcuDataProvider {
  IcuDataProvider._(this._ffi);

  /// Construct a data provider from a postcard blob's bytes.
  ///
  /// Pass the [ByteBuffer] from a `Flutter.rootBundle.load()` of an
  /// asset, OR from `File.readAsBytes()` plus `.buffer`.
  factory IcuDataProvider.fromBytes(ByteBuffer bytes) {
    try {
      return IcuDataProvider._(icu.DataProvider.fromByteSlice(bytes));
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Failed to construct DataProvider from blob bytes: $e',
        marker: 'DataProvider.fromByteSlice',
      );
    }
  }
  final icu.DataProvider _ffi;

  /// The underlying FFI handle. INTERNAL — exposed only for facades that
  /// take a custom provider via `*WithProvider` constructors. Consumers
  /// should not call this directly.
  icu.DataProvider get ffi => _ffi;
}
