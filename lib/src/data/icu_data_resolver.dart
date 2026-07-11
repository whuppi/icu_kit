import 'dart:typed_data';

import '../errors/icu_error.dart';
import '../runtime/bindings.dart' as icu;
import 'icu_data.dart';
import 'icu_data_source.dart';

/// The data resolver — shared across platforms via the unified bindings.
///
/// Holds the active [IcuData] for the running app and translates each
/// requested locale into either:
///   - `null` (use compiled data — `*` constructor on FFI bindings)
///   - an [icu.DataProvider] handle (use `*WithProvider` constructor)
///
/// One resolver per app. Lives on `IcuKit`; facades read it through
/// `IcuKit.providerFor`.
class IcuDataResolver {
  /// Create the resolver over [data]; [bundleCldrData] states whether
  /// the binary carries compiled-in CLDR data.
  IcuDataResolver({required IcuData data, required this.bundleCldrData})
    : _data = data;
  IcuData _data;

  /// Whether the underlying binary was built with `compiled_data` enabled.
  /// Used by `IcuKit` to validate the configuration matrix.
  bool bundleCldrData;

  // Cache: locale → resolved provider. `null` means "compiled data".
  // The map's presence-of-key vs absence distinguishes "we know about this
  // locale" (preloaded) from "first time we've seen it".
  final Map<String, icu.DataProvider?> _cache = {};

  // Cache for blob-source providers — once we've built an `icu.DataProvider`
  // from a postcard's bytes, reuse it for every locale that hits that blob.
  final Map<int, icu.DataProvider> _providerByBytesIdentity = {};

  /// Replace the active [IcuData]. Clears the cache.
  void replace(IcuData data) {
    _data = data;
    _cache.clear();
    _providerByBytesIdentity.clear();
  }

  /// True iff this [IcuData] (anywhere in its tree) has at least one
  /// [LazyIcuData] layer.
  bool get hasLazyLayer => _hasLazy(_data);

  /// True iff this [IcuData] (anywhere in its tree) has at least one
  /// [BundledIcuData] layer.
  bool get hasBundledLayer => _hasBundled(_data);

  bool _hasLazy(IcuData data) => switch (data) {
    BundledIcuData() => false,
    LazyIcuData() => true,
    CompositeIcuData(:final sources) => sources.any(_hasLazy),
  };

  bool _hasBundled(IcuData data) => switch (data) {
    BundledIcuData() => true,
    LazyIcuData() => false,
    CompositeIcuData(:final sources) => sources.any(_hasBundled),
  };

  /// Synchronously look up the FFI provider for [locale]. Returns `null`
  /// if the active [IcuData] indicates "use compiled data" for this locale.
  ///
  /// Throws [IcuMissingDataError] if the locale hasn't been preloaded
  /// (lazy mode requires `await IcuKit.preloadLocale(locale)` before the
  /// first sync facade call for that locale).
  icu.DataProvider? providerFor(String locale) {
    if (_cache.containsKey(locale)) return _cache[locale];

    // Walk the tree synchronously. If any branch is `bundled`, return
    // null (compiled data). If a `lazy` branch is hit and not yet
    // preloaded, throw.
    try {
      final result = _walkSync(_data, locale);
      _cache[locale] = result;
      return result;
    } on _NotInLayer {
      // No layer in the tree covered the locale. Surface the typed
      // missing-data error the public contract documents.
      throw IcuMissingDataError(
        'No CLDR data for locale "$locale". '
        'Call `await IcuKit.preloadLocale("$locale")` before constructing '
        'facades for this locale, or set fallbackLocale on IcuData.lazy.',
        locale: locale,
      );
    }
  }

  icu.DataProvider? _walkSync(IcuData data, String locale) {
    switch (data) {
      case BundledIcuData(:final locales):
        // A bundled layer resolves to compiled data — which only EXISTS on
        // a bundled binary. On a lean binary the layer covers nothing, so
        // it must fall through (in a composite the next layer serves; alone,
        // providerFor surfaces IcuMissingDataError). This is what makes
        // `composite([BundledIcuData(), lazy])` portable across both
        // flavors: bundled serves on fat, lazy serves on lean.
        if (bundleCldrData && (locales == null || locales.contains(locale))) {
          return null;
        }
        throw _NotInLayer();
      case LazyIcuData(:final source, :final fallbackLocale):
        // Lazy-loaded blobs need pre-resolved bytes (see preload).
        // The source's `resolve(locale)` is async; we expect the user
        // to have called `IcuKit.preloadLocale(locale)` first.
        // Returns the FFI provider for the cached blob, or signals
        // _NotInLayer when this lazy source doesn't cover the locale —
        // the composite walker then tries the next layer.
        return _resolveLazy(source, locale, fallbackLocale);
      case CompositeIcuData(:final sources):
        for (final s in sources) {
          try {
            return _walkSync(s, locale);
          } on _NotInLayer {
            continue;
          }
        }
        throw _NotInLayer();
    }
  }

  icu.DataProvider? _resolveLazy(
    IcuDataSource source,
    String locale,
    String? fallbackLocale,
  ) {
    final preloaded = _preloadedBytes[(source, locale)];
    if (preloaded == null) {
      if (fallbackLocale != null) {
        final fb = _preloadedBytes[(source, fallbackLocale)];
        if (fb != null) return _ffiFor(fb);
      }
      // This lazy layer has nothing for the locale (no preload, no
      // usable fallback). Signal _NotInLayer so a parent composite
      // walks past us to the next sibling instead of mistaking
      // "this layer is empty" for "no source has the data."
      throw const _NotInLayer();
    }
    return _ffiFor(preloaded);
  }

  icu.DataProvider _ffiFor(ByteBuffer bytes) {
    return _providerByBytesIdentity.putIfAbsent(
      identityHashCode(bytes),
      () => icu.DataProvider.fromByteSlice(bytes),
    );
  }

  // Preload state — populated by [preload] below.
  final Map<(IcuDataSource, String), ByteBuffer> _preloadedBytes = {};

  /// Asynchronously load (and cache) the bytes for [locale]. After this
  /// completes, [providerFor] returns synchronously.
  ///
  /// Walks the [IcuData] tree, calling `IcuDataSource.resolve(locale)` on
  /// every lazy layer. The first source that returns non-null wins —
  /// matches the priority order [providerFor] uses.
  ///
  /// No-op if every layer is bundled (no lazy work needed). If no layer
  /// resolves and the locale isn't covered by a bundled layer, throws
  /// [IcuMissingDataError].
  Future<void> preload(String locale) async {
    if (_cache.containsKey(locale)) return;

    final outcome = await _preloadInTree(_data, locale);
    if (outcome == _PreloadOutcome.bundled) {
      _cache[locale] = null;
    } else if (outcome == _PreloadOutcome.lazyResolved) {
      // _preloadedBytes was populated; providerFor will fetch from there.
    } else {
      throw IcuMissingDataError(
        'No CLDR data for locale "$locale" — none of the configured '
        'IcuData sources resolved bytes for this locale.',
        locale: locale,
      );
    }
  }

  Future<_PreloadOutcome> _preloadInTree(IcuData data, String locale) async {
    switch (data) {
      case BundledIcuData(:final locales):
        // On a lean binary a bundled layer covers nothing (no compiled
        // data), so preload must NOT report it as covered — otherwise a
        // composite's lazy layer is skipped and the postcard never loads.
        if (bundleCldrData && (locales == null || locales.contains(locale))) {
          return _PreloadOutcome.bundled;
        }
        return _PreloadOutcome.notFound;
      case LazyIcuData(:final source):
        if (_preloadedBytes.containsKey((source, locale))) {
          return _PreloadOutcome.lazyResolved;
        }
        final bytes = await source.resolve(locale);
        if (bytes == null) return _PreloadOutcome.notFound;
        _preloadedBytes[(source, locale)] = bytes;
        return _PreloadOutcome.lazyResolved;
      case CompositeIcuData(:final sources):
        for (final s in sources) {
          final outcome = await _preloadInTree(s, locale);
          if (outcome != _PreloadOutcome.notFound) return outcome;
        }
        return _PreloadOutcome.notFound;
    }
  }
}

enum _PreloadOutcome { bundled, lazyResolved, notFound }

class _NotInLayer implements Exception {
  const _NotInLayer();
}
