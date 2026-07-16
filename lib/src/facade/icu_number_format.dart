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
  /// 754 representation has. The optional controls apply ECMA-402 digit
  /// shaping before formatting (see [shapeDecimalDigits]):
  ///
  /// - [minimumIntegerDigits] — left-pad the integer part with zeros.
  /// - [minimumFractionDigits] — right-pad the fraction with zeros.
  /// - [maximumFractionDigits] — round the fraction ([roundingMode]
  ///   defaults to half away from zero, ECMA-402's default).
  /// - [minimumSignificantDigits] / [maximumSignificantDigits] — take
  ///   priority over the fraction/integer options when set.
  /// - [roundingMode] — one of the nine ECMA-402 modes.
  /// - [roundingIncrement] — snap to a multiple (nickel rounding etc.).
  /// - [trailingZeroDisplay] — strip fraction zeros on whole numbers.
  /// - [signDisplay] — when the sign renders, applied post-rounding.
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
  }) {
    return _ffi.format(
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
    IcuRoundingMode? roundingMode,
    int? roundingIncrement,
    IcuTrailingZeroDisplay? trailingZeroDisplay,
    IcuSignDisplay? signDisplay,
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
          roundingMode: roundingMode,
          roundingIncrement: roundingIncrement,
          trailingZeroDisplay: trailingZeroDisplay,
          signDisplay: signDisplay,
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
///
/// [roundingMode] picks one of the nine ECMA-402 modes (default
/// [IcuRoundingMode.halfExpand]). [roundingIncrement] snaps rounding to a
/// multiple (nickel rounding etc.) — it requires an explicit
/// [maximumFractionDigits] equal to the (defaulted-to-0)
/// [minimumFractionDigits] and is incompatible with significant-digit
/// options; violations throw [IcuDataError]. [trailingZeroDisplay] strips
/// fraction zeros from integer-valued results. [signDisplay] applies to the
/// value AFTER rounding (ECMA-402: the sign reflects the rounded value).
icu.Decimal shapedDecimalFfi(
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
}) {
  if (minimumSignificantDigits != null || maximumSignificantDigits != null) {
    if (roundingIncrement != null && roundingIncrement != 1) {
      throw IcuDataError(
        'roundingIncrement is incompatible with significant-digit options',
        marker: 'shapedDecimalFfi',
      );
    }
    final icu.Decimal d;
    if (maximumSignificantDigits != null && roundingMode != null) {
      // A custom mode can't ride the significant-digits constructor (it
      // rounds with its own default), so round in place at the position of
      // the (maxSig)th significant digit of the ORIGINAL value.
      d = _toDecimal(value);
      d.roundWithMode(
        d.magnitudeEnd - maximumSignificantDigits + 1,
        _ffiRoundingMode(roundingMode),
      );
    } else if (maximumSignificantDigits != null) {
      // maxSig rounds at construction (ICU4X handles the magnitude shift
      // that naive position math gets wrong, e.g. 9.99 @ 2 sig → "10").
      d = icu.Decimal.fromDoubleWithSignificantDigits(
        value.toDouble(),
        maximumSignificantDigits,
      );
    } else {
      d = _toDecimal(value);
    }
    if (minimumSignificantDigits != null) {
      // Pad trailing zeros so at least minSig significant digits show. The
      // most-significant digit sits at magnitudeEnd (ICU4X magnitude_range is
      // a Rust RangeInclusive, so `end` is the HIGH magnitude); the lowest
      // significant position we need is magnitudeEnd - minSig + 1.
      d.padEnd(d.magnitudeEnd - minimumSignificantDigits + 1);
    }
    if (trailingZeroDisplay == IcuTrailingZeroDisplay.stripIfInteger) {
      d.trimEndIfInteger();
    }
    if (signDisplay != null) d.applySignDisplay(_ffiSignDisplay(signDisplay));
    return d;
  }
  final d = _toDecimal(value);
  shapeDecimalDigits(
    d,
    minimumIntegerDigits: minimumIntegerDigits,
    minimumFractionDigits: minimumFractionDigits,
    maximumFractionDigits: maximumFractionDigits,
    roundingMode: roundingMode,
    roundingIncrement: roundingIncrement,
    trailingZeroDisplay: trailingZeroDisplay,
    signDisplay: signDisplay,
  );
  return d;
}

/// Apply ECMA-402 digit shaping to [d] in place, before it is handed to any
/// formatter. Shared by every number-style facade (decimal / percent /
/// currency / unit) so digit semantics are identical across styles.
///
/// Order is load-bearing: round FIRST (drop excess fraction), then pad the
/// minimum fraction (restore required trailing zeros), then pad the integer,
/// then strip integer-valued trailing zeros ([trailingZeroDisplay] must
/// undo the padding for whole numbers), then apply [signDisplay] (the sign
/// reflects the ROUNDED value per ECMA-402).
///
/// [maximumFractionDigits] rounds half away from zero — ECMA-402's default
/// `roundingMode`, which is NOT ICU4X's default (half-even) — unless
/// [roundingMode] overrides it. A non-1 [roundingIncrement] snaps to a
/// multiple at the rounding position; it requires an explicit
/// [maximumFractionDigits] matching the (defaulted-to-0)
/// [minimumFractionDigits], and must be {1, 2, 5, 25} × 10^k — violations
/// throw [IcuDataError].
void shapeDecimalDigits(
  icu.Decimal d, {
  int? minimumIntegerDigits,
  int? minimumFractionDigits,
  int? maximumFractionDigits,
  IcuRoundingMode? roundingMode,
  int? roundingIncrement,
  IcuTrailingZeroDisplay? trailingZeroDisplay,
  IcuSignDisplay? signDisplay,
}) {
  final mode = _ffiRoundingMode(roundingMode ?? IcuRoundingMode.halfExpand);
  if (roundingIncrement != null && roundingIncrement != 1) {
    if (maximumFractionDigits == null ||
        (minimumFractionDigits ?? 0) != maximumFractionDigits) {
      throw IcuDataError(
        'roundingIncrement requires equal minimum and maximum fraction '
        'digits (an explicit maximumFractionDigits matching '
        'minimumFractionDigits, which defaults to 0)',
        marker: 'shapeDecimalDigits',
      );
    }
    // Decompose increment = base × 10^k with base in {1, 2, 5, 25}, then
    // round to multiples of `base` at position (k - maxFrac). Covers the
    // whole ECMA-402 increment set (10 = 1e1, 50 = 5e1, 250 = 25e1, …).
    var base = roundingIncrement;
    var k = 0;
    while (base % 10 == 0) {
      base ~/= 10;
      k++;
    }
    final increment = switch (base) {
      1 => icu.DecimalRoundingIncrement.multiplesOf1,
      2 => icu.DecimalRoundingIncrement.multiplesOf2,
      5 => icu.DecimalRoundingIncrement.multiplesOf5,
      25 => icu.DecimalRoundingIncrement.multiplesOf25,
      _ => throw IcuDataError(
          'roundingIncrement must be one of 1, 2, 5, 10, 20, 25, 50, 100, '
          '200, 250, 500, 1000, 2000, 2500, 5000 (got $roundingIncrement)',
          marker: 'shapeDecimalDigits',
        ),
    };
    d.roundWithModeAndIncrement(k - maximumFractionDigits, mode, increment);
  } else if (maximumFractionDigits != null) {
    d.roundWithMode(-maximumFractionDigits, mode);
  }
  // In the increment branch the effective minimum equals maximumFractionDigits
  // (the constraint above guarantees it when minimumFractionDigits is unset),
  // and padding must run UNCONDITIONALLY there: the pad is also what records
  // the fraction intent for the browser-Intl Decimal mirror — without it the
  // shim pins fraction digits from the input string and renders "0.0" where
  // native renders "0".
  final padTo = minimumFractionDigits ??
      (roundingIncrement != null && roundingIncrement != 1
          ? maximumFractionDigits
          : null);
  if (padTo != null) {
    d.padEnd(-padTo);
  }
  if (minimumIntegerDigits != null) {
    // ICU4X pad_start(position) yields `position` integer digits (verified:
    // pad_start(4) on 42 → "0042"), so the digit count maps straight through.
    d.padStart(minimumIntegerDigits);
  }
  if (trailingZeroDisplay == IcuTrailingZeroDisplay.stripIfInteger) {
    d.trimEndIfInteger();
  }
  if (signDisplay != null) d.applySignDisplay(_ffiSignDisplay(signDisplay));
}

icu.DecimalSignedRoundingMode _ffiRoundingMode(IcuRoundingMode mode) =>
    switch (mode) {
      IcuRoundingMode.ceil => icu.DecimalSignedRoundingMode.ceil,
      IcuRoundingMode.floor => icu.DecimalSignedRoundingMode.floor,
      IcuRoundingMode.expand => icu.DecimalSignedRoundingMode.expand,
      IcuRoundingMode.trunc => icu.DecimalSignedRoundingMode.trunc,
      IcuRoundingMode.halfCeil => icu.DecimalSignedRoundingMode.halfCeil,
      IcuRoundingMode.halfFloor => icu.DecimalSignedRoundingMode.halfFloor,
      IcuRoundingMode.halfExpand => icu.DecimalSignedRoundingMode.halfExpand,
      IcuRoundingMode.halfTrunc => icu.DecimalSignedRoundingMode.halfTrunc,
      IcuRoundingMode.halfEven => icu.DecimalSignedRoundingMode.halfEven,
    };

icu.DecimalSignDisplay _ffiSignDisplay(IcuSignDisplay display) =>
    switch (display) {
      IcuSignDisplay.auto => icu.DecimalSignDisplay.auto,
      IcuSignDisplay.never => icu.DecimalSignDisplay.never,
      IcuSignDisplay.always => icu.DecimalSignDisplay.always,
      IcuSignDisplay.exceptZero => icu.DecimalSignDisplay.exceptZero,
      IcuSignDisplay.negative => icu.DecimalSignDisplay.negative,
    };

/// ECMA-402 `roundingMode` — how a value is rounded at the cutoff digit.
enum IcuRoundingMode {
  /// Toward positive infinity.
  ceil,

  /// Toward negative infinity.
  floor,

  /// Away from zero.
  expand,

  /// Toward zero.
  trunc,

  /// To the nearest; ties toward positive infinity.
  halfCeil,

  /// To the nearest; ties toward negative infinity.
  halfFloor,

  /// To the nearest; ties away from zero (the ECMA-402 default).
  halfExpand,

  /// To the nearest; ties toward zero.
  halfTrunc,

  /// To the nearest; ties to the even neighbor (banker's rounding).
  halfEven,
}

/// ECMA-402 `signDisplay` — when the sign is rendered. Applied to the
/// value AFTER rounding.
enum IcuSignDisplay {
  /// Sign on negative values only (the default).
  auto,

  /// Never show a sign.
  never,

  /// Sign on every value, including zero.
  always,

  /// Sign on every non-zero value.
  exceptZero,

  /// Minus on negative values, never a plus.
  negative,
}

/// ECMA-402 `trailingZeroDisplay` — whether fraction zeros survive on
/// integer-valued results.
enum IcuTrailingZeroDisplay {
  /// Keep zeros required by the fraction-digit options (the default).
  auto,

  /// Drop all fraction zeros when the rounded value is a whole number.
  stripIfInteger,
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

/// Shared `useGrouping` / [IcuGroupingStrategy] → binding-enum mapping,
/// reused by the percent / currency / unit facades so all four number
/// styles resolve grouping identically.
icu.DecimalGroupingStrategy? resolveGroupingStrategy(
  bool? useGrouping,
  IcuGroupingStrategy? explicit,
) => _resolveGroupingStrategy(useGrouping, explicit);

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
