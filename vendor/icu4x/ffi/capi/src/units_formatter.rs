// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).
//
// ── icu_kit patch (entire file) ── exposes UnitsFormatter from icu_experimental
// via Diplomat. Mirrors the design of currency_formatter.rs.
// Will be removed when upstream lands the unified percent/currency/unit
// API in stable icu (tracked: same migration as PR #7789).

#[diplomat::bridge]
#[diplomat::abi_rename = "icu4x_{0}_mv1"]
pub mod ffi {
    use alloc::boxed::Box;

    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use crate::unstable::locale_core::ffi::Locale;
    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use crate::unstable::decimal::ffi::DecimalGroupingStrategy;
    #[cfg(feature = "buffer_provider")]
    use crate::unstable::provider::ffi::DataProvider;
    use crate::unstable::{errors::ffi::DataError, fixed_decimal::ffi::Decimal};
    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use icu_experimental::dimension::units::formatter::UnitsFormatterPreferences;
    use icu_experimental::dimension::units::options::{
        UnitsFormatterOptions, Width,
    };
    use writeable::Writeable;

    #[diplomat::opaque]
    /// An ICU4X unit formatter pinned to a single CLDR unit identifier
    /// (e.g. "meter", "kilometer-per-hour", "hour"). Renders values like
    /// "5 hours", "5 hr", "5 h" depending on width.
    #[diplomat::rust_link(
        icu::experimental::dimension::units::formatter::UnitsFormatter,
        Struct
    )]
    pub struct UnitsFormatter(
        pub icu_experimental::dimension::units::formatter::UnitsFormatter,
    );

    /// Width controlling unit-name rendering. Mirrors
    /// `icu_experimental::dimension::units::options::Width`.
    #[diplomat::rust_link(
        icu::experimental::dimension::units::options::Width,
        Enum
    )]
    #[diplomat::enum_convert(
        icu_experimental::dimension::units::options::Width,
        needs_wildcard
    )]
    #[non_exhaustive]
    pub enum UnitsWidth {
        /// "5 hours" (en-US).
        Long,
        /// "5 hr" (en-US). Default.
        #[diplomat::attr(auto, default)]
        Short,
        /// "5 h" (en-US).
        Narrow,
    }

    impl UnitsFormatter {
        /// Creates a new [`UnitsFormatter`] for `unit_identifier` using compiled
        /// CLDR data.
        ///
        /// `unit_identifier` is a CLDR unit identifier (e.g. "meter",
        /// "kilometer", "kilometer-per-hour", "hour"). Returns an error if the
        /// locale or unit has no data.
        #[cfg(feature = "compiled_data")]
        #[diplomat::rust_link(
            icu::experimental::dimension::units::formatter::UnitsFormatter::try_new,
            FnInStruct
        )]
        #[diplomat::attr(
            all(supports = fallible_constructors, supports = named_constructors),
            named_constructor = "for_unit"
        )]
        #[diplomat::demo(default_constructor)]
        pub fn create_for_unit(
            locale: &Locale,
            unit_identifier: &DiplomatStr,
            width: Option<UnitsWidth>,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<UnitsFormatter>, DataError> {
            // The Rust API takes &str; reject non-UTF8 unit identifiers.
            let unit = match core::str::from_utf8(unit_identifier) {
                Ok(s) => s,
                Err(_) => return Err(DataError::InvalidRequest),
            };
            let prefs = UnitsFormatterPreferences::from(&locale.0);
            let mut options = UnitsFormatterOptions::default();
            options.width = width.map(Into::into).unwrap_or(Width::Short);
            options.grouping_strategy = grouping_strategy.map(Into::into);
            Ok(Box::new(UnitsFormatter(
                icu_experimental::dimension::units::formatter::UnitsFormatter::try_new(
                    prefs, unit, options,
                )?,
            )))
        }

        // ---- UnitsFormatter (with_provider) --------------------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "for_unit_with_provider")]
        pub fn create_for_unit_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            unit_identifier: &DiplomatStr,
            width: Option<UnitsWidth>,
            grouping_strategy: Option<DecimalGroupingStrategy>,
        ) -> Result<Box<UnitsFormatter>, DataError> {
            let unit = match core::str::from_utf8(unit_identifier) {
                Ok(s) => s,
                Err(_) => return Err(DataError::InvalidRequest),
            };
            let prefs = UnitsFormatterPreferences::from(&locale.0);
            let mut options = UnitsFormatterOptions::default();
            options.width = width.map(Into::into).unwrap_or(Width::Short);
            options.grouping_strategy = grouping_strategy.map(Into::into);
            Ok(Box::new(UnitsFormatter(
                icu_experimental::dimension::units::formatter::UnitsFormatter::try_new_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    unit,
                    options,
                )?,
            )))
        }

        /// Format `value` with the unit. Returns the locale-correct plural
        /// form (e.g. "1 hour" / "2 hours" in en-US).
        #[diplomat::rust_link(
            icu::experimental::dimension::units::formatter::UnitsFormatter::format_fixed_decimal,
            FnInStruct
        )]
        pub fn format(&self, value: &Decimal, write: &mut DiplomatWrite) {
            let _ = self.0.format_fixed_decimal(&value.0).write_to(write);
        }

        /// Format `value` into typed parts (ECMA-402 `formatToParts` shape):
        /// integer / group / decimal / fraction, with the unit name as a
        /// single `unit` part and surrounding spacing as `literal`.
        pub fn format_to_parts(
            &self,
            value: &Decimal,
        ) -> Box<crate::unstable::formatted_parts::ffi::FormattedNumberParts> {
            Box::new(crate::unstable::formatted_parts::ffi::FormattedNumberParts(
                crate::unstable::formatted_parts::collect_parts(
                    &self.0.format_fixed_decimal(&value.0),
                    crate::unstable::formatted_parts::GapKind::Unit,
                ),
            ))
        }
    }

}
