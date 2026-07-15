import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';
import 'icu_number_parts.dart';

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
  /// 754 representation has. The optional digit controls apply ECMA-402
  /// digit shaping before formatting (see [shapeDecimalDigits]):
  ///
  /// - [minimumIntegerDigits] — left-pad the integer part with zeros.
  /// - [minimumFractionDigits] — right-pad the fraction with zeros.
  /// - [maximumFractionDigits] — round the fraction (half away from zero,
  ///   ECMA-402's default rounding).
  String format(
    num value, {
    int? minimumIntegerDigits,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    int? minimumSignificantDigits,
    int? maximumSignificantDigits,
  }) {
    return _ffi.format(
      shapedDecimalFfi(
        value,
        minimumIntegerDigits: minimumIntegerDigits,
        minimumFractionDigits: minimumFractionDigits,
        maximumFractionDigits: maximumFractionDigits,
        minimumSignificantDigits: minimumSignificantDigits,
        maximumSignificantDigits: maximumSignificantDigits,
      ),
    );
  }

  /// Format [value] into typed parts (integer / group / decimal / fraction /
  /// sign), mirroring ECMA-402 `Intl.NumberFormat.prototype.formatToParts`.
  ///
  /// Concatenating every part's `value` reproduces [format]'s output exactly.
  /// The digit controls behave as in [format].
  List<IcuNumberPart> formatToParts(
    num value, {
    int? minimumIntegerDigits,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    int? minimumSignificantDigits,
    int? maximumSignificantDigits,
  }) {
    return partsToList(
      _ffi.formatToParts(
        shapedDecimalFfi(
          value,
          minimumIntegerDigits: minimumIntegerDigits,
          minimumFractionDigits: minimumFractionDigits,
          maximumFractionDigits: maximumFractionDigits,
          minimumSignificantDigits: minimumSignificantDigits,
          maximumSignificantDigits: maximumSignificantDigits,
        ),
      ),
    );
  }
}

/// Maps Dart's `num` to ICU4X's `Decimal`. Top-level so both decimal and
/// currency facades reuse it.
icu.Decimal toDecimalFfi(num value) => _toDecimal(value);

/// Build the shaped ICU4X Decimal for [value] under ECMA-402 digit options.
/// Every number-style facade (decimal / percent / currency / unit) builds its
/// Decimal through this, so digit shaping is identical across styles.
///
/// Significant-digit options take priority over integer/fraction options
/// (ECMA-402's default `roundingPriority: "auto"`): when either significant
/// option is set, the fraction/integer options are ignored.
icu.Decimal shapedDecimalFfi(
  num value, {
  int? minimumIntegerDigits,
  int? minimumFractionDigits,
  int? maximumFractionDigits,
  int? minimumSignificantDigits,
  int? maximumSignificantDigits,
}) {
  if (minimumSignificantDigits != null || maximumSignificantDigits != null) {
    // maxSig rounds at construction (ICU4X handles the magnitude shift that
    // in-place rounding gets wrong, e.g. 9.99 @ 2 sig → "10", not "10.0").
    final d = maximumSignificantDigits != null
        ? icu.Decimal.fromDoubleWithSignificantDigits(
            value.toDouble(),
            maximumSignificantDigits,
          )
        : _toDecimal(value);
    if (minimumSignificantDigits != null) {
      // Pad trailing zeros so at least minSig significant digits show. The
      // most-significant digit sits at magnitudeEnd (ICU4X magnitude_range is
      // a Rust RangeInclusive, so `end` is the HIGH magnitude); the lowest
      // significant position we need is magnitudeEnd - minSig + 1.
      d.padEnd(d.magnitudeEnd - minimumSignificantDigits + 1);
    }
    return d;
  }
  final d = _toDecimal(value);
  shapeDecimalDigits(
    d,
    minimumIntegerDigits: minimumIntegerDigits,
    minimumFractionDigits: minimumFractionDigits,
    maximumFractionDigits: maximumFractionDigits,
  );
  return d;
}

/// Apply ECMA-402 digit shaping to [d] in place, before it is handed to any
/// formatter. Shared by every number-style facade (decimal / percent /
/// currency / unit) so digit semantics are identical across styles.
///
/// Order is load-bearing: round FIRST (drop excess fraction), then pad the
/// minimum fraction (restore required trailing zeros), then pad the integer.
/// Rounding after padding would strip the zeros padding just added.
///
/// [maximumFractionDigits] rounds half away from zero — ECMA-402's default
/// `roundingMode`, which is NOT ICU4X's default (half-even), so it goes
/// through `roundWithMode` explicitly.
void shapeDecimalDigits(
  icu.Decimal d, {
  int? minimumIntegerDigits,
  int? minimumFractionDigits,
  int? maximumFractionDigits,
}) {
  if (maximumFractionDigits != null) {
    d.roundWithMode(
      -maximumFractionDigits,
      icu.DecimalSignedRoundingMode.halfExpand,
    );
  }
  if (minimumFractionDigits != null) {
    d.padEnd(-minimumFractionDigits);
  }
  if (minimumIntegerDigits != null) {
    // ICU4X pad_start(position) yields `position` integer digits (verified:
    // pad_start(4) on 42 → "0042"), so the digit count maps straight through.
    d.padStart(minimumIntegerDigits);
  }
}

icu.Decimal _toDecimal(num value) {
  // On the web, `is int` is true for any integer-VALUED double — including
  // -0.0 and ±infinity (dart2js/dart2wasm number semantics). Route those
  // through the double constructor so ICU4X applies one contract on every
  // engine: sign preserved for -0.0, throw for non-finite. The int branch
  // would silently drop the sign (-0.0) or coerce ±infinity to 0.
  final d = value.toDouble();
  if (!d.isFinite || (d == 0 && d.isNegative)) {
    return icu.Decimal.fromDoubleWithRoundTripPrecision(d);
  }
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
