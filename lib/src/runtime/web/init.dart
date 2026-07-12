import 'dart:js_interop';

import 'package:logging/logging.dart';

import 'flavor_probe.dart';
import '../web_engine.dart';
// DEFERRED: the browser-Intl shim is compiled into a separate chunk and
// loaded ONLY when `init(webEngine: WebEngine.browserIntl)` runs, so
// ICU4X-mode web bundles never ship it.
import '../web_intl/install.dart' deferred as browser_intl;
import '../../data/icu_data_resolver.dart';
import '../../data/icu_data.dart';
import '../../errors/icu_error.dart';

final _log = Logger('icu_kit');

/// One-time async load of the icu_kit JavaScript module shipped under
/// the consuming app's `web/icu_kit/lib/index.mjs` (placed there by
/// `flutter pub run icu_kit:setup`).
///
/// Call once at app startup before any facade is constructed:
///
/// ```dart
/// import 'package:icu_kit/icu_kit.dart';
///
/// Future<void> main() async {
///   await IcuKit.init();   // or: IcuKit.init(data: IcuData.lazy(...))
///   runApp(MyApp());
/// }
/// ```
class IcuKit {
  IcuKit._();

  static JSObject? _module;
  static IcuDataResolver? _resolver;
  static bool? _hasCompiledData;

  // The web engine chosen by the FIRST init(). Fixed for the app lifetime and
  // the single source of truth for [engine]. Claimed synchronously in init()
  // (before any await), together with [_moduleLoad], so a concurrent or later
  // init() requesting a DIFFERENT engine is rejected rather than silently
  // handed this one. Cleared with [_moduleLoad] if the load fails.
  static WebEngine? _chosenEngine;

  // Latches the one-time module load. Every init() awaits this SAME future, so
  // concurrent calls share one load instead of racing to set _module /
  // _hasCompiledData. Set to null on a failed load so a later init() retries.
  static Future<void>? _moduleLoad;

  /// Which web engine is active: `'icu4x'` (default) or `'browser-intl'`
  /// (selected via `IcuKit.init(webEngine: WebEngine.browserIntl)`). On native
  /// this getter returns `'native'` — the surface is symmetric across the
  /// conditional import.
  static String get engine => switch (_chosenEngine) {
    WebEngine.browserIntl => 'browser-intl',
    WebEngine.icu4x || null => 'icu4x',
  };

  /// Module URL relative to the page that loads the app. Defaults to
  /// `'icu_kit/lib/index.mjs'` which matches what `flutter pub run icu_kit:setup`
  /// installs into the consumer's `web/` folder. Override if you put the
  /// assets somewhere else.
  static String moduleUrl = 'icu_kit/lib/index.mjs';

  /// Whether the loaded wasm carries the full compiled CLDR.
  ///
  /// DETECTED, not declared — the probe checks a compiled-data-gated
  /// export on the wasm the app actually loaded. `setup` installs the
  /// bundled wasm; `setup --lean` installs the lean one under the same
  /// name. Only available after [init] (the wasm must be loaded to be
  /// asked).
  static bool get hasCompiledData {
    final v = _hasCompiledData;
    if (v == null) {
      throw StateError(
        'IcuKit.hasCompiledData is only known after `await IcuKit.init()` '
        '(the wasm must be loaded to be probed).',
      );
    }
    return v;
  }

  /// Bootstrap icu_kit. Call once at app startup before any facade is used.
  ///
  /// On web this also loads the JS module. Safe to call repeatedly with the
  /// same [webEngine] (a later call just updates [data]); the engine is fixed
  /// by the first call.
  ///
  /// [data] determines how CLDR data is loaded:
  ///   * Default ([IcuData.bundled]) — full baked-in data (today's only
  ///     shipped wasm).
  ///   * [IcuData.lazy] — load per-locale postcards on demand.
  ///   * [IcuData.composite] — tiered fallback.
  ///
  /// [webEngine] picks the web engine: [WebEngine.icu4x] (default, full ICU4X)
  /// or [WebEngine.browserIntl] (the browser's built-in `Intl`, zero download —
  /// see [WebEngine.browserIntl] for the coverage trade). The browser engine's
  /// code is loaded lazily, only when selected.
  ///
  /// Validation runs against the DETECTED wasm flavor
  /// ([hasCompiledData]) — same single-door contract as native.
  ///
  /// Throws [IcuLoadError] if the JS module fails to load.
  /// Throws [IcuMissingDataError] if the wasm is lean and no lazy data
  /// is configured.
  /// Throws [IcuUnsupportedError] if [WebEngine.browserIntl] is paired with a
  /// per-locale [IcuData] (lazy / composite) — the browser owns the CLDR.
  /// Throws [StateError] if a later call requests a different [webEngine] than
  /// the first — the engine is fixed for the app lifetime.
  static Future<void> init({
    IcuData data = const BundledIcuData(),
    WebEngine webEngine = WebEngine.icu4x,
  }) async {
    // Per-call argument check — rejects the bad pairing regardless of whether
    // the module is already loaded (the browser owns the CLDR, so per-locale
    // data sources make no sense with it).
    if (webEngine == WebEngine.browserIntl && data is! BundledIcuData) {
      throw IcuUnsupportedError(
        'IcuData.lazy / IcuData.composite (per-locale data sources)',
        engine: 'browser-intl',
      );
    }

    // Claim the engine + capture the shared load with NO await between, so
    // Dart's single-threaded prologue makes it atomic: every init() reads a
    // consistent (_chosenEngine, _moduleLoad) pair. The first call fixes the
    // engine; a later/concurrent call either shares the exact same load or is
    // rejected for asking for a different engine — never silently switched.
    final Future<void> load;
    final chosen = _chosenEngine;
    if (chosen == null) {
      _chosenEngine = webEngine;
      load = _moduleLoad = _loadModule(webEngine);
    } else if (chosen != webEngine) {
      throw StateError(
        'IcuKit.init() was already called with WebEngine.${chosen.name}; the '
        'web engine is fixed for the app lifetime and cannot switch to '
        'WebEngine.${webEngine.name}. Call init() once at startup.',
      );
    } else {
      load = _moduleLoad!;
    }
    await load;

    final r = _resolver;
    if (r == null) {
      _resolver = IcuDataResolver(
        data: data,
        bundleCldrData: _hasCompiledData!,
      );
    } else {
      r.replace(data);
    }
    _validate();
  }

  // Loads the web module exactly once, latched by [_moduleLoad]. On failure it
  // clears the latch AND the engine claim so a later init() can retry (and
  // re-choose the engine), and normalizes any non-Icu throw into [IcuLoadError].
  static Future<void> _loadModule(WebEngine webEngine) async {
    try {
      if (webEngine == WebEngine.browserIntl) {
        await browser_intl.loadLibrary();
        _module = browser_intl.buildBrowserIntlModule();
        _hasCompiledData = true; // the browser owns the CLDR; always present
      } else {
        _module = await importModule(moduleUrl.toJS).toDart;
        // Probe the flavor off diplomat-wasm.mjs — the sibling the loaded
        // module's classes already import-cache. Resolve it as the sibling in
        // [moduleUrl]'s own directory, not by rewriting an assumed 'index.mjs'
        // filename, so an overridden [moduleUrl] still finds it.
        final dir = moduleUrl.substring(0, moduleUrl.lastIndexOf('/') + 1);
        _hasCompiledData = await wasmHasCompiledData('${dir}diplomat-wasm.mjs');
      }
    } catch (e) {
      _moduleLoad = null; // failed — let the next init() retry
      _chosenEngine = null;
      if (e is IcuError) rethrow;
      throw IcuLoadError('web', e);
    }
  }

  /// Asynchronously load CLDR data for [locale] if the active [IcuData]
  /// is lazy. No-op for bundled data.
  static Future<void> preloadLocale(String locale) async {
    final r = _resolver;
    if (r == null) {
      throw StateError(
        'IcuKit.init() must be awaited before IcuKit.preloadLocale().',
      );
    }
    await r.preload(locale);
  }

  /// Look up the JS provider for a locale. INTERNAL — facades use this.
  static JSObject? providerFor(String locale) {
    final r = _resolver;
    if (r == null) return null;
    final p = r.providerFor(locale);
    if (p == null) return null;
    // The shared resolver speaks the seam's DataProvider — which on web IS
    // the runtime/web mirror (a JSObject at runtime). The through-Object
    // cast is needed only because `dart analyze` resolves the seam to the
    // FFI type; it is a no-op in the compiled web program.
    return (p as Object) as JSObject;
  }

  /// The loaded JS module. Internal — facade types use this to look up
  /// classes. Throws if [init] hasn't been awaited yet.
  static JSObject get module {
    final m = _module;
    if (m == null) {
      throw IcuLoadError(
        'web',
        StateError(
          'IcuKit.init() must be awaited before any icu_kit API is used on web. '
          'Add `await IcuKit.init();` to your main() before runApp().',
        ),
      );
    }
    return m;
  }

  static void _validate() {
    final r = _resolver!;
    if (!r.bundleCldrData && !r.hasLazyLayer) {
      throw IcuMissingDataError(
        'The loaded icu_kit wasm is LEAN (detected: the compiled-data '
        'exports are absent), but IcuKit.init() was called without a '
        'lazy IcuData source. Either:\n'
        '  - install the full wasm (`flutter pub run icu_kit:setup`), OR\n'
        '  - pass `data: IcuData.lazy(...)` (or `IcuData.composite([..., '
        'IcuData.lazy(...)]))` to IcuKit.init.',
        locale: '<any>',
      );
    }
    if (r.bundleCldrData && r.hasLazyLayer && !r.hasBundledLayer) {
      _log.warning(
        'The loaded icu_kit wasm carries the full compiled CLDR, but '
        'IcuKit.init() was called with a lazy-only IcuData — the bundled '
        'CLDR ships in the wasm and is never used. Install the lean wasm '
        'instead (`flutter pub run icu_kit:setup --lean`, ~2 MB vs ~19 MB).',
      );
    }
  }
}
