import 'package:logging/logging.dart';

import 'flavor_probe.dart';
import '../../data/icu_data_resolver.dart';
import '../../data/icu_data.dart';
import '../../errors/icu_error.dart';
import 'bindings/lib.g.dart' as icu;

final _log = Logger('icu_kit');

/// One-time initialization for icu_kit.
///
/// Native: no native loading is required (the build hook bundles
/// `libicu_capi` and Dart's `@Native` resolves on first FFI call), but
/// [IcuKit.init] still configures the data resolver based on the `data` argument.
///
/// Web: see `web.dart`. Same public surface.
class IcuKit {
  IcuKit._();

  static IcuDataResolver? _resolver;

  /// Module URL is web-only; provided here as a getter that returns null
  /// so apps can do `IcuKit.moduleUrl ??= ...` unconditionally if they
  /// want without branching on platform.
  static String? get moduleUrl => null;
  static set moduleUrl(String? value) {
    // Ignored on native.
  }

  /// Whether the linked binary carries the full compiled CLDR.
  ///
  /// DETECTED, not declared: the probe resolves one compiled-data-gated
  /// FFI symbol, so this reflects the binary the build hook actually
  /// produced — `true` for the default build, `false` when the consumer
  /// set `bundleCldrData: false` in pubspec user_defines (the ONLY
  /// switch; there is no dart-define to keep in sync).
  static bool get hasCompiledData => binaryHasCompiledData();

  /// Bootstrap icu_kit. Call once at app startup before any facade is used.
  ///
  /// [data] determines how CLDR data is loaded:
  ///   * Default ([IcuData.bundled]) — full baked-in data. Requires the
  ///     default fat binary (`bundleCldrData: true` in pubspec).
  ///   * [IcuData.lazy] — load per-locale postcards on demand. Pair with
  ///     `bundleCldrData: false` for the smallest binary.
  ///   * [IcuData.composite] — tiered fallback.
  ///
  /// Validation — against the DETECTED binary flavor ([hasCompiledData]),
  /// so a lean binary can never be mistaken for a fat one:
  ///   * lean binary + bundled-only data → throws [IcuMissingDataError]
  ///   * fat binary + lazy-only data → logs a warning (CLDR ships
  ///     twice; set `bundleCldrData: false` to remove the bake-in)
  ///
  /// Calling [init] again replaces the active data, clearing the
  /// per-locale cache.
  static Future<void> init({IcuData data = const BundledIcuData()}) async {
    final r = _resolver;
    if (r == null) {
      _resolver = IcuDataResolver(
        data: data,
        bundleCldrData: binaryHasCompiledData(),
      );
    } else {
      r.replace(data);
    }
    _validate();
  }

  /// Asynchronously load CLDR data for [locale] if the active [IcuData]
  /// is lazy. No-op for bundled data.
  ///
  /// After this completes, every formatter for [locale] constructs
  /// synchronously. Throws [IcuMissingDataError] if no source resolves
  /// bytes for [locale].
  ///
  /// Idempotent — calling for an already-loaded locale is a no-op.
  static Future<void> preloadLocale(String locale) async {
    final r = _resolver;
    if (r == null) {
      throw StateError(
        'IcuKit.init() must be awaited before IcuKit.preloadLocale(). '
        'Add `await IcuKit.init();` to your main() before runApp().',
      );
    }
    await r.preload(locale);
  }

  /// Look up the FFI provider for a locale. INTERNAL — facades use this
  /// to pick between compiled-data and `*WithProvider` constructors.
  ///
  /// Returns `null` if the active [IcuData] indicates "use compiled
  /// data" for this locale. Throws [IcuMissingDataError] if the locale
  /// hasn't been preloaded (lazy mode).
  static icu.DataProvider? providerFor(String locale) {
    final r = _resolver;
    if (r == null) {
      // init() not called yet. For ergonomic reasons, we treat this as
      // "use compiled data" rather than throwing — matches the historical
      // shape where IcuKit.init() was a no-op on native.
      return null;
    }
    return r.providerFor(locale);
  }

  static void _validate() {
    final r = _resolver!;
    if (!r.bundleCldrData && !r.hasLazyLayer) {
      throw IcuMissingDataError(
        'This icu_kit binary is LEAN (built with bundleCldrData: false — '
        'detected: the compiled-data symbols are absent), but '
        'IcuKit.init() was called without a lazy IcuData source. '
        'Either:\n'
        '  - set `bundleCldrData: true` in your pubspec.yaml user_defines '
        '(or remove the override — true is the default), OR\n'
        '  - pass `data: IcuData.lazy(...)` (or `IcuData.composite([..., '
        'IcuData.lazy(...)]))` to IcuKit.init.',
        locale: '<any>',
      );
    }
    if (r.bundleCldrData && r.hasLazyLayer && !r.hasBundledLayer) {
      _log.warning(
        'This icu_kit binary carries the full compiled CLDR, but '
        'IcuKit.init() was called with a lazy-only IcuData. The binary '
        "ships ~21 MB of CLDR data that's never used. To remove the "
        'bake-in, set `bundleCldrData: false` in your pubspec.yaml under '
        'hooks > user_defines > icu_kit.',
      );
    }
  }
}
