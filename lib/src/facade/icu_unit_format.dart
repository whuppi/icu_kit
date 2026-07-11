import 'package:meta/meta.dart';

import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;
import 'icu_locale.dart';
import 'icu_number_format.dart' show toDecimalFfi;

/// EXPERIMENTAL — locale-aware unit formatting.
///
/// Backed by ICU4X's `icu_experimental::dimension::units::UnitsFormatter`,
/// exposed via a local Diplomat IDL patch. Pinned to one CLDR unit
/// identifier for the formatter's lifetime — re-create the formatter to
/// switch units.
///
/// **CLDR unit identifiers**, not UCUM. See
/// <https://www.unicode.org/reports/tr35/tr35-general.html#Unit_Elements>.
/// Examples:
///   * `"meter"`, `"kilometer"`, `"mile"`, `"foot"`
///   * `"hour"`, `"minute"`, `"second"`, `"millisecond"`
///   * `"kilogram"`, `"gram"`, `"pound"`
///   * `"celsius"`, `"fahrenheit"`
///   * Compound: `"kilometer-per-hour"`, `"meter-per-second"`,
///     `"liter-per-100-kilometer"`
///
/// Plural-correct rendering — `format(1)` and `format(2)` produce locale's
/// singular vs plural form ("1 hour" / "2 hours" in en-US).
///
/// Three width modes:
///   * [IcuUnitWidth.long]   — `"5 hours"`
///   * [IcuUnitWidth.short]  — `"5 hr"` (default)
///   * [IcuUnitWidth.narrow] — `"5 h"`
///
/// Example:
///
/// ```dart
/// final hours = IcuUnitFormat(locale: 'en-US', unit: 'hour');
/// hours.format(1);                       // "1 hr"
/// hours.format(2);                       // "2 hr"
///
/// final hoursLong = IcuUnitFormat(
///   locale: 'en-US', unit: 'hour', width: IcuUnitWidth.long);
/// hoursLong.format(1);                   // "1 hour"
/// hoursLong.format(2);                   // "2 hours"
///
/// final kmh = IcuUnitFormat(
///   locale: 'fr', unit: 'kilometer-per-hour');
/// kmh.format(120);                       // "120 km/h"
/// ```
@experimental
final class IcuUnitFormat {
  IcuUnitFormat._(this._ffi, this._unit);

  /// EXPERIMENTAL — create a unit formatter pinned to [unit] for [locale].
  ///
  /// [unit] is a CLDR unit identifier (e.g. `"meter"`, `"hour"`,
  /// `"kilometer-per-hour"`). Returns an error if the locale or unit has
  /// no data.
  ///
  /// [width] selects the rendering width (default [IcuUnitWidth.short]).
  @experimental
  factory IcuUnitFormat({
    required String locale,
    required String unit,
    IcuUnitWidth width = IcuUnitWidth.short,
  }) {
    if (unit.isEmpty) {
      throw IcuDataError(
        'Unit identifier must not be empty',
        locale: locale,
        marker: 'UnitsFormatter',
      );
    }
    final loc = IcuLocale.parse(locale);
    try {
      final formatter = dispatch.unitsFormatterForUnit(
        locale,
        loc.ffi,
        unit,
        switch (width) {
          IcuUnitWidth.long => icu.UnitsWidth.long,
          IcuUnitWidth.short => icu.UnitsWidth.short,
          IcuUnitWidth.narrow => icu.UnitsWidth.narrow,
        },
      );
      return IcuUnitFormat._(formatter, unit);
    } catch (e) {
      throw IcuDataError(
        'Unit formatter unavailable for $locale + "$unit": $e',
        locale: locale,
        marker: 'UnitsFormatter',
      );
    }
  }
  final icu.UnitsFormatter _ffi;
  final String _unit;

  /// EXPERIMENTAL — format [value] with this formatter's pinned unit.
  ///
  /// Returns the locale-correct plural form
  /// (e.g. `"1 hour"` / `"2 hours"` in en-US).
  @experimental
  String format(num value) => _ffi.format(toDecimalFfi(value));

  /// EXPERIMENTAL — the CLDR unit identifier this formatter is pinned to.
  @experimental
  String get unit => _unit;
}

/// EXPERIMENTAL — width for [IcuUnitFormat].
///
/// Mirrors ICU4X's `Width` enum.
@experimental
enum IcuUnitWidth {
  /// Long form (e.g. `"5 hours"` in en-US).
  long,

  /// Short form (e.g. `"5 hr"` in en-US). Default.
  short,

  /// Narrow form (e.g. `"5 h"` in en-US). May be ambiguous.
  narrow,
}
