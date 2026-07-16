import 'package:meta/meta.dart';

import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';
import 'icu_number_format.dart'
    show
        IcuGroupingStrategy,
        IcuRoundingMode,
        IcuSignDisplay,
        IcuTrailingZeroDisplay,
        resolveGroupingStrategy,
        shapeDecimalDigits,
        shapedDecimalFfi;
import 'icu_number_parts.dart';

/// EXPERIMENTAL — compact-notation decimal formatting.
///
/// Backed by ICU4X's `icu_decimal::CompactDecimalFormatter` (behind that
/// crate's `unstable` feature), exposed via a local Diplomat IDL patch in
/// `vendor/icu4x/`. Covers ECMA-402 `notation: "compact"`:
///
///   * [IcuCompactDisplay.short] — `"1.2M"` (default)
///   * [IcuCompactDisplay.long]  — `"1.2 million"`
///
/// The formatter applies CLDR compact rounding to the significand
/// internally; the optional digit controls on [format] shape the input
/// BEFORE compacting and are rarely needed.
///
/// Example:
///
/// ```dart
/// final short = IcuCompactFormat(locale: 'en-US');
/// short.format(1234567);                    // "1.2M"
///
/// final long = IcuCompactFormat(
///   locale: 'en-US', display: IcuCompactDisplay.long);
/// long.format(1234567);                     // "1.2 million"
/// ```
@experimental
final class IcuCompactFormat {
  IcuCompactFormat._(this._ffi);

  /// EXPERIMENTAL — create a compact formatter for [locale].
  ///
  /// [display] selects the abbreviation form (default
  /// [IcuCompactDisplay.short]).
  @experimental
  factory IcuCompactFormat({
    required String locale,
    IcuCompactDisplay display = IcuCompactDisplay.short,
    bool? useGrouping,
    IcuGroupingStrategy? groupingStrategy,
  }) {
    final loc = IcuLocale.parse(locale);
    final strategy = resolveGroupingStrategy(useGrouping, groupingStrategy);
    try {
      final formatter = switch (display) {
        IcuCompactDisplay.short =>
          dispatch.compactDecimalFormatterShort(locale, loc.ffi, strategy),
        IcuCompactDisplay.long =>
          dispatch.compactDecimalFormatterLong(locale, loc.ffi, strategy),
      };
      return IcuCompactFormat._(formatter);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Compact formatter unavailable for $locale: $e',
        locale: locale,
        marker: 'CompactDecimalFormatter',
      );
    }
  }
  final icu.CompactDecimalFormatter _ffi;

  /// EXPERIMENTAL — format [value] in compact notation.
  ///
  /// CLDR compact rounding applies to the significand internally
  /// (`1234567` → `"1.2M"`). The digit controls shape the input value
  /// before compacting (see [shapeDecimalDigits]).
  @experimental
  String format(
    num value, {
    int? minimumIntegerDigits,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    int? minimumSignificantDigits,
    int? maximumSignificantDigits,
    IcuRoundingMode? roundingMode,
    int? roundingIncrement,
    IcuTrailingZeroDisplay? trailingZeroDisplay,
    IcuSignDisplay? signDisplay,
  }) => _ffi.format(
    shapedDecimalFfi(
      value,
      minimumIntegerDigits: minimumIntegerDigits,
      minimumFractionDigits: minimumFractionDigits,
      maximumFractionDigits: maximumFractionDigits,
      minimumSignificantDigits: minimumSignificantDigits,
      maximumSignificantDigits: maximumSignificantDigits,
      roundingMode: roundingMode,
      roundingIncrement: roundingIncrement,
      trailingZeroDisplay: trailingZeroDisplay,
      signDisplay: signDisplay,
    ),
  );

  /// EXPERIMENTAL — format [value] into typed parts (the number as
  /// integer / decimal / fraction, the abbreviation as a `compact` part),
  /// mirroring ECMA-402 `formatToParts`. Concatenating every part's
  /// `value` reproduces [format].
  @experimental
  List<IcuNumberPart> formatToParts(
    num value, {
    int? minimumIntegerDigits,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    int? minimumSignificantDigits,
    int? maximumSignificantDigits,
    IcuRoundingMode? roundingMode,
    int? roundingIncrement,
    IcuTrailingZeroDisplay? trailingZeroDisplay,
    IcuSignDisplay? signDisplay,
  }) => partsToList(
    _ffi.formatToParts(
      shapedDecimalFfi(
        value,
        minimumIntegerDigits: minimumIntegerDigits,
        minimumFractionDigits: minimumFractionDigits,
        maximumFractionDigits: maximumFractionDigits,
        minimumSignificantDigits: minimumSignificantDigits,
        maximumSignificantDigits: maximumSignificantDigits,
        roundingMode: roundingMode,
        roundingIncrement: roundingIncrement,
        trailingZeroDisplay: trailingZeroDisplay,
        signDisplay: signDisplay,
      ),
    ),
  );
}

/// EXPERIMENTAL — abbreviation form for [IcuCompactFormat]. Mirrors
/// ECMA-402 `compactDisplay`.
@experimental
enum IcuCompactDisplay {
  /// Abbreviated symbol (e.g. `"1.2M"` in en-US). Default.
  short,

  /// Spelled-out word (e.g. `"1.2 million"` in en-US).
  long,
}
