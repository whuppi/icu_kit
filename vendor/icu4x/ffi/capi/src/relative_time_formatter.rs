// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).
//
// ── icu_kit patch (entire file) ── exposes RelativeTimeFormatter from icu_experimental
// via Diplomat. Mirrors the design of decimal.rs and currency_formatter.rs.
//
// Will be removed when upstream lands the stable RelativeTimeFormatter
// API at icu_experimental → icu (currently slated for ICU4X 2.3+).

#[diplomat::bridge]
#[diplomat::abi_rename = "icu4x_{0}_mv1"]
pub mod ffi {
    use alloc::boxed::Box;

    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use crate::unstable::locale_core::ffi::Locale;
    #[cfg(feature = "buffer_provider")]
    use crate::unstable::provider::ffi::DataProvider;
    use crate::unstable::{errors::ffi::DataError, fixed_decimal::ffi::Decimal};
    #[cfg(any(feature = "compiled_data", feature = "buffer_provider"))]
    use icu_experimental::relativetime::RelativeTimeFormatterPreferences;
    use icu_experimental::relativetime::{
        options::{Numeric, RelativeTimeFormatterOptions},
        RelativeTimeFormatter,
    };
    use writeable::Writeable;

    #[diplomat::opaque]
    /// An ICU4X relative-time formatter pinned to one (width, unit) combo.
    /// Renders values like "in 5 seconds", "2 days ago", "yesterday"
    /// (when Numeric::Auto is set).
    #[diplomat::rust_link(
        icu::experimental::relativetime::RelativeTimeFormatter,
        Struct
    )]
    pub struct RelativeTimeFormatterFfi(pub RelativeTimeFormatter);

    /// Formatting style for relative times.
    /// Mirrors `icu_experimental::relativetime::options::Numeric`.
    #[diplomat::rust_link(
        icu::experimental::relativetime::options::Numeric,
        Enum
    )]
    #[diplomat::enum_convert(
        icu_experimental::relativetime::options::Numeric,
        needs_wildcard
    )]
    #[non_exhaustive]
    pub enum RelativeTimeNumeric {
        #[diplomat::attr(auto, default)]
        Always,
        Auto,
    }

    impl RelativeTimeFormatterFfi {
        // Convenience macro that emits a `create_<width>_<unit>` factory
        // for every combination. Each one delegates to
        // `RelativeTimeFormatter::try_new_<width>_<unit>`. We can't use a
        // Rust macro directly inside diplomat's bridge — Diplomat's
        // tooling reads the literal function definitions — so we expand
        // the 24 functions inline.

        // ---- LONG ----------------------------------------------------

        #[cfg(feature = "compiled_data")]
        #[diplomat::rust_link(
            icu::experimental::relativetime::RelativeTimeFormatter::try_new_long_second,
            FnInStruct
        )]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_second")]
        pub fn create_long_second(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_second(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_minute")]
        pub fn create_long_minute(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_minute(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_hour")]
        pub fn create_long_hour(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_hour(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_day")]
        pub fn create_long_day(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_day(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_week")]
        pub fn create_long_week(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_week(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_month")]
        pub fn create_long_month(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_month(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_quarter")]
        pub fn create_long_quarter(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_quarter(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_year")]
        pub fn create_long_year(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_year(prefs, options)?,
            )))
        }

        // ---- SHORT ---------------------------------------------------

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_second")]
        pub fn create_short_second(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_second(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_minute")]
        pub fn create_short_minute(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_minute(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_hour")]
        pub fn create_short_hour(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_hour(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_day")]
        pub fn create_short_day(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_day(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_week")]
        pub fn create_short_week(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_week(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_month")]
        pub fn create_short_month(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_month(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_quarter")]
        pub fn create_short_quarter(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_quarter(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_year")]
        pub fn create_short_year(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_year(prefs, options)?,
            )))
        }

        // ---- NARROW --------------------------------------------------

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_second")]
        pub fn create_narrow_second(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_second(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_minute")]
        pub fn create_narrow_minute(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_minute(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_hour")]
        pub fn create_narrow_hour(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_hour(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_day")]
        pub fn create_narrow_day(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_day(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_week")]
        pub fn create_narrow_week(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_week(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_month")]
        pub fn create_narrow_month(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_month(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_quarter")]
        pub fn create_narrow_quarter(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_quarter(prefs, options)?,
            )))
        }

        #[cfg(feature = "compiled_data")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_year")]
        pub fn create_narrow_year(
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_year(prefs, options)?,
            )))
        }

        // ---- Long (with_provider) ----------------------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_second_with_provider")]
        pub fn create_long_second_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_second_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_minute_with_provider")]
        pub fn create_long_minute_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_minute_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_hour_with_provider")]
        pub fn create_long_hour_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_hour_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_day_with_provider")]
        pub fn create_long_day_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_day_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_week_with_provider")]
        pub fn create_long_week_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_week_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_month_with_provider")]
        pub fn create_long_month_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_month_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_quarter_with_provider")]
        pub fn create_long_quarter_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_quarter_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "long_year_with_provider")]
        pub fn create_long_year_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_long_year_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        // ---- Short (with_provider) ----------------------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_second_with_provider")]
        pub fn create_short_second_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_second_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_minute_with_provider")]
        pub fn create_short_minute_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_minute_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_hour_with_provider")]
        pub fn create_short_hour_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_hour_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_day_with_provider")]
        pub fn create_short_day_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_day_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_week_with_provider")]
        pub fn create_short_week_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_week_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_month_with_provider")]
        pub fn create_short_month_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_month_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_quarter_with_provider")]
        pub fn create_short_quarter_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_quarter_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "short_year_with_provider")]
        pub fn create_short_year_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_short_year_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        // ---- Narrow (with_provider) ----------------------------

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_second_with_provider")]
        pub fn create_narrow_second_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_second_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_minute_with_provider")]
        pub fn create_narrow_minute_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_minute_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_hour_with_provider")]
        pub fn create_narrow_hour_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_hour_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_day_with_provider")]
        pub fn create_narrow_day_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_day_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_week_with_provider")]
        pub fn create_narrow_week_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_week_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_month_with_provider")]
        pub fn create_narrow_month_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_month_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_quarter_with_provider")]
        pub fn create_narrow_quarter_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_quarter_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        #[cfg(feature = "buffer_provider")]
        #[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "narrow_year_with_provider")]
        pub fn create_narrow_year_with_provider(
            provider: &DataProvider,
            locale: &Locale,
            numeric: Option<RelativeTimeNumeric>,
        ) -> Result<Box<RelativeTimeFormatterFfi>, DataError> {
            let prefs = RelativeTimeFormatterPreferences::from(&locale.0);
            let mut options = RelativeTimeFormatterOptions::default();
            options.numeric = numeric.map(Into::into).unwrap_or(Numeric::Always);
            Ok(Box::new(RelativeTimeFormatterFfi(
                RelativeTimeFormatter::try_new_narrow_year_with_buffer_provider(
                    provider.get()?,
                    prefs,
                    options,
                )?,
            )))
        }

        // ---- format ---------------------------------------------------

        /// Format `value` (signed; negative = past, positive = future).
        #[diplomat::rust_link(
            icu::experimental::relativetime::RelativeTimeFormatter::format,
            FnInStruct
        )]
        pub fn format(&self, value: &Decimal, write: &mut DiplomatWrite) {
            let _ = self.0.format(value.0.clone()).write_to(write);
        }
    }
}
