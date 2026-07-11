/// Sealed error hierarchy for ICU operations.
///
/// All errors thrown by `icu_kit` extend [IcuError]. Each subtype is `final`
/// (Dart 3) so consumer `switch` statements are compiler-enforced exhaustive.
sealed class IcuError implements Exception {
  const IcuError(this.message);

  /// Developer-facing English diagnostic. NOT user-facing.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The locale string failed to parse as a BCP-47 identifier.
final class IcuLocaleParseError extends IcuError {
  /// Create the error for the unparseable [input].
  const IcuLocaleParseError(this.input)
    : super('Invalid BCP-47 locale: "$input"');

  /// The string that failed to parse.
  final String input;
}

/// CLDR data for the requested operation is unavailable in the current build.
///
/// This typically means the data blob shipped with the binary doesn't include
/// the locale or component you asked for. Run `dart run icu_kit:slice` with
/// the right `--locales` and `--features` to include it.
final class IcuDataError extends IcuError {
  /// Create the error; [locale] and [marker] narrow down what was
  /// missing.
  const IcuDataError(super.message, {this.locale, this.marker});

  /// Optional locale that was requested.
  final String? locale;

  /// Optional component / marker name that was requested.
  final String? marker;
}

/// CLDR data for the requested locale isn't loaded yet.
///
/// Thrown when:
///   * The active `IcuData` is lazy AND the locale wasn't preloaded —
///     call `await IcuKit.preloadLocale(locale)` before constructing
///     facades for that locale.
///   * The active `IcuData` is composite AND no source covers the locale.
///   * The build was compiled with `bundleCldrData: false` AND
///     `IcuKit.init` was called without a `data:` argument — there's no
///     data anywhere.
final class IcuMissingDataError extends IcuError {
  /// Create the error for the unresolvable [locale].
  const IcuMissingDataError(super.message, {required this.locale});

  /// The locale that couldn't be resolved.
  final String locale;
}

/// A formatter received an option value the spec doesn't permit, or the
/// underlying ICU4X formatter rejected the option combination.
final class IcuOptionError extends IcuError {
  /// Create the error for [optionName] rejecting [badValue].
  IcuOptionError(this.optionName, this.badValue)
    : super('Invalid value for option "$optionName": $badValue');

  /// The option name (e.g. `'currencyDisplay'`).
  final String optionName;

  /// The bad value.
  final Object? badValue;
}

/// The ICU4X native library could not be loaded for the current platform.
///
/// Means the build hook didn't produce a binary, or the binary failed to load
/// at runtime. Check `pub get` output and the build hook logs.
final class IcuLoadError extends IcuError {
  /// Create the error for a load failure on [platform].
  IcuLoadError(this.platform, this.cause)
    : super('Failed to initialize icu_capi on platform "$platform": $cause');

  /// The platform identifier where loading failed (e.g. `'macos-arm64'`).
  final String platform;

  /// The underlying platform-side cause, if any.
  final Object? cause;
}

/// IDNA processing rejected a domain name.
///
/// Thrown by `IcuIdna`'s `toAscii` / `toUnicode` when the input fails
/// UTS #46 / RFC 5891 validation, or when the input bytes aren't valid
/// UTF-8.
final class IcuIdnaError extends IcuError {
  /// Create the error for [operation] rejecting [domain].
  IcuIdnaError(this.kind, this.domain, this.operation)
    : super('IDNA $operation failed (${kind.name}) for "$domain"');

  /// Why the call failed.
  final IcuIdnaErrorKind kind;

  /// The domain that triggered the error.
  final String domain;

  /// Which IDNA operation failed — `'toAscii'` or `'toUnicode'`.
  final String operation;
}

/// Why IDNA processing failed.
enum IcuIdnaErrorKind {
  /// An error from the underlying `idna` crate that doesn't fit the
  /// other variants. Rare; treat as opaque.
  unknown,

  /// The input bytes were not valid UTF-8.
  invalidUtf8,

  /// The domain failed UTS #46 / RFC 5891 validation. Examples:
  /// invalid Punycode, label too long (>63 bytes ASCII), domain too
  /// long (>253 bytes ASCII), disallowed characters.
  invalid,
}
