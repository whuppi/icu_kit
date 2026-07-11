import 'dart:typed_data';

/// Where the bytes for one locale (or a multi-locale blob) come from.
///
/// Paired with `IcuData.lazy` to define how postcard data reaches the
/// runtime. Three forms cover every realistic source:
///
///   * [IcuDataSource.assets] — load `<prefix><locale>.postcard` via an
///     asset-loader callback you supply (typically `rootBundle.load` in
///     Flutter apps).
///   * [IcuDataSource.callback] — return the bytes for one locale however
///     you want (HTTP fetch, file read, encrypted store, anything).
///   * [IcuDataSource.bytes] — a single pre-computed blob already in memory
///     (e.g. one postcard covering all your app's locales).
abstract class IcuDataSource {
  /// Enable const constructors in subclasses.
  const IcuDataSource();

  /// Loads `<prefix><locale>.postcard` via an asset-loader callback.
  ///
  /// Pair with `dart run icu_kit:slice --locales=… --per-locale --out=assets/icu/`
  /// and add the directory to your pubspec's flutter assets.
  ///
  /// In a Flutter app:
  /// ```dart
  /// import 'package:flutter/services.dart' show rootBundle;
  ///
  /// IcuDataSource.assets(load: rootBundle.load);
  /// ```
  ///
  /// The callback receives the asset path (e.g. `'assets/icu/fr.postcard'`)
  /// and returns its bytes. icu_kit caches the result per locale, so the
  /// loader runs at most once per locale per session.
  ///
  /// Returns `null` from the callback (or throws) if the asset is missing —
  /// callers should guard with `IcuData.composite` if they need a fallback.
  factory IcuDataSource.assets({
    required Future<ByteData> Function(String key) load,
    String? prefix,
  }) = _AssetsSource;

  /// Returns bytes for one locale on demand. Use when [IcuDataSource.assets]
  /// doesn't fit — backend fetches, encrypted stores, custom caching, etc.
  ///
  /// The callback receives the locale tag (e.g. `'fr'`, `'ja-JP'`) and
  /// returns its postcard bytes (or `null` if the locale isn't available).
  /// icu_kit caches the result per locale.
  factory IcuDataSource.callback(
    Future<ByteBuffer?> Function(String locale) fetch,
  ) = _CallbackSource;

  /// A single in-memory blob covering one or more locales. Use when you
  /// already have the bytes (e.g. compiled in via `--out=app.postcard`
  /// then loaded once at startup).
  factory IcuDataSource.bytes(ByteBuffer bytes) = _BytesSource;

  /// Resolve bytes for a locale, or return `null` if this source can't
  /// provide them. Implementation detail — facades go through `IcuData`.
  Future<ByteBuffer?> resolve(String locale);
}

class _AssetsSource extends IcuDataSource {
  _AssetsSource({required this.load, String? prefix})
    : prefix = prefix ?? 'assets/icu/';
  final Future<ByteData> Function(String key) load;
  final String prefix;

  @override
  Future<ByteBuffer?> resolve(String locale) async {
    try {
      final data = await load('$prefix$locale.postcard');
      return data.buffer;
    } catch (_) {
      return null;
    }
  }
}

class _CallbackSource extends IcuDataSource {
  _CallbackSource(this.fetch);
  final Future<ByteBuffer?> Function(String locale) fetch;

  @override
  Future<ByteBuffer?> resolve(String locale) => fetch(locale);
}

class _BytesSource extends IcuDataSource {
  _BytesSource(this.bytes);
  final ByteBuffer bytes;

  @override
  // The same blob covers any locale baked into it. The runtime tries it
  // for every locale; ICU4X will fall through to the next IcuData if the
  // blob doesn't contain the requested locale.
  Future<ByteBuffer?> resolve(String locale) async => bytes;
}
