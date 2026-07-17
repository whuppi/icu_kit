// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).
//
// ── icu_kit patch (entire file) ── exposes CurrencyFormatter + LongCurrencyFormatter
// from icu_experimental via Diplomat. Mirrors the design of decimal.rs.
// Will be removed when upstream lands the unified CurrencyDisplay API
// (tracked: unicode-org/icu4x PR #7789).

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
    use icu_experimental::dimension::currency::formatter::CurrencyFormatterPreferences;
    use icu_experimental::dimension::currency::options::{
        CurrencyFormatterOptions, Width,
    };
    use icu_experimental::dimension::currency::CurrencyCode;
    use tinystr::TinyAsciiStr;
    use writeable::Writeable;

    #[diplomat::opaque]
    /// An ICU4X currency formatter object that renders a [`Decimal`] with a
    /// short or narrow currency symbol (e.g. "$1.00" or "US$1").
    ///
    /// For long-form ("1 US dollar") use [`LongCurrencyFormatter`].
    #[diplomat::rust_link(
        icu::experimental::dimension::currency::formatter::CurrencyFormatter,
        Struct
    )]
    pub struct CurrencyFormatter(
        pub icu_experimental::dimension::currency::formatter::CurrencyFormatter,
    );

    #[diplomat::opaque]
    /// An ICU4X long-form currency formatter pinned to one currency
    /// (e.g. "1 US dollar" / "2 US dollars" with locale-aware plural form).
    #[diplomat::rust_link(
        icu::experimental::dimension::currency::long_formatter::LongCurrencyFormatter,
        Struct
    )]
    pub struct LongCurrencyFormatter(
        pub icu_experimental::dimension::currency::long_formatter::LongCurrencyFormatter,
    );

    /// Width controlling the symbol form for [`CurrencyFormatter`].
    /// Mirrors `icu_experimental::dimension::currency::options::Width`.
    #[diplomat::rust_link(
        icu::experimental::dimension::currency::options::Width,
        Enum
    )]
    #[diplomat::enum_convert(
        icu_experimental::dimension::currency::options::Width,
        needs_wildcard
    )]
    #[non_exhaustive]
    pub enum CurrencyWidth {
        #[diplomat::attr(auto, default)]
        Short,
        Narrow,
        /// ISO 4217 code display (e.g. "USD 1.00"). icu_kit patch for
        /// ECMA-402 `currencyDisplay: "code"`.
        Code,
    }

    impl CurrencyFormatter {
        /// Creates a new [`CurrencyFormatter`] using compiled CLDR data.
        ///
        /// Returns an error if the locale has no currency data.
        #[cfg(feature = "compiled_data")]
        #[diplomat::rust_link(
            icu::experimental::dimension::currency::formatter::CurrencyFormatter::try_new,
            FnInStruct
        )]
        #[diplomat::attr(
            all(supports = fallible_constructors, supports = named_constructors),
            named_constructor = "with_width"
        )]
        #[diplomat::demo(default_constructor)]
        pub fn create_with_width(
            locale: &Locale,
            width: Option<CurrencyWidth>,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<CurrencyFormatter>, DataError> {
            let prefs = CurrencyFormatterPreferences::from(&locale.0);
            let mut options = CurrencyFormatterOptions::default();
            options.width = width.map(Into::into).unwrap_or(Width::Short);
            options.grouping_strategy = grouping_strategy.map(Into::into);
            Ok(Box::new(CurrencyFormatter(
                icu_experimental::dimension::currency::formatter::CurrencyFormatter::try_new(
                    prefs, options,
                )?,
            )))
        }

        // ---- CurrencyFormatter (with_provider) -----------------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "with_width_with_provider")]
        pub fn create_with_width_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            width: Option<CurrencyWidth>,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<CurrencyFormatter>, DataError> {
            let prefs = CurrencyFormatterPreferences::from(&locale.0);
            let mut options = CurrencyFormatterOptions::default();
            options.width = width.map(Into::into).unwrap_or(Width::Short);
            options.grouping_strategy = grouping_strategy.map(Into::into);
            Ok(Box::new(CurrencyFormatter(
                icu_experimental::dimension::currency::formatter::CurrencyFormatter::try_new_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        /// Format `value` with `currency_code` (3-letter ISO 4217, e.g. "USD").
        ///
        /// Returns an empty string if `currency_code` is not a valid 3-letter
        /// ASCII code; callers should validate first.
        #[diplomat::rust_link(
            icu::experimental::dimension::currency::formatter::CurrencyFormatter::format_fixed_decimal,
            FnInStruct
        )]
        pub fn format(
            &self,
            value: &Decimal,
            currency_code: &DiplomatStr,
            write: &mut DiplomatWrite,
        ) {
            let Some(code) = parse_currency_code(currency_code) else {
                return;
            };
            let _ = self.0.format_fixed_decimal(&value.0, &code).write_to(write);
        }

        /// Format `value` with `currency_code` into typed parts (ECMA-402
        /// `formatToParts` shape): the symbol as a `currency` part, the number
        /// as integer / group / decimal / fraction. Returns an EMPTY part list
        /// for an invalid currency code (same as `format`'s empty output).
        pub fn format_to_parts(
            &self,
            value: &Decimal,
            currency_code: &DiplomatStr,
        ) -> Box<crate::unstable::formatted_parts::ffi::FormattedNumberParts> {
            use crate::unstable::formatted_parts::ffi::FormattedNumberParts;
            let Some(code) = parse_currency_code(currency_code) else {
                return Box::new(FormattedNumberParts(alloc::vec::Vec::new()));
            };
            let parts = crate::unstable::formatted_parts::collect_parts(
                &self.0.format_fixed_decimal(&value.0, &code),
                crate::unstable::formatted_parts::GapKind::Currency,
            );
            Box::new(FormattedNumberParts(parts))
        }
    }

    impl LongCurrencyFormatter {
        /// Creates a new [`LongCurrencyFormatter`] for one currency using
        /// compiled CLDR data.
        ///
        /// Returns `Err(DataError)` if the locale or currency has no data.
        #[cfg(feature = "compiled_data")]
        #[diplomat::rust_link(
            icu::experimental::dimension::currency::long_formatter::LongCurrencyFormatter::try_new,
            FnInStruct
        )]
        #[diplomat::attr(
            all(supports = fallible_constructors, supports = named_constructors),
            named_constructor = "for_currency"
        )]
        #[diplomat::demo(default_constructor)]
        pub fn create_for_currency(
            locale: &Locale,
            currency_code: &DiplomatStr,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<LongCurrencyFormatter>, DataError> {
            let Some(code) = parse_currency_code(currency_code) else {
                return Err(DataError::InvalidRequest);
            };
            let prefs = CurrencyFormatterPreferences::from(&locale.0);
            Ok(Box::new(LongCurrencyFormatter(
                icu_experimental::dimension::currency::long_formatter::LongCurrencyFormatter::try_new(
                    prefs, &code, grouping_strategy.map(Into::into),
                )?,
            )))
        }

        // ---- LongCurrencyFormatter (with_provider) -------------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "for_currency_with_provider")]
        pub fn create_for_currency_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            currency_code: &DiplomatStr,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<LongCurrencyFormatter>, DataError> {
            let Some(code) = parse_currency_code(currency_code) else {
                return Err(DataError::InvalidRequest);
            };
            let prefs = CurrencyFormatterPreferences::from(&locale.0);
            Ok(Box::new(LongCurrencyFormatter(
                icu_experimental::dimension::currency::long_formatter::LongCurrencyFormatter::try_new_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    &code,
                    grouping_strategy.map(Into::into),
                )?,
            )))
        }

        /// Format `value` using the locale-specific plural form
        /// (e.g. "1 US dollar" / "2 US dollars").
        #[diplomat::rust_link(
            icu::experimental::dimension::currency::long_formatter::LongCurrencyFormatter::format_fixed_decimal,
            FnInStruct
        )]
        pub fn format(&self, value: &Decimal, write: &mut DiplomatWrite) {
            let _ = self.0.format_fixed_decimal(&value.0).write_to(write);
        }

        /// Format `value` into typed parts (ECMA-402 `formatToParts` shape):
        /// the long currency name as a single `currency` part, the number as
        /// integer / group / decimal / fraction.
        pub fn format_to_parts(
            &self,
            value: &Decimal,
        ) -> Box<crate::unstable::formatted_parts::ffi::FormattedNumberParts> {
            Box::new(crate::unstable::formatted_parts::ffi::FormattedNumberParts(
                crate::unstable::formatted_parts::collect_parts(
                    &self.0.format_fixed_decimal(&value.0),
                    crate::unstable::formatted_parts::GapKind::Currency,
                ),
            ))
        }
    }

    /// Parse a 3-letter ASCII currency code (`"USD"`, `"EUR"`) into a
    /// [`CurrencyCode`]. Returns `None` if not exactly 3 ASCII characters.
    fn parse_currency_code(bytes: &DiplomatStr) -> Option<CurrencyCode> {
        let s = TinyAsciiStr::<3>::try_from_utf8(bytes).ok()?;
        Some(CurrencyCode(s))
    }
}
