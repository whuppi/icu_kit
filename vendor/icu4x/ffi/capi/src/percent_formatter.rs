// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).
//
// ── icu_kit patch (entire file) ── exposes PercentFormatter from icu_experimental
// via Diplomat. Mirrors the design of currency_formatter.rs.
// Will be removed when upstream lands the unified percent/currency/unit
// API in stable icu (tracked: same migration as PR #7789's CurrencyDisplay).

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
    use icu_experimental::dimension::percent::formatter::PercentFormatterPreferences;
    use icu_experimental::dimension::percent::options::{
        Display, PercentFormatterOptions,
    };
    use writeable::Writeable;

    #[diplomat::opaque]
    /// An ICU4X percent formatter object that renders a [`Decimal`] with the
    /// locale's percent sign (e.g. "12.34%" in en-US, "12,34 %" in fr).
    #[diplomat::rust_link(
        icu::experimental::dimension::percent::formatter::PercentFormatter,
        Struct
    )]
    pub struct PercentFormatter(
        pub icu_experimental::dimension::percent::formatter::PercentFormatter<
            icu_decimal::DecimalFormatter,
        >,
    );

    /// Display style controlling how the percent value is rendered.
    /// Mirrors `icu_experimental::dimension::percent::options::Display`.
    #[diplomat::rust_link(
        icu::experimental::dimension::percent::options::Display,
        Enum
    )]
    #[diplomat::enum_convert(
        icu_experimental::dimension::percent::options::Display,
        needs_wildcard
    )]
    #[non_exhaustive]
    pub enum PercentDisplay {
        /// Locale-standard rendering (e.g. "12%").
        #[diplomat::attr(auto, default)]
        Standard,
        /// Approximate-value rendering (e.g. "~12%").
        Approximate,
        /// Explicit-sign rendering (e.g. "+12%").
        ExplicitSign,
    }

    impl PercentFormatter {
        /// Creates a new [`PercentFormatter`] using compiled CLDR data.
        ///
        /// Returns an error if the locale has no percent data.
        #[cfg(feature = "compiled_data")]
        #[diplomat::rust_link(
            icu::experimental::dimension::percent::formatter::PercentFormatter::try_new,
            FnInStruct
        )]
        #[diplomat::attr(
            all(supports = fallible_constructors, supports = named_constructors),
            named_constructor = "with_display"
        )]
        #[diplomat::demo(default_constructor)]
        pub fn create_with_display(
            locale: &Locale,
            display: Option<PercentDisplay>,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<PercentFormatter>, DataError> {
            let prefs = PercentFormatterPreferences::from(&locale.0);
            let mut options = PercentFormatterOptions::default();
            options.display = display.map(Into::into).unwrap_or(Display::Standard);
            options.grouping_strategy = grouping_strategy.map(Into::into);
            Ok(Box::new(PercentFormatter(
                icu_experimental::dimension::percent::formatter::PercentFormatter::try_new(
                    prefs, options,
                )?,
            )))
        }

        // ---- PercentFormatter (with_provider) ------------------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "with_display_with_provider")]
        pub fn create_with_display_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            display: Option<PercentDisplay>,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<PercentFormatter>, DataError> {
            let prefs = PercentFormatterPreferences::from(&locale.0);
            let mut options = PercentFormatterOptions::default();
            options.display = display.map(Into::into).unwrap_or(Display::Standard);
            options.grouping_strategy = grouping_strategy.map(Into::into);
            Ok(Box::new(PercentFormatter(
                icu_experimental::dimension::percent::formatter::PercentFormatter::try_new_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        /// Format `value` as a percent. The decimal is interpreted as already
        /// scaled (i.e. `0.12` → "0.12%", not "12%"). Pre-multiply by 100 in
        /// Dart if you want ECMA-402 percent semantics ("12%" from `0.12`).
        #[diplomat::rust_link(
            icu::experimental::dimension::percent::formatter::PercentFormatter::format,
            FnInStruct
        )]
        pub fn format(&self, value: &Decimal, write: &mut DiplomatWrite) {
            let _ = self.0.format(&value.0).write_to(write);
        }

        /// Format `value` into typed parts (ECMA-402 `formatToParts` shape):
        /// integer / group / decimal / fraction / percentSign / sign.
        pub fn format_to_parts(
            &self,
            value: &Decimal,
        ) -> Box<crate::unstable::formatted_parts::ffi::FormattedNumberParts> {
            Box::new(crate::unstable::formatted_parts::ffi::FormattedNumberParts(
                crate::unstable::formatted_parts::collect_parts(
                    &self.0.format(&value.0),
                    crate::unstable::formatted_parts::GapKind::Percent,
                ),
            ))
        }
    }
}
