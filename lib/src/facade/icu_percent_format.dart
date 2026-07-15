import 'package:meta/meta.dart';

import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';
import 'icu_number_format.dart' show shapedDecimalFfi, shapeDecimalDigits;
import 'icu_number_parts.dart';

/// EXPERIMENTAL — locale-aware percent formatting.
///
/// Backed by ICU4X's `icu_experimental::dimension::percent::PercentFormatter`,
/// exposed via a local Diplomat IDL patch. The upstream API will be
/// subsumed by the unified percent/currency/unit shape tracked at
/// unicode-org/icu4x PR #7789 — same migration trigger as
/// `IcuCurrencyFormat`.
///
/// **Scaling convention.** ICU4X's percent formatter does NOT scale the
/// input — `0.12` renders as `"0.12%"`, not `"12%"`. ECMA-402's
/// `Intl.NumberFormat({style: "percent"})` DOES scale by 100 (`0.12` →
/// `"12%"`). For ECMA-402 parity, multiply by 100 in Dart before calling
/// [format].
///
/// Three display modes from CLDR's percent essentials:
///   * [IcuPercentDisplay.standard]      — `"12%"` in en-US
///   * [IcuPercentDisplay.approximate]   — `"~12%"` in en-US
///   * [IcuPercentDisplay.explicitSign]  — `"+12%"` in en-US
///
/// Example:
///
/// ```dart
/// final pct = IcuPercentFormat(locale: 'en-US');
/// pct.format(50);        // "50%"
/// pct.format(0.5 * 100); // "50%" (ECMA-402-style scaling)
///
/// final fr = IcuPercentFormat(locale: 'fr');
/// fr.format(12.34);      // "12,34 %" (locale-correct comma + NBSP)
/// ```
@experimental
final class IcuPercentFormat {
  IcuPercentFormat._(this._ffi);

  /// EXPERIMENTAL — create a percent formatter for [locale].
  ///
  /// [display] selects the rendering style (default
  /// [IcuPercentDisplay.standard]).
  @experimental
  factory IcuPercentFormat({
    required String locale,
    IcuPercentDisplay display = IcuPercentDisplay.standard,
  }) {
    final loc = IcuLocale.parse(locale);
    try {
      final formatter = dispatch.percentFormatterWithDisplay(
        locale,
        loc.ffi,
        switch (display) {
          IcuPercentDisplay.standard => icu.PercentDisplay.standard,
          IcuPercentDisplay.approximate => icu.PercentDisplay.approximate,
          IcuPercentDisplay.explicitSign => icu.PercentDisplay.explicitSign,
        },
      );
      return IcuPercentFormat._(formatter);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Percent formatter unavailable for $locale: $e',
        locale: locale,
        marker: 'PercentFormatter',
      );
    }
  }
  final icu.PercentFormatter _ffi;

  /// EXPERIMENTAL — format [value] as a percent.
  ///
  /// Input is interpreted as ALREADY-scaled. For ECMA-402 semantics
  /// (`0.12` → `"12%"`), multiply by 100 in Dart first. The digit controls
  /// apply ECMA-402 shaping (see [shapeDecimalDigits]).
  @experimental
  String format(
    num value, {
    int? minimumIntegerDigits,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    int? minimumSignificantDigits,
    int? maximumSignificantDigits,
  }) => _ffi.format(
    shapedDecimalFfi(
      value,
      minimumIntegerDigits: minimumIntegerDigits,
      minimumFractionDigits: minimumFractionDigits,
      maximumFractionDigits: maximumFractionDigits,
      minimumSignificantDigits: minimumSignificantDigits,
      maximumSignificantDigits: maximumSignificantDigits,
    ),
  );

  /// EXPERIMENTAL — format [value] into typed parts (integer / group /
  /// decimal / fraction / percentSign / sign), mirroring ECMA-402
  /// `formatToParts`. Concatenating every part's `value` reproduces [format].
  @experimental
  List<IcuNumberPart> formatToParts(
    num value, {
    int? minimumIntegerDigits,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    int? minimumSignificantDigits,
    int? maximumSignificantDigits,
  }) => partsToList(
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

/// EXPERIMENTAL — display style for [IcuPercentFormat].
///
/// Mirrors ICU4X's `Display` enum.
@experimental
enum IcuPercentDisplay {
  /// Locale-standard percent rendering (e.g. `"12%"` in en-US).
  standard,

  /// Approximate-value rendering (e.g. `"~12%"` in en-US).
  approximate,

  /// Explicit-sign rendering (e.g. `"+12%"` in en-US, `"-12%"` for negatives).
  explicitSign,
}
