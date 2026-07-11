import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale fallback chain — STABLE.
///
/// Generates the chain of locales ICU4X tries when looking up CLDR data
/// for a given locale. Use case: an app that builds its own resource
/// pipeline (translations, region data, etc.) and wants the same fallback
/// behavior as ICU4X uses internally.
///
/// Example:
///
/// ```dart
/// final fb = IcuLocaleFallbacker();
/// fb.chain('en-Latn-US').toList();
/// // ['en-Latn-US', 'en-US', 'en']
/// ```
final class IcuLocaleFallbacker {
  IcuLocaleFallbacker._(this._ffi);

  /// Create a fallbacker using [priority] to order the chain.
  ///
  /// Throws [IcuDataError] when fallback data is unavailable.
  factory IcuLocaleFallbacker({
    IcuFallbackPriority priority = IcuFallbackPriority.language,
  }) {
    try {
      final inner = dispatch.localeFallbackerDefault();
      final config = icu.LocaleFallbackConfig(
        priority: switch (priority) {
          IcuFallbackPriority.language => icu.LocaleFallbackPriority.language,
          IcuFallbackPriority.region => icu.LocaleFallbackPriority.region,
        },
      );
      return IcuLocaleFallbacker._(inner.forConfig(config));
    } catch (e) {
      throw IcuDataError(
        'Fallbacker unavailable: $e',
        marker: 'LocaleFallbacker',
      );
    }
  }
  final icu.LocaleFallbackerWithConfig _ffi;

  /// Iterate the fallback chain for [locale], starting with [locale]
  /// itself.
  ///
  /// Each step represents one less-specific locale ICU4X would try when
  /// looking up data. The chain ends when ICU4X has no more fallbacks —
  /// the last element is the broadest language root reachable (e.g.
  /// `'en'` for `'en-Latn-US'`, `'zh-Hant'` for `'zh-Hant-TW'`).
  ///
  /// ICU4X's fallback algorithm does NOT explicitly yield the root
  /// locale `'und'` — it stops when the iterator returns null.
  Iterable<String> chain(String locale) sync* {
    final loc = IcuLocale.parse(locale);
    yield locale;
    final iter = _ffi.fallbackForLocale(loc.ffi);
    while (iter.moveNext()) {
      final next = iter.current.asBcp47;
      if (next.isEmpty) return;
      yield next;
    }
  }
}

/// Priority mode for the locale fallback algorithm.
///
///   * `language` (default) — fall back to the parent language first
///     (en-US-CA → en-US → en → und)
///   * `region` — fall back keeping the region first (en-US-CA → en-US-001
///     → und-US-CA → und-US → und). Use for region-specific data lookups
///     (currency, units of measure).
enum IcuFallbackPriority {
  /// Fall back to the parent language first (en-US-CA → en-US → en →
  /// und) — the default.
  language,

  /// Keep the region while falling back (en-US-CA → en-US-001 →
  /// und-US-CA → und-US → und).
  region,
}
