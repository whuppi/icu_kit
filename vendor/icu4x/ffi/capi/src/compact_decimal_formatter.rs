// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).
//
// ── icu_kit patch (entire file) ── exposes CompactDecimalFormatter
// (icu_decimal's `unstable` feature) via Diplomat, for ECMA-402
// `notation: "compact"`. Mirrors the design of currency_formatter.rs.

#[diplomat::bridge]
#[diplomat::abi_rename = "icu4x_{0}_mv1"]
pub mod ffi {
    use alloc::boxed::Box;

    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use crate::unstable::decimal::ffi::DecimalGroupingStrategy;
    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use crate::unstable::locale_core::ffi::Locale;
    #[cfg(feature = "buffer_provider")]
    use crate::unstable::provider::ffi::DataProvider;
    use crate::unstable::{errors::ffi::DataError, fixed_decimal::ffi::Decimal};
    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use icu_decimal::options::CompactDecimalFormatterOptions;
    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use icu_decimal::preferences::CompactDecimalFormatterPreferences;
    use writeable::Writeable;

    #[diplomat::opaque]
    /// An ICU4X compact decimal formatter — renders a [`Decimal`] in
    /// CLDR compact notation ("1.2M" short, "1.2 million" long).
    /// ECMA-402 `notation: "compact"` with `compactDisplay` chosen at
    /// construction.
    #[diplomat::rust_link(icu::decimal::CompactDecimalFormatter, Struct)]
    pub struct CompactDecimalFormatter(pub icu_decimal::CompactDecimalFormatter);

    impl CompactDecimalFormatter {
        /// Creates a short-form ("1.2M") compact formatter from compiled
        /// CLDR data. `grouping_strategy` defaults to the compact
        /// formatter's own default (Min2) when not given.
        #[cfg(feature = "compiled_data")]
        #[diplomat::rust_link(
            icu::decimal::CompactDecimalFormatter::try_new_short,
            FnInStruct
        )]
        #[diplomat::attr(
            all(supports = fallible_constructors, supports = named_constructors),
            named_constructor = "short"
        )]
        #[diplomat::demo(default_constructor)]
        pub fn create_short(
            locale: &Locale,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<CompactDecimalFormatter>, DataError> {
            let prefs = CompactDecimalFormatterPreferences::from(&locale.0);
            let mut options = CompactDecimalFormatterOptions::default();
            if let Some(g) = grouping_strategy {
                options.grouping_strategy = Some(g.into());
            }
            Ok(Box::new(CompactDecimalFormatter(
                icu_decimal::CompactDecimalFormatter::try_new_short(prefs, options)?,
            )))
        }

        /// Creates a long-form ("1.2 million") compact formatter from
        /// compiled CLDR data.
        #[cfg(feature = "compiled_data")]
        #[diplomat::rust_link(
            icu::decimal::CompactDecimalFormatter::try_new_long,
            FnInStruct
        )]
        #[diplomat::attr(
            all(supports = fallible_constructors, supports = named_constructors),
            named_constructor = "long"
        )]
        pub fn create_long(
            locale: &Locale,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<CompactDecimalFormatter>, DataError> {
            let prefs = CompactDecimalFormatterPreferences::from(&locale.0);
            let mut options = CompactDecimalFormatterOptions::default();
            if let Some(g) = grouping_strategy {
                options.grouping_strategy = Some(g.into());
            }
            Ok(Box::new(CompactDecimalFormatter(
                icu_decimal::CompactDecimalFormatter::try_new_long(prefs, options)?,
            )))
        }

        // ---- CompactDecimalFormatter (with_provider) -----------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_with_provider")]
        pub fn create_short_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<CompactDecimalFormatter>, DataError> {
            let prefs = CompactDecimalFormatterPreferences::from(&locale.0);
            let mut options = CompactDecimalFormatterOptions::default();
            if let Some(g) = grouping_strategy {
                options.grouping_strategy = Some(g.into());
            }
            Ok(Box::new(CompactDecimalFormatter(
                icu_decimal::CompactDecimalFormatter::try_new_short_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_with_provider")]
        pub fn create_long_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<CompactDecimalFormatter>, DataError> {
            let prefs = CompactDecimalFormatterPreferences::from(&locale.0);
            let mut options = CompactDecimalFormatterOptions::default();
            if let Some(g) = grouping_strategy {
                options.grouping_strategy = Some(g.into());
            }
            Ok(Box::new(CompactDecimalFormatter(
                icu_decimal::CompactDecimalFormatter::try_new_long_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        /// Format `value` in compact notation. The formatter applies CLDR
        /// compact rounding to the significand internally.
        #[diplomat::rust_link(
            icu::decimal::CompactDecimalFormatter::format,
            FnInStruct
        )]
        pub fn format(&self, value: &Decimal, write: &mut DiplomatWrite) {
            let _ = self.0.format(&value.0).write_to(write);
        }

        /// Format `value` into typed parts (ECMA-402 `formatToParts`
        /// shape): the number as integer / decimal / fraction, the
        /// abbreviation as a `compact` part.
        pub fn format_to_parts(
            &self,
            value: &Decimal,
        ) -> Box<crate::unstable::formatted_parts::ffi::FormattedNumberParts> {
            Box::new(crate::unstable::formatted_parts::ffi::FormattedNumberParts(
                crate::unstable::formatted_parts::collect_parts(
                    &self.0.format(&value.0),
                    crate::unstable::formatted_parts::GapKind::Compact,
                ),
            ))
        }
    }
}
