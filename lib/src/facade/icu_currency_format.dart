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

/// EXPERIMENTAL — currency-aware decimal formatting.
///
/// Backed by ICU4X's `icu_experimental::dimension::currency::formatter`
/// (`CurrencyFormatter`) and `long_formatter` (`LongCurrencyFormatter`).
/// Both are exposed via a local Diplomat IDL patch in `vendor/icu4x/`.
///
/// **This API is unstable.** ICU4X 2.2's `Width` enum (`Short` / `Narrow`)
/// will be replaced by the unified `CurrencyDisplay` in 2.3+ once
/// unicode-org/icu4x PR #7789 lands and stabilizes. When that happens the
/// experimental mark lifts, the API may change, and old `IcuCurrencyWidth`
/// callers may need to migrate to a new shape.
///
/// Two display modes are supported today:
///   * Symbol form (e.g. `"$1.00"` / `"US$1"`) via [IcuCurrencyFormat.symbol]
///   * Long form (e.g. `"1 US dollar"` / `"2 US dollars"`) via [IcuCurrencyFormat.long]
///
/// Example:
///
/// ```dart
/// final usd = IcuCurrencyFormat.symbol(locale: 'en-US');
/// usd.format(1234.56, currencyCode: 'USD');           // "$1,234.56"
///
/// final long = IcuCurrencyFormat.long(locale: 'en-US', currencyCode: 'USD');
/// long.format(1);                                      // "1 US dollar"
/// long.format(2);                                      // "2 US dollars"
/// ```
@experimental
final class IcuCurrencyFormat {
  IcuCurrencyFormat._symbol(this._symbol)
    : _long = null,
      _pinnedCurrencyCode = null;

  IcuCurrencyFormat._long(this._long, this._pinnedCurrencyCode)
    : _symbol = null;

  /// EXPERIMENTAL — symbol-style currency formatter (e.g. "$1.00", "US$1").
  ///
  /// [width] selects between the locale's short and narrow forms. Default
  /// is short. Renders the currency code passed to [format] each call.
  @experimental
  factory IcuCurrencyFormat.symbol({
    required String locale,
    IcuCurrencyWidth width = IcuCurrencyWidth.short,
    bool? useGrouping,
    IcuGroupingStrategy? groupingStrategy,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      final formatter = dispatch.currencyFormatterWithWidth(
        locale,
        loc.ffi,
        width: switch (width) {
          IcuCurrencyWidth.short => icu.CurrencyWidth.short,
          IcuCurrencyWidth.narrow => icu.CurrencyWidth.narrow,
          IcuCurrencyWidth.code => icu.CurrencyWidth.code,
        },
        groupingStrategy: resolveGroupingStrategy(
          useGrouping,
          groupingStrategy,
        ),
      );
      return IcuCurrencyFormat._symbol(formatter);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Currency formatter unavailable for $locale: $e',
        locale: locale,
        marker: 'CurrencyFormatter',
      );
    }
  }

  /// EXPERIMENTAL — long-form currency formatter pinned to one currency.
  ///
  /// Renders locale-aware plural form (e.g. "1 US dollar" / "2 US dollars").
  /// [currencyCode] must be a 3-letter ISO 4217 code; the formatter is
  /// pinned to that currency for the lifetime of this instance.
  @experimental
  factory IcuCurrencyFormat.long({
    required String locale,
    required String currencyCode,
    bool? useGrouping,
    IcuGroupingStrategy? groupingStrategy,
  }) {
    if (currencyCode.length != 3) {
      throw IcuDataError(
        'Currency code must be exactly 3 ASCII characters (got "$currencyCode")',
        locale: locale,
        marker: 'LongCurrencyFormatter',
      );
    }
    final loc = IcuLocale.parse(locale);
    try {
      final formatter = dispatch.longCurrencyFormatterForCurrency(
        locale,
        loc.ffi,
        currencyCode,
        resolveGroupingStrategy(useGrouping, groupingStrategy),
      );
      return IcuCurrencyFormat._long(formatter, currencyCode);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Long currency formatter unavailable for $locale + $currencyCode: $e',
        locale: locale,
        marker: 'LongCurrencyFormatter',
      );
    }
  }
  // Exactly one of these two is non-null. Symbol form uses the per-call
  // currency code; long form is pinned to one currency at construction.
  final icu.CurrencyFormatter? _symbol;
  final icu.LongCurrencyFormatter? _long;
  final String? _pinnedCurrencyCode;

  /// EXPERIMENTAL — format [value] as a currency string.
  ///
  /// For symbol-style instances, [currencyCode] is required (3-letter ISO
  /// 4217). For long-form instances, [currencyCode] is ignored — the
  /// formatter is pinned to the currency code passed at construction. The
  /// digit controls apply ECMA-402 shaping (see [shapeDecimalDigits]).
  @experimental
  String format(
    num value, {
    String? currencyCode,
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
    final decimal = shapedDecimalFfi(
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
    );
    final symbol = _symbol;
    if (symbol != null) {
      if (currencyCode == null || currencyCode.length != 3) {
        throw IcuDataError(
          'Symbol-style IcuCurrencyFormat.format requires a 3-letter '
          'ISO 4217 currencyCode (got: ${currencyCode ?? "null"})',
          marker: 'CurrencyFormatter.format',
        );
      }
      return symbol.format(decimal, currencyCode);
    }
    return _long!.format(decimal);
  }

  /// EXPERIMENTAL — format [value] into typed parts (the symbol or name as a
  /// `currency` part, the number as integer / group / decimal / fraction),
  /// mirroring ECMA-402 `formatToParts`. Same [currencyCode] contract as
  /// [format]. Concatenating every part's `value` reproduces [format].
  @experimental
  List<IcuNumberPart> formatToParts(
    num value, {
    String? currencyCode,
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
    final decimal = shapedDecimalFfi(
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
    );
    final symbol = _symbol;
    if (symbol != null) {
      if (currencyCode == null || currencyCode.length != 3) {
        throw IcuDataError(
          'Symbol-style IcuCurrencyFormat.formatToParts requires a 3-letter '
          'ISO 4217 currencyCode (got: ${currencyCode ?? "null"})',
          marker: 'CurrencyFormatter.formatToParts',
        );
      }
      return partsToList(symbol.formatToParts(decimal, currencyCode));
    }
    return partsToList(_long!.formatToParts(decimal));
  }

  /// EXPERIMENTAL — the currency code this formatter is pinned to, or null
  /// for symbol-style formatters that take the code per-call.
  @experimental
  String? get pinnedCurrencyCode => _pinnedCurrencyCode;
}

/// EXPERIMENTAL — currency symbol width.
///
/// Mirrors ICU4X 2.2's `Width` enum. Will be subsumed by `CurrencyDisplay`
/// when upstream PR #7789 lands.
@experimental
enum IcuCurrencyWidth {
  /// Short form — e.g. "$1" in en-US, "US$1" in some locales.
  short,

  /// Narrow form — e.g. "$1" everywhere (ambiguous on purpose, for tight
  /// columns where the locale-specific differentiation is undesirable).
  narrow,

  /// ISO 4217 code form — e.g. "USD 1.00" in en-US. The 3-letter code with
  /// the alpha-next-to-number spacing CLDR uses for alphabetic displays.
  /// Maps to ECMA-402 `currencyDisplay: "code"`.
  code,
}
