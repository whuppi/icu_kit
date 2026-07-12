import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';

/// Locale-aware decimal formatting — STABLE.
///
/// Backed by ICU4X's `icu_decimal::DecimalFormatter`. Covers the
/// `style: "decimal"` portion of ECMA-402 `Intl.NumberFormat`:
///
///   - Locale-specific decimal separator (`'.'` / `','`)
///   - Locale-specific grouping separator (`','` / `' '` / `'.'`)
///   - Configurable grouping strategy (auto / always / never / min2)
///   - Sign + minus-sign rendering
///
/// Currency formatting lives in a separate experimental class —
/// [`IcuCurrencyFormat`] — because the underlying ICU4X
/// `CurrencyFormatter` lives in `icu_experimental` and the API is still
/// evolving upstream (tracked: unicode-org/icu4x #7789).
///
/// Example:
///
/// ```dart
/// final fr = IcuNumberFormat.decimal(locale: 'fr');
/// fr.format(1234567.89);            // "1 234 567,89"
///
/// final en = IcuNumberFormat.decimal(locale: 'en-US', useGrouping: false);
/// en.format(1234.5);                // "1234.5"
/// ```
final class IcuNumberFormat {
  IcuNumberFormat._(this._ffi);

  /// Decimal-style formatter for [locale].
  ///
  /// [useGrouping] — `null` (default, locale-determined), `true` (always),
  /// `false` (never), or [IcuGroupingStrategy.min2] for "group only when 5+
  /// digits."
  factory IcuNumberFormat.decimal({
    required String locale,
    bool? useGrouping,
    IcuGroupingStrategy? groupingStrategy,
  }) {
    final loc = IcuLocale.parse(locale);
    final strategy = _resolveGroupingStrategy(useGrouping, groupingStrategy);
    try {
      final formatter = dispatch.decimalFormatterWithGroupingStrategy(
        locale,
        loc.ffi,
        strategy,
      );
      return IcuNumberFormat._(formatter);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Decimal formatter unavailable for $locale: $e',
        locale: locale,
        marker: 'DecimalFormatter',
      );
    }
  }
  final icu.DecimalFormatter _ffi;

  /// Format [value]. Accepts any `num` (int or double).
  ///
  /// Doubles are converted via round-trip precision — same digits the IEEE
  /// 754 representation has. For controlled-precision formatting, pre-round
  /// in Dart and pass an `int` or pre-rounded `double`.
  String format(num value) {
    final decimal = _toDecimal(value);
    return _ffi.format(decimal);
  }
}

/// Maps Dart's `num` to ICU4X's `Decimal`. Top-level so both decimal and
/// currency facades reuse it.
icu.Decimal toDecimalFfi(num value) => _toDecimal(value);

icu.Decimal _toDecimal(num value) {
  if (value is int) return icu.Decimal.fromInt(value);
  return icu.Decimal.fromDoubleWithRoundTripPrecision(value as double);
}

icu.DecimalGroupingStrategy? _resolveGroupingStrategy(
  bool? useGrouping,
  IcuGroupingStrategy? explicit,
) {
  if (explicit != null) {
    return switch (explicit) {
      IcuGroupingStrategy.auto => icu.DecimalGroupingStrategy.auto,
      IcuGroupingStrategy.never => icu.DecimalGroupingStrategy.never,
      IcuGroupingStrategy.always => icu.DecimalGroupingStrategy.always,
      IcuGroupingStrategy.min2 => icu.DecimalGroupingStrategy.min2,
    };
  }
  if (useGrouping == false) return icu.DecimalGroupingStrategy.never;
  if (useGrouping == true) return icu.DecimalGroupingStrategy.always;
  return null;
}

/// CLDR grouping strategy. Mirrors ICU4X's `DecimalGroupingStrategy`
/// + ECMA-402's `useGrouping` option.
enum IcuGroupingStrategy {
  /// Locale default. Most locales group thousands; some (e.g. Indian) use
  /// lakhs/crores positions.
  auto,

  /// Never insert grouping separators.
  never,

  /// Always insert grouping separators when locale has any.
  always,

  /// Group only when there are at least 5 digits ("min2" — locales where
  /// 4-digit numbers traditionally aren't grouped).
  min2,
}
