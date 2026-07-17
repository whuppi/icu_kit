// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).
//
// ── icu_kit patch (entire file) ── exposes formatToParts (ECMA-402 typed
// part output) over Diplomat. ICU4X emits typed parts internally via
// writeable::PartsWrite (see components/decimal/src/parts.rs), but the capi
// has no parts-over-FFI surface. This collects those parts, flattens the
// nesting to ECMA-402's flat tiling, fills the untyped gaps per formatter
// kind, and exposes the result as an opaque list of (typeString, substring).
// Remove if upstream unicode-org/icu4x grows a parts-over-FFI surface.

use alloc::string::{String, ToString};
use alloc::vec::Vec;
use writeable::{Part, PartsWrite, Writeable};

#[diplomat::bridge]
#[diplomat::abi_rename = "icu4x_{0}_mv1"]
pub mod ffi {
    use alloc::boxed::Box;
    use alloc::string::String;
    use alloc::vec::Vec;
    use writeable::Writeable;

    #[diplomat::opaque]
    /// A formatted number decomposed into typed parts, mirroring ECMA-402
    /// `Intl.NumberFormat.prototype.formatToParts`.
    ///
    /// Each part is a `(type, value)` pair; the types are the ECMA-402 names
    /// (`"integer"`, `"group"`, `"decimal"`, `"fraction"`, `"minusSign"`,
    /// `"plusSign"`, `"percentSign"`, `"currency"`, `"unit"`, `"literal"`, …).
    /// Concatenating every part's value reproduces the flat formatted string.
    pub struct FormattedNumberParts(pub Vec<(String, String)>);

    impl FormattedNumberParts {
        /// The number of parts.
        #[diplomat::attr(auto, getter)]
        pub fn part_count(&self) -> usize {
            self.0.len()
        }

        /// The ECMA-402 type name of the part at `index`, or nothing if the
        /// index is out of bounds.
        pub fn part_type_at(
            &self,
            index: usize,
            write: &mut diplomat_runtime::DiplomatWrite,
        ) -> Option<()> {
            let _infallible = self.0.get(index)?.0.write_to(write);
            Some(())
        }

        /// The substring of the part at `index`, or nothing if the index is
        /// out of bounds.
        pub fn part_value_at(
            &self,
            index: usize,
            write: &mut diplomat_runtime::DiplomatWrite,
        ) -> Option<()> {
            let _infallible = self.0.get(index)?.1.write_to(write);
            Some(())
        }
    }
}

/// Which formatter produced the parts. Decides how UNTYPED gaps (text ICU4X
/// wrote without a part annotation) are typed: for the symbol-bearing
/// formatters the gap's non-whitespace core is the symbol/name.
#[derive(Clone, Copy)]
pub(crate) enum GapKind {
    Decimal,
    Currency,
    Percent,
    Unit,
    Compact,
}

impl GapKind {
    /// The ECMA-402 type for the non-whitespace core of an untyped gap.
    fn core_type(self) -> &'static str {
        match self {
            GapKind::Decimal => "literal",
            GapKind::Currency => "currency",
            GapKind::Percent => "percentSign",
            GapKind::Unit => "unit",
            GapKind::Compact => "compact",
        }
    }
}

/// A `PartsWrite` sink that records the written string and every typed range
/// `(start, end, Part)`. Nesting is handled naturally: `with_part` runs the
/// inner closure against `self`, so an inner part's range lands inside its
/// parent's. Modeled on `writeable::testing::TestWriter`.
struct PartsCollector {
    string: String,
    ranges: Vec<(usize, usize, Part)>,
}

impl core::fmt::Write for PartsCollector {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        self.string.write_str(s)
    }
    fn write_char(&mut self, c: char) -> core::fmt::Result {
        self.string.write_char(c)
    }
}

impl PartsWrite for PartsCollector {
    type SubPartsWrite = Self;
    fn with_part(
        &mut self,
        part: Part,
        mut f: impl FnMut(&mut Self::SubPartsWrite) -> core::fmt::Result,
    ) -> core::fmt::Result {
        let start = self.string.len();
        f(self)?;
        let end = self.string.len();
        if start < end {
            self.ranges.push((start, end, part));
        }
        Ok(())
    }
}

/// Format `w` and decompose it into ECMA-402-shaped parts.
pub(crate) fn collect_parts<W: Writeable>(w: &W, kind: GapKind) -> Vec<(String, String)> {
    let mut collector = PartsCollector {
        string: String::new(),
        ranges: Vec::new(),
    };
    // String sink is infallible.
    let _ = w.write_to_parts(&mut collector);
    flatten(&collector.string, &collector.ranges, kind)
}

/// The core algorithm: given the formatted string and ICU4X's (possibly
/// nested, possibly gapped) typed ranges, produce a flat, gap-free list of
/// `(ecmaType, substring)` that tiles the whole string in order.
fn flatten(text: &str, ranges: &[(usize, usize, Part)], kind: GapKind) -> Vec<(String, String)> {
    // 1. Boundary set: 0, len, and every range endpoint. Sorted, deduped.
    let mut bounds: Vec<usize> = Vec::with_capacity(ranges.len() * 2 + 2);
    bounds.push(0);
    bounds.push(text.len());
    for &(s, e, _) in ranges {
        bounds.push(s);
        bounds.push(e);
    }
    bounds.sort_unstable();
    bounds.dedup();

    // 2. Per segment [a, b): innermost containing range wins; else it's a gap.
    let mut out: Vec<(String, String)> = Vec::new();
    for win in bounds.windows(2) {
        let (a, b) = (win[0], win[1]);
        if a >= b {
            continue;
        }
        let mut best: Option<(usize, &'static str)> = None; // (len, type)
        for &(s, e, part) in ranges {
            if s <= a && b <= e {
                let len = e - s;
                if best.map_or(true, |(bl, _)| len < bl) {
                    best = Some((len, part.value));
                }
            }
        }
        let value = &text[a..b];
        match best {
            Some((_, ty)) => push_or_merge(&mut out, ty, value),
            None => emit_gap(&mut out, kind, value),
        }
    }
    out
}

/// Emit an untyped gap. For the symbol formatters, leading/trailing whitespace
/// becomes `literal` and the core becomes the kind's symbol type; interior
/// whitespace stays inside the core (so "US dollars" is one currency part).
fn emit_gap(out: &mut Vec<(String, String)>, kind: GapKind, gap: &str) {
    if matches!(kind, GapKind::Decimal) {
        // Decimal never leaves symbol gaps; any stray gap is literal text.
        push_or_merge(out, "literal", gap);
        return;
    }
    // Byte offset of the first / last non-whitespace char.
    let core_start = gap
        .char_indices()
        .find(|(_, c)| !c.is_whitespace())
        .map(|(i, _)| i);
    let Some(core_start) = core_start else {
        // All whitespace → one literal.
        push_or_merge(out, "literal", gap);
        return;
    };
    let core_end = gap
        .char_indices()
        .rev()
        .find(|(_, c)| !c.is_whitespace())
        .map(|(i, c)| i + c.len_utf8())
        .unwrap_or(gap.len());

    if core_start > 0 {
        push_or_merge(out, "literal", &gap[..core_start]);
    }
    push_or_merge(out, kind.core_type(), &gap[core_start..core_end]);
    if core_end < gap.len() {
        push_or_merge(out, "literal", &gap[core_end..]);
    }
}

/// Append `(ty, value)`, merging into the previous part if it has the same
/// type (collapses boundary over-splitting; never merges across a differing
/// type, so `integer, group, integer` stays split).
fn push_or_merge(out: &mut Vec<(String, String)>, ty: &str, value: &str) {
    if let Some(last) = out.last_mut() {
        if last.0 == ty {
            last.1.push_str(value);
            return;
        }
    }
    out.push((ty.to_string(), value.to_string()));
}

#[cfg(test)]
mod tests {
    use super::*;

    // Build ranges by hand from a Part + byte span.
    fn part(value: &'static str) -> Part {
        Part {
            category: "decimal",
            value,
        }
    }

    #[test]
    fn nesting_splits_integer_at_group() {
        // "-987,654.321": minus(0,1) integer(1,8) group(4,5) decimal(8,9) fraction(9,12)
        let text = "-987,654.321";
        let ranges = [
            (0, 1, part("minusSign")),
            (1, 8, part("integer")),
            (4, 5, part("group")),
            (8, 9, part("decimal")),
            (9, 12, part("fraction")),
        ];
        let got = flatten(text, &ranges, GapKind::Decimal);
        let expected = [
            ("minusSign", "-"),
            ("integer", "987"),
            ("group", ","),
            ("integer", "654"),
            ("decimal", "."),
            ("fraction", "321"),
        ];
        assert_eq!(got.len(), expected.len(), "{got:?}");
        for (g, e) in got.iter().zip(expected.iter()) {
            assert_eq!((g.0.as_str(), g.1.as_str()), *e);
        }
        // Reconstruction invariant.
        let joined: String = got.iter().map(|p| p.1.as_str()).collect();
        assert_eq!(joined, text);
    }

    #[test]
    fn currency_gap_becomes_currency_symbol() {
        // "$12.34": integer(1,3) decimal(3,4) fraction(4,6); "$" is a gap.
        let text = "$12.34";
        let ranges = [
            (1, 3, part("integer")),
            (3, 4, part("decimal")),
            (4, 6, part("fraction")),
        ];
        let got = flatten(text, &ranges, GapKind::Currency);
        assert_eq!(got[0].0, "currency");
        assert_eq!(got[0].1, "$");
        let joined: String = got.iter().map(|p| p.1.as_str()).collect();
        assert_eq!(joined, text);
    }

    #[test]
    fn unit_gap_edge_trims_leading_space() {
        // "1 meter": integer(0,1); " meter" is a gap.
        let text = "1 meter";
        let ranges = [(0, 1, part("integer"))];
        let got = flatten(text, &ranges, GapKind::Unit);
        let flat: Vec<(&str, &str)> = got.iter().map(|p| (p.0.as_str(), p.1.as_str())).collect();
        assert_eq!(flat, [("integer", "1"), ("literal", " "), ("unit", "meter")]);
    }

    #[test]
    fn percent_nbsp_gap_splits_literal_and_sign() {
        // French "12\u{00A0}%": integer(0,2); "\u{00A0}%" is a gap.
        let text = "12\u{00A0}%";
        let ranges = [(0, 2, part("integer"))];
        let got = flatten(text, &ranges, GapKind::Percent);
        let flat: Vec<(&str, &str)> = got.iter().map(|p| (p.0.as_str(), p.1.as_str())).collect();
        assert_eq!(
            flat,
            [("integer", "12"), ("literal", "\u{00A0}"), ("percentSign", "%")]
        );
    }

    #[test]
    fn all_whitespace_gap_is_single_literal() {
        // "1 2" where " " between two integers is a gap (contrived).
        let text = "1 2";
        let ranges = [(0, 1, part("integer")), (2, 3, part("integer"))];
        let got = flatten(text, &ranges, GapKind::Unit);
        let flat: Vec<(&str, &str)> = got.iter().map(|p| (p.0.as_str(), p.1.as_str())).collect();
        assert_eq!(flat, [("integer", "1"), ("literal", " "), ("integer", "2")]);
    }

    #[test]
    fn interior_space_stays_in_core() {
        // "1 US dollars": integer(0,1); " US dollars" gap → literal " " + currency "US dollars".
        let text = "1 US dollars";
        let ranges = [(0, 1, part("integer"))];
        let got = flatten(text, &ranges, GapKind::Currency);
        let flat: Vec<(&str, &str)> = got.iter().map(|p| (p.0.as_str(), p.1.as_str())).collect();
        assert_eq!(
            flat,
            [("integer", "1"), ("literal", " "), ("currency", "US dollars")]
        );
    }

    #[test]
    fn no_ranges_is_whole_gap() {
        let text = "abc";
        let ranges: [(usize, usize, Part); 0] = [];
        let got = flatten(text, &ranges, GapKind::Currency);
        // Non-whitespace core → currency.
        assert_eq!(got.len(), 1);
        assert_eq!(got[0].0, "currency");
        assert_eq!(got[0].1, "abc");
    }
}
