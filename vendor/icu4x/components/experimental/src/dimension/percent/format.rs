// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).

use fixed_decimal::{Decimal, Sign};
use icu_decimal::DecimalFormatter;

use crate::alloc::borrow::ToOwned;
use alloc::borrow::Cow;
use writeable::Writeable;

use crate::dimension::provider::percent::PercentEssentials;

use super::options::{Display, PercentFormatterOptions};

struct Append<W1, W2>(W1, W2);
// This allows us to combines two writeables together.
impl<W1: Writeable, W2: Writeable> Writeable for Append<W1, W2> {
    fn write_to<W>(&self, sink: &mut W) -> Result<(), core::fmt::Error>
    where
        W: core::fmt::Write + ?Sized,
    {
        self.0.write_to(sink)?;
        self.1.write_to(sink)
    }
    // ── icu_kit patch ── propagate typed parts through both halves.
    fn write_to_parts<W>(&self, sink: &mut W) -> Result<(), core::fmt::Error>
    where
        W: writeable::PartsWrite + ?Sized,
    {
        self.0.write_to_parts(sink)?;
        self.1.write_to_parts(sink)
    }
    // ── end icu_kit patch ──
}

// ── icu_kit patch ── tags an inner writeable's output with a [`Part`], so a
// sign glyph is recorded as minusSign / plusSign / approximatelySign for
// formatToParts. write_to is unchanged (the flat string never differs).
struct WithPart<W>(W, writeable::Part);
impl<W: Writeable> Writeable for WithPart<W> {
    fn write_to<S>(&self, sink: &mut S) -> Result<(), core::fmt::Error>
    where
        S: core::fmt::Write + ?Sized,
    {
        self.0.write_to(sink)
    }
    fn write_to_parts<S>(&self, sink: &mut S) -> Result<(), core::fmt::Error>
    where
        S: writeable::PartsWrite + ?Sized,
    {
        sink.with_part(self.1, |w| self.0.write_to_parts(w))
    }
}
// ── end icu_kit patch ──

#[derive(Debug)]
pub struct FormattedPercent<'l> {
    pub(crate) value: &'l Decimal,
    pub(crate) essential: &'l PercentEssentials<'l>,
    pub(crate) options: &'l PercentFormatterOptions,
    pub(crate) decimal_formatter: &'l DecimalFormatter,
}

impl Writeable for FormattedPercent<'_> {
    fn write_to<W>(&self, sink: &mut W) -> Result<(), core::fmt::Error>
    where
        W: core::fmt::Write + ?Sized,
    {
        // Removing the sign from the value
        let abs_value = match self.value.sign() {
            Sign::Negative => self.value.clone().with_sign(Sign::None),
            _ => self.value.to_owned(),
        };

        let value = self.decimal_formatter.format(&abs_value);

        match self.options.display {
            // In the Standard display, we take the unsigned pattern only when the value is positive.
            Display::Standard => {
                if self.value.sign() == Sign::Negative {
                    self.essential
                        .signed_pattern
                        .interpolate((value, &self.essential.minus_sign))
                        .write_to(sink)?
                } else {
                    self.essential
                        .unsigned_pattern
                        .interpolate([value])
                        .write_to(sink)?
                };
            }
            Display::Approximate => {
                let sign = if self.value.sign() == Sign::Negative {
                    // The approximate sign gets pre-pended
                    Append(
                        &self.essential.approximately_sign,
                        &self.essential.minus_sign,
                    )
                } else {
                    Append(&self.essential.approximately_sign, &Cow::Borrowed(""))
                };

                self.essential
                    .signed_pattern
                    .interpolate((value, sign))
                    .write_to(sink)?;
            }
            Display::ExplicitSign => self
                .essential
                .signed_pattern
                .interpolate((
                    value,
                    if self.value.sign() == Sign::Negative {
                        &self.essential.minus_sign
                    } else {
                        &self.essential.plus_sign
                    },
                ))
                .write_to(sink)?,
        };

        Ok(())
    }

    // ── icu_kit patch ── typed-part output for formatToParts. Mirrors write_to
    // exactly (identical flat string) but tags each sign glyph with its Part;
    // the number keeps the decimal formatter's parts, and the % symbol stays a
    // pattern literal (typed as percentSign by the FFI gap-fill layer).
    fn write_to_parts<W>(&self, sink: &mut W) -> Result<(), core::fmt::Error>
    where
        W: writeable::PartsWrite + ?Sized,
    {
        const APPROX_SIGN: writeable::Part = writeable::Part {
            category: "percent",
            value: "approximatelySign",
        };
        let minus = icu_decimal::parts::MINUS_SIGN;
        let plus = icu_decimal::parts::PLUS_SIGN;

        let abs_value = match self.value.sign() {
            Sign::Negative => self.value.clone().with_sign(Sign::None),
            _ => self.value.to_owned(),
        };
        let value = self.decimal_formatter.format(&abs_value);

        match self.options.display {
            Display::Standard => {
                if self.value.sign() == Sign::Negative {
                    self.essential
                        .signed_pattern
                        .interpolate((value, WithPart(&self.essential.minus_sign, minus)))
                        .write_to_parts(sink)?
                } else {
                    self.essential
                        .unsigned_pattern
                        .interpolate([value])
                        .write_to_parts(sink)?
                };
            }
            Display::Approximate => {
                let sign = if self.value.sign() == Sign::Negative {
                    Append(
                        WithPart(&self.essential.approximately_sign, APPROX_SIGN),
                        WithPart(&self.essential.minus_sign, minus),
                    )
                } else {
                    Append(
                        WithPart(&self.essential.approximately_sign, APPROX_SIGN),
                        WithPart(&Cow::Borrowed(""), minus),
                    )
                };
                self.essential
                    .signed_pattern
                    .interpolate((value, sign))
                    .write_to_parts(sink)?;
            }
            Display::ExplicitSign => self
                .essential
                .signed_pattern
                .interpolate((
                    value,
                    if self.value.sign() == Sign::Negative {
                        WithPart(&self.essential.minus_sign, minus)
                    } else {
                        WithPart(&self.essential.plus_sign, plus)
                    },
                ))
                .write_to_parts(sink)?,
        };

        Ok(())
    }
    // ── end icu_kit patch ──
}

writeable::impl_display_with_writeable!(FormattedPercent<'_>);

#[cfg(test)]
mod tests {
    use icu_locale_core::locale;
    use writeable::assert_writeable_eq;

    use crate::dimension::percent::{
        formatter::{PercentFormatter, PercentFormatterPreferences},
        options::{Display, PercentFormatterOptions},
    };

    // ── icu_kit patch ── verify write_to_parts tags the sign + number parts
    // (the % symbol stays an untyped pattern literal — typed as percentSign by
    // the FFI gap-fill layer). Ranges are byte offsets into the flat string.
    #[test]
    fn test_parts() {
        use icu_decimal::parts;
        use writeable::assert_writeable_parts_eq;
        let prefs: PercentFormatterPreferences = locale!("en-US").into();

        // Negative Standard: "-12.5%" → minusSign, integer, decimal, fraction.
        let fmt = PercentFormatter::try_new(prefs, Default::default()).unwrap();
        let neg = "-12.5".parse().unwrap();
        assert_writeable_parts_eq!(
            fmt.format(&neg),
            "-12.5%",
            [
                (0, 1, parts::MINUS_SIGN),
                (1, 3, parts::INTEGER),
                (3, 4, parts::DECIMAL),
                (4, 5, parts::FRACTION),
            ]
        );

        // ExplicitSign positive: "+42%" → plusSign, integer.
        let explicit = PercentFormatter::try_new(
            prefs,
            PercentFormatterOptions {
                display: Display::ExplicitSign,
            },
        )
        .unwrap();
        let pos = "42".parse().unwrap();
        assert_writeable_parts_eq!(
            explicit.format(&pos),
            "+42%",
            [(0, 1, parts::PLUS_SIGN), (1, 3, parts::INTEGER)]
        );
    }
    // ── end icu_kit patch ──

    #[test]
    pub fn test_en_us() {
        let prefs: PercentFormatterPreferences = locale!("en-US").into();
        // Positive case
        let positive_value = "12345.67".parse().unwrap();
        let default_fmt = PercentFormatter::try_new(prefs, Default::default()).unwrap();
        let formatted_percent = default_fmt.format(&positive_value);
        assert_writeable_eq!(formatted_percent, "12,345.67%");

        // Negative case
        let neg_value = "-12345.67".parse().unwrap();
        let formatted_percent = default_fmt.format(&neg_value);
        assert_writeable_eq!(formatted_percent, "-12,345.67%");

        // Approximate Case
        let approx_value = "12345.67".parse().unwrap();
        let approx_fmt = PercentFormatter::try_new(
            prefs,
            PercentFormatterOptions {
                display: Display::Approximate,
            },
        )
        .unwrap();
        let formatted_percent = approx_fmt.format(&approx_value);
        assert_writeable_eq!(formatted_percent, "~12,345.67%");

        // ExplicitSign Case
        let explicit_fmt = PercentFormatter::try_new(
            prefs,
            PercentFormatterOptions {
                display: Display::ExplicitSign,
            },
        )
        .unwrap();
        let formatted_percent = explicit_fmt.format(&positive_value);
        assert_writeable_eq!(formatted_percent, "+12,345.67%");
    }

    #[test]
    pub fn test_tr() {
        let prefs: PercentFormatterPreferences = locale!("tr").into();
        // Positive case
        let positive_value = "12345.67".parse().unwrap();
        let default_fmt = PercentFormatter::try_new(prefs, Default::default()).unwrap();
        let formatted_percent = default_fmt.format(&positive_value);
        assert_writeable_eq!(formatted_percent, "%12.345,67");

        // Negative case
        let neg_value = "-12345.67".parse().unwrap();
        let formatted_percent = default_fmt.format(&neg_value);
        assert_writeable_eq!(formatted_percent, "-%12.345,67");

        // Approximate Case
        let approx_value = "12345.67".parse().unwrap();
        let approx_fmt = PercentFormatter::try_new(
            prefs,
            PercentFormatterOptions {
                display: Display::Approximate,
            },
        )
        .unwrap();
        let formatted_percent = approx_fmt.format(&approx_value);
        assert_writeable_eq!(formatted_percent, "~%12.345,67");

        // ExplicitSign Case
        let explicit_fmt = PercentFormatter::try_new(
            prefs,
            PercentFormatterOptions {
                display: Display::ExplicitSign,
            },
        )
        .unwrap();
        let formatted_percent = explicit_fmt.format(&positive_value);
        assert_writeable_eq!(formatted_percent, "+%12.345,67");
    }

    #[test]
    pub fn test_blo() {
        let prefs: PercentFormatterPreferences = locale!("blo").into();
        // Positive case
        let positive_value = "12345.67".parse().unwrap();
        let default_fmt = PercentFormatter::try_new(prefs, Default::default()).unwrap();
        let formatted_percent = default_fmt.format(&positive_value);
        assert_writeable_eq!(formatted_percent, "%\u{a0}12\u{a0}345,67");

        // Negative case
        let neg_value = "-12345.67".parse().unwrap();
        let formatted_percent = default_fmt.format(&neg_value);
        assert_writeable_eq!(formatted_percent, "%\u{a0}-12\u{a0}345,67");

        // Approximate Case
        let approx_value = "12345.67".parse().unwrap();
        let approx_fmt = PercentFormatter::try_new(
            prefs,
            PercentFormatterOptions {
                display: Display::Approximate,
            },
        )
        .unwrap();
        let formatted_percent = approx_fmt.format(&approx_value);
        assert_writeable_eq!(formatted_percent, "%\u{a0}~12\u{a0}345,67");

        // ExplicitSign Case
        let explicit_fmt = PercentFormatter::try_new(
            prefs,
            PercentFormatterOptions {
                display: Display::ExplicitSign,
            },
        )
        .unwrap();
        let formatted_percent = explicit_fmt.format(&positive_value);
        assert_writeable_eq!(formatted_percent, "%\u{a0}+12\u{a0}345,67");
    }
}
