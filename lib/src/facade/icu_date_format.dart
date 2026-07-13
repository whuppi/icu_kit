import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_datetime_shared.dart';
import 'icu_locale.dart';

// Re-export the shared enums so importers of this file don't need a
// second import. The public barrel `lib/icu_kit.dart` exports this file
// (via the conditional barrel `icu_date_format.dart`), making
// `IcuDateLength`, `IcuDateAlignment`, `IcuYearStyle` available to apps.
export 'icu_datetime_shared.dart'
    show IcuDateAlignment, IcuDateLength, IcuYearStyle;

/// Locale-aware date formatting — STABLE.
///
/// Maps Dart's `DateTime` (always proleptic Gregorian) to ICU4X's `IsoDate`,
/// which the formatter then renders via the locale's calendar (driven by
/// the locale's BCP47 `-u-ca-…` extension if present, else Gregorian).
///
/// ECMA-402 `dateStyle` mapping: `IcuDateLength.full/long/medium/short`
/// translate to ICU4X's `Length.long/medium/short` (ICU4X has no `full`;
/// `IcuDateLength.full` aliases to `long` here, matching JS engines'
/// rendering behavior).
///
/// Five field-set constructors cover the common shapes:
///
///   * `.ymd()` — year + month + day (most common; ECMA-402 dateStyle)
///   * `.md()`  — month + day
///   * `.ymde()` — year + month + day + weekday (e.g. "Mon, Apr 28, 2026")
///   * `.mde()` — month + day + weekday
///   * `.de()`  — day + weekday
///
/// For non-default cases (only year, only month, only weekday), use the
/// lower-level constructors `.y()`, `.m()`, `.e()`, `.ym()`, `.d()`.
final class IcuDateFormat {
  IcuDateFormat._(this._ffi);

  /// Year + month + day for [locale]. The ECMA-402 `dateStyle` workhorse.
  ///
  /// Example: `IcuDateFormat.ymd(locale: 'en-US', length: medium)`
  /// → "Apr 28, 2026"
  factory IcuDateFormat.ymd({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.ymd',
      build: (l, loc) => dispatch.dateFormatterYmd(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
        yearStyle: toFfiYearStyle(yearStyle),
      ),
    );
  }

  /// Month + day for [locale]. No year.
  factory IcuDateFormat.md({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.md',
      build: (l, loc) => dispatch.dateFormatterMd(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
      ),
    );
  }

  /// Year + month + day + weekday — e.g. "Monday, April 28, 2026".
  factory IcuDateFormat.ymde({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.ymde',
      build: (l, loc) => dispatch.dateFormatterYmde(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
        yearStyle: toFfiYearStyle(yearStyle),
      ),
    );
  }

  /// Month + day + weekday — e.g. "Mon, Apr 28".
  factory IcuDateFormat.mde({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.mde',
      build: (l, loc) => dispatch.dateFormatterMde(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
      ),
    );
  }

  /// Day + weekday — e.g. "Mon 28".
  factory IcuDateFormat.de({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.de',
      build: (l, loc) => dispatch.dateFormatterDe(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
      ),
    );
  }

  /// Year only.
  factory IcuDateFormat.y({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.y',
      build: (l, loc) => dispatch.dateFormatterY(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
        yearStyle: toFfiYearStyle(yearStyle),
      ),
    );
  }

  /// Month only.
  factory IcuDateFormat.m({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.m',
      build: (l, loc) => dispatch.dateFormatterM(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
      ),
    );
  }

  /// Day only.
  factory IcuDateFormat.d({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.d',
      build: (l, loc) => dispatch.dateFormatterD(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
      ),
    );
  }

  /// Weekday only.
  factory IcuDateFormat.e({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.e',
      build: (l, loc) => dispatch.dateFormatterE(l, loc, toFfiLength(length)),
    );
  }

  /// Year + month.
  factory IcuDateFormat.ym({
    required String locale,
    IcuDateLength length = IcuDateLength.medium,
    IcuDateAlignment? alignment,
    IcuYearStyle? yearStyle,
  }) {
    return _build(
      locale: locale,
      marker: 'DateFormatter.ym',
      build: (l, loc) => dispatch.dateFormatterYm(
        l,
        loc,
        length: toFfiLength(length),
        alignment: toFfiAlignment(alignment),
        yearStyle: toFfiYearStyle(yearStyle),
      ),
    );
  }
  final icu.DateFormatter _ffi;

  /// Format a Dart [DateTime] (date portion only — time portion ignored).
  ///
  /// `DateTime` is always proleptic Gregorian in Dart; ICU4X accepts an
  /// `IsoDate` and renders via the locale's calendar internally. Time-zone
  /// of the input [DateTime] is ignored — the wall-clock date is taken
  /// as-is.
  String format(DateTime date) {
    return _ffi.formatIso(isoDateFromDart(date));
  }

  // ---- internal helpers -------------------------------------------------

  static IcuDateFormat _build({
    required String locale,
    required String marker,
    required icu.DateFormatter Function(String localeStr, icu.Locale loc) build,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      return IcuDateFormat._(build(locale, loc.ffi));
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Date formatter unavailable for $locale: $e',
        locale: locale,
        marker: marker,
      );
    }
  }
}
