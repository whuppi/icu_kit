import 'icu_data_source.dart';

/// The runtime data policy: which CLDR data icu_kit serves, and how loudly
/// a missing locale fails. This is NOT a size lever — binary size is a build
/// choice (`bundleCldrData` native / `setup --lean` web). See the README's
/// "Bundle size" section for how the two relate.
///
/// Pass to `IcuKit.init` via the `data:` argument:
///
/// ```dart
/// // Default — serve every baked locale (most apps).
/// await IcuKit.init();
///
/// // Serve ONLY these locales; any other throws loudly. A correctness
/// // guard, not a size change: the binary still holds every locale.
/// await IcuKit.init(data: IcuData.bundled(locales: ['en', 'fr', 'ja']));
///
/// // Lazy — load per-locale postcards on demand (the lean path).
/// await IcuKit.init(data: IcuData.lazy(IcuDataSource.assets(load: rootBundle.load)));
///
/// // Composite — one call that runs unchanged on both fat and lean binaries.
/// await IcuKit.init(data: IcuData.composite([
///   IcuData.bundled(locales: ['en']),
///   IcuData.lazy(IcuDataSource.assets(load: rootBundle.load)),
/// ]));
/// ```
sealed class IcuData {
  const IcuData();

  /// Serve CLDR data baked into the binary at compile time. Does NOT change
  /// binary size — that is the build's `bundleCldrData` flag. This
  /// constructor only decides which baked locales are served.
  ///
  /// If [locales] is `null`, every baked locale is available (the default
  /// for a `bundleCldrData: true` build, the pubspec default). Pass an
  /// explicit list to serve only those locales: a request for any other
  /// throws loudly instead of silently falling back to root data. The
  /// binary is unchanged either way.
  ///
  /// **Build flag interaction:**
  ///   * `bundleCldrData: true` (default) + this constructor → works
  ///   * `bundleCldrData: false` + this constructor → throws
  ///     `IcuMissingDataError` on first format. The build is lean; you
  ///     must use [IcuData.lazy] or [IcuData.composite] (with at least
  ///     one [IcuData.lazy] source) to actually have data.
  factory IcuData.bundled({List<String>? locales}) = BundledIcuData;

  /// Per-locale CLDR data loaded on demand from [source].
  ///
  /// First format-call per locale fetches from the source; subsequent
  /// calls hit an in-memory cache. Build with `bundleCldrData: false`
  /// in pubspec for the smallest possible binary.
  ///
  /// [fallbackLocale] is consulted when the requested locale isn't
  /// available from [source] (offline, missing slice, etc.). Defaults to
  /// `null` — missing locales throw `IcuMissingDataError`. Set to
  /// e.g. `'en'` for graceful degradation.
  factory IcuData.lazy(IcuDataSource source, {String? fallbackLocale}) =
      LazyIcuData;

  /// Tries each source in order; the first that resolves the requested
  /// locale wins. Walks the list left-to-right per lookup.
  ///
  /// The one policy that runs unchanged on **both** binaries: on a fat
  /// binary the [IcuData.bundled] tier serves and the [IcuData.lazy] tier stays cold; on a
  /// lean binary the [IcuData.bundled] tier is inert (its compiled data does not
  /// exist) and the [IcuData.lazy] postcards serve. That is what lets a single
  /// `init(...)` call work either way.
  factory IcuData.composite(List<IcuData> sources) = CompositeIcuData;
}

/// Baked-in CLDR data. See [IcuData.bundled].
final class BundledIcuData extends IcuData {
  /// See [IcuData.bundled].
  const BundledIcuData({this.locales});

  /// Locales to serve; null means all compiled-in locales.
  final List<String>? locales;
}

/// Lazy-loaded CLDR data via [IcuDataSource]. See [IcuData.lazy].
final class LazyIcuData extends IcuData {
  /// See [IcuData.lazy].
  const LazyIcuData(this.source, {this.fallbackLocale});

  /// Where postcard blobs are loaded from.
  final IcuDataSource source;

  /// Locale served when the requested one can't be loaded.
  final String? fallbackLocale;
}

/// Tiered CLDR data — first source that resolves wins. See [IcuData.composite].
final class CompositeIcuData extends IcuData {
  /// See [IcuData.composite].
  const CompositeIcuData(this.sources);

  /// Tiers tried left-to-right per lookup.
  final List<IcuData> sources;
}
