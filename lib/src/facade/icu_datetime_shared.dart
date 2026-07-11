// Shared enums + binding-enum mappers used by IcuDateFormat, IcuTimeFormat,
// IcuDateTimeFormat, and IcuZonedDateTimeFormat. One place so the same
// values flow across every datetime facade.

import '../runtime/bindings.dart' as icu;

/// Length presets that mirror ECMA-402's `dateStyle` / `timeStyle` option.
///
/// ICU4X 2.2 has three variants (`long`, `medium`, `short`); ECMA-402
/// adds `full` as a longer form. We map `full → long` to match the de-facto
/// JS engine behavior — there is no fifth length distinction in CLDR.
enum IcuDateLength {
  /// Longest form; maps to ICU4X `long` (see the enum doc above).
  full,

  /// Long form (e.g. "January 15, 2024" in en-US).
  long,

  /// Medium form (e.g. "Jan 15, 2024" in en-US).
  medium,

  /// Short form (e.g. "1/15/24" in en-US).
  short,
}

/// Padding behavior for numeric fields.
///
/// Mirrors ICU4X's `DateTimeAlignment`. `column` zero-pads numeric fields
/// for table-column alignment; `auto` uses locale defaults.
enum IcuDateAlignment {
  /// Locale-default widths for running text.
  auto,

  /// Zero-padded numeric fields so values line up in columns.
  column,
}

/// How the year is rendered when present.
///
/// Mirrors ICU4X's `YearStyle`:
///   * `auto` — locale defaults
///   * `full` — full year with era when locale requires it
///   * `withEra` — always show the era (e.g. "AD 2026", "令和8年")
///   * `noEra` — never show the era (numeric year only)
enum IcuYearStyle {
  /// Locale defaults; era and century shown only when needed.
  auto,

  /// Full year, era only when the locale requires it.
  full,

  /// Always show the era (e.g. "AD 2026", "令和8年").
  withEra,

  /// Never show the era (numeric year only).
  noEra,
}

/// Sub-second precision selector.
///
/// Mirrors ICU4X's `TimePrecision`:
///   * `hour` — only hour rendered
///   * `minute` — hour + minute (default for most locales)
///   * `minuteOptional` — minute shown only when non-zero
///   * `second` — hour + minute + second
///   * `subsecondN` — hour + minute + second + N digits of fractional seconds
enum IcuTimePrecision {
  /// Hour only (e.g. "3 PM").
  hour,

  /// Hour and minute (e.g. "3:05 PM") — the default for most locales.
  minute,

  /// Minute shown only when nonzero.
  minuteOptional,

  /// Hour, minute, and second (e.g. "3:05:07 PM").
  second,

  /// Seconds with 1 fractional digit.
  subsecond1,

  /// Seconds with 2 fractional digits.
  subsecond2,

  /// Seconds with 3 fractional digits.
  subsecond3,

  /// Seconds with 4 fractional digits.
  subsecond4,

  /// Seconds with 5 fractional digits.
  subsecond5,

  /// Seconds with 6 fractional digits.
  subsecond6,

  /// Seconds with 7 fractional digits.
  subsecond7,

  /// Seconds with 8 fractional digits.
  subsecond8,

  /// Seconds with 9 fractional digits.
  subsecond9,
}

// ---- binding mappers (shared by every datetime facade) ------------------

/// The [IcuDateLength] as a binding [icu.DateTimeLength]; `full`
/// collapses to `long`.
icu.DateTimeLength toFfiLength(IcuDateLength length) => switch (length) {
  IcuDateLength.full => icu.DateTimeLength.long,
  IcuDateLength.long => icu.DateTimeLength.long,
  IcuDateLength.medium => icu.DateTimeLength.medium,
  IcuDateLength.short => icu.DateTimeLength.short,
};

/// The [IcuDateAlignment] as a binding [icu.DateTimeAlignment].
icu.DateTimeAlignment? toFfiAlignment(IcuDateAlignment? a) => switch (a) {
  null => null,
  IcuDateAlignment.auto => icu.DateTimeAlignment.auto,
  IcuDateAlignment.column => icu.DateTimeAlignment.column,
};

/// The [IcuYearStyle] as a binding [icu.YearStyle].
icu.YearStyle? toFfiYearStyle(IcuYearStyle? y) => switch (y) {
  null => null,
  IcuYearStyle.auto => icu.YearStyle.auto,
  IcuYearStyle.full => icu.YearStyle.full,
  IcuYearStyle.withEra => icu.YearStyle.withEra,
  IcuYearStyle.noEra => icu.YearStyle.noEra,
};

/// The [IcuTimePrecision] as a binding [icu.TimePrecision].
icu.TimePrecision? toFfiPrecision(IcuTimePrecision? p) => switch (p) {
  null => null,
  IcuTimePrecision.hour => icu.TimePrecision.hour,
  IcuTimePrecision.minute => icu.TimePrecision.minute,
  IcuTimePrecision.minuteOptional => icu.TimePrecision.minuteOptional,
  IcuTimePrecision.second => icu.TimePrecision.second,
  IcuTimePrecision.subsecond1 => icu.TimePrecision.subsecond1,
  IcuTimePrecision.subsecond2 => icu.TimePrecision.subsecond2,
  IcuTimePrecision.subsecond3 => icu.TimePrecision.subsecond3,
  IcuTimePrecision.subsecond4 => icu.TimePrecision.subsecond4,
  IcuTimePrecision.subsecond5 => icu.TimePrecision.subsecond5,
  IcuTimePrecision.subsecond6 => icu.TimePrecision.subsecond6,
  IcuTimePrecision.subsecond7 => icu.TimePrecision.subsecond7,
  IcuTimePrecision.subsecond8 => icu.TimePrecision.subsecond8,
  IcuTimePrecision.subsecond9 => icu.TimePrecision.subsecond9,
};

/// The date portion of a Dart [DateTime] as a binding [icu.IsoDate].
icu.IsoDate isoDateFromDart(DateTime d) => icu.IsoDate(d.year, d.month, d.day);

/// The time portion of a Dart [DateTime] as a binding [icu.Time].
icu.Time timeFromDart(DateTime d) {
  final nanos = (d.millisecond * 1000 + d.microsecond) * 1000;
  return icu.Time(d.hour, d.minute, d.second, nanos);
}
