// Generator for the `_with_provider` factory variants we need to add to
// our local IDL patches under `vendor/icu4x/ffi/capi/src/`.
//
// One-shot scaffolding tool — emits Rust source snippets to stdout. Each
// snippet is a parallel `_with_provider` factory that mirrors the
// existing compiled-data factory but takes a `&DataProvider` first arg
// and calls the upstream `try_new_*_with_buffer_provider` Rust ctor.
//
// We don't auto-edit the IDL files — too easy to corrupt them. Instead
// we print, eyeball, and paste once.
//
// Run:
//   fvm dart run tool/gen_idl_provider_patches.dart [--target=relative_time|currency|percent|units|all]
//
// Default: `all`. Output is stable across runs.

import 'dart:io';

void main(List<String> args) {
  final target = _resolveTarget(args);

  switch (target) {
    case _Target.relativeTime:
      _emitRelativeTime();
    case _Target.currency:
      _emitCurrency();
    case _Target.percent:
      _emitPercent();
    case _Target.units:
      _emitUnits();
    case _Target.all:
      _emitBanner('relative_time_formatter.rs');
      _emitRelativeTime();
      _emitBanner('currency_formatter.rs (CurrencyFormatter)');
      _emitCurrency();
      _emitBanner('percent_formatter.rs');
      _emitPercent();
      _emitBanner('units_formatter.rs');
      _emitUnits();
  }
}

// ---- emitters --------------------------------------------------------

void _emitRelativeTime() {
  // Cross-product of 3 widths × 8 units = 24 factories.
  // Keep order matching the existing file: long block, short block, narrow block.
  const widths = ['long', 'short', 'narrow'];
  const units = [
    'second',
    'minute',
    'hour',
    'day',
    'week',
    'month',
    'quarter',
    'year',
  ];

  for (final width in widths) {
    stdout.writeln(
      '        // ---- ${_caps(width)} (with_provider) ----------------------------',
    );
    stdout.writeln();
    for (final unit in units) {
      final name = '${width}_$unit';
      stdout.writeln('        #[cfg(feature = "buffer_provider")]');
      stdout.writeln(
        '        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "${name}_with_provider")]',
      );
      stdout.writeln('        pub fn create_${name}_with_provider(');
      stdout.writeln('            provider: &DataProvider,');
      stdout.writeln('            locale: &Locale,');
      stdout.writeln('            numeric: Option<RelativeTimeNumeric>,');
      stdout.writeln(
        '        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {',
      );
      stdout.writeln(
        '            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);',
      );
      stdout.writeln(
        '            let mut options = RelativeTimeFormatterOptions::default();',
      );
      stdout.writeln(
        '            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);',
      );
      stdout.writeln('            Ok(Box::new(RelativeTimeFormatterFfi(');
      stdout.writeln(
        '                RelativeTimeFormatter::try_new_${name}_with_buffer_provider(',
      );
      stdout.writeln('                    provider.get()?,');
      stdout.writeln('                    prefs,');
      stdout.writeln('                    options,');
      stdout.writeln('                )?,');
      stdout.writeln('            )))');
      stdout.writeln('        }');
      stdout.writeln();
    }
  }
}

void _emitCurrency() {
  // Two impls in this file:
  //   - impl CurrencyFormatter — `create_with_width(locale, width)`.
  //     Adding: `create_with_width_with_provider`.
  //   - impl LongCurrencyFormatter — `create_for_currency(locale, currency_code)`.
  //     Adding: `create_for_currency_with_provider`.
  //
  // The two snippets are emitted as separate sections because they go
  // into separate `impl` blocks. The splice has to handle that.

  stdout.writeln('// ==== INSERT INTO impl CurrencyFormatter ====');
  stdout.writeln(
    '        // ---- CurrencyFormatter (with_provider) -----------------------',
  );
  stdout.writeln();
  stdout.writeln('        #[cfg(feature = "buffer_provider")]');
  stdout.writeln(
    '        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "with_width_with_provider")]',
  );
  stdout.writeln('        pub fn create_with_width_with_provider(');
  stdout.writeln('            provider: &DataProvider,');
  stdout.writeln('            locale: &Locale,');
  stdout.writeln('            width: Option<CurrencyWidth>,');
  stdout.writeln('        ) -> Result<Box<CurrencyFormatter>, DataError> {');
  stdout.writeln(
    '            let prefs = CurrencyFormatterPreferences::from(&locale.0);',
  );
  stdout.writeln(
    '            let mut options = CurrencyFormatterOptions::default();',
  );
  stdout.writeln(
    '            options.width = width.map(Into::into).unwrap_or(Width::Short);',
  );
  stdout.writeln('            Ok(Box::new(CurrencyFormatter(');
  stdout.writeln(
    '                icu_experimental::dimension::currency::formatter::CurrencyFormatter::try_new_with_buffer_provider(',
  );
  stdout.writeln('                    provider.get()?,');
  stdout.writeln('                    prefs,');
  stdout.writeln('                    options,');
  stdout.writeln('                )?,');
  stdout.writeln('            )))');
  stdout.writeln('        }');
  stdout.writeln();
  stdout.writeln('// ==== INSERT INTO impl LongCurrencyFormatter ====');
  stdout.writeln(
    '        // ---- LongCurrencyFormatter (with_provider) -------------------',
  );
  stdout.writeln();
  stdout.writeln('        #[cfg(feature = "buffer_provider")]');
  stdout.writeln(
    '        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "for_currency_with_provider")]',
  );
  stdout.writeln('        pub fn create_for_currency_with_provider(');
  stdout.writeln('            provider: &DataProvider,');
  stdout.writeln('            locale: &Locale,');
  stdout.writeln('            currency_code: &DiplomatStr,');
  stdout.writeln(
    '        ) -> Result<Box<LongCurrencyFormatter>, DataError> {',
  );
  stdout.writeln(
    '            let Some(code) = parse_currency_code(currency_code) else {',
  );
  stdout.writeln('                return Err(DataError::InvalidRequest);');
  stdout.writeln('            };');
  stdout.writeln(
    '            let prefs = CurrencyFormatterPreferences::from(&locale.0);',
  );
  stdout.writeln('            Ok(Box::new(LongCurrencyFormatter(');
  stdout.writeln(
    '                icu_experimental::dimension::currency::long_formatter::LongCurrencyFormatter::try_new_with_buffer_provider(',
  );
  stdout.writeln('                    provider.get()?,');
  stdout.writeln('                    prefs,');
  stdout.writeln('                    &code,');
  stdout.writeln('                )?,');
  stdout.writeln('            )))');
  stdout.writeln('        }');
  stdout.writeln();
}

void _emitPercent() {
  // PercentFormatter — `create_with_display(locale, display)`.
  // Adding: `create_with_display_with_provider`.
  stdout.writeln(
    '        // ---- PercentFormatter (with_provider) ------------------------',
  );
  stdout.writeln();
  stdout.writeln('        #[cfg(feature = "buffer_provider")]');
  stdout.writeln(
    '        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "with_display_with_provider")]',
  );
  stdout.writeln('        pub fn create_with_display_with_provider(');
  stdout.writeln('            provider: &DataProvider,');
  stdout.writeln('            locale: &Locale,');
  stdout.writeln('            display: Option<PercentDisplay>,');
  stdout.writeln('        ) -> Result<Box<PercentFormatter>, DataError> {');
  stdout.writeln(
    '            let prefs = PercentFormatterPreferences::from(&locale.0);',
  );
  stdout.writeln(
    '            let mut options = PercentFormatterOptions::default();',
  );
  stdout.writeln(
    '            options.display = display.map(Into::into).unwrap_or(Display::Standard);',
  );
  stdout.writeln('            Ok(Box::new(PercentFormatter(');
  stdout.writeln(
    '                icu_experimental::dimension::percent::formatter::PercentFormatter::try_new_with_buffer_provider(',
  );
  stdout.writeln('                    provider.get()?,');
  stdout.writeln('                    prefs,');
  stdout.writeln('                    options,');
  stdout.writeln('                )?,');
  stdout.writeln('            )))');
  stdout.writeln('        }');
  stdout.writeln();
}

void _emitUnits() {
  // UnitsFormatter — `create_for_unit(locale, unit_identifier, width)`.
  // Adding: `create_for_unit_with_provider`.
  stdout.writeln(
    '        // ---- UnitsFormatter (with_provider) --------------------------',
  );
  stdout.writeln();
  stdout.writeln('        #[cfg(feature = "buffer_provider")]');
  stdout.writeln(
    '        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "for_unit_with_provider")]',
  );
  stdout.writeln('        pub fn create_for_unit_with_provider(');
  stdout.writeln('            provider: &DataProvider,');
  stdout.writeln('            locale: &Locale,');
  stdout.writeln('            unit_identifier: &DiplomatStr,');
  stdout.writeln('            width: Option<UnitsWidth>,');
  stdout.writeln('        ) -> Result<Box<UnitsFormatter>, DataError> {');
  stdout.writeln(
    '            let unit = match core::str::from_utf8(unit_identifier) {',
  );
  stdout.writeln('                Ok(s) => s,');
  stdout.writeln(
    '                Err(_) => return Err(DataError::InvalidRequest),',
  );
  stdout.writeln('            };');
  stdout.writeln(
    '            let prefs = UnitsFormatterPreferences::from(&locale.0);',
  );
  stdout.writeln(
    '            let mut options = UnitsFormatterOptions::default();',
  );
  stdout.writeln(
    '            options.width = width.map(Into::into).unwrap_or(Width::Short);',
  );
  stdout.writeln('            Ok(Box::new(UnitsFormatter(');
  stdout.writeln(
    '                icu_experimental::dimension::units::formatter::UnitsFormatter::try_new_with_buffer_provider(',
  );
  stdout.writeln('                    provider.get()?,');
  stdout.writeln('                    prefs,');
  stdout.writeln('                    unit,');
  stdout.writeln('                    options,');
  stdout.writeln('                )?,');
  stdout.writeln('            )))');
  stdout.writeln('        }');
  stdout.writeln();
}

// ---- helpers ---------------------------------------------------------

void _emitBanner(String fileName) {
  stdout.writeln(
    '// ════════════════════════════════════════════════════════════════',
  );
  stdout.writeln('// $fileName');
  stdout.writeln(
    '// ════════════════════════════════════════════════════════════════',
  );
  stdout.writeln();
}

String _caps(String s) => s[0].toUpperCase() + s.substring(1);

enum _Target { relativeTime, currency, percent, units, all }

_Target _resolveTarget(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--target=')) {
      final value = arg.substring('--target='.length);
      return switch (value) {
        'relative_time' || 'relativeTime' => _Target.relativeTime,
        'currency' => _Target.currency,
        'percent' => _Target.percent,
        'units' => _Target.units,
        'all' => _Target.all,
        _ => throw ArgumentError('Unknown --target value: $value'),
      };
    }
    if (arg == '--help' || arg == '-h') {
      stderr.writeln(
        'Usage: fvm dart run tool/gen_idl_provider_patches.dart '
        '[--target=relative_time|currency|percent|units|all]',
      );
      stderr.writeln('Default target: all.');
      exit(2);
    }
  }
  return _Target.all;
}
