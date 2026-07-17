# icu_kit — Capability Matrix

What's shipped, what's experimental, what's deliberately out of scope. For HOW each facade works, see [`../README.md`](../README.md). For how the package is wired, see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Table 1 — Shipped

ECMA-402 / Unicode capabilities exposed via the public facade.

| Domain | Facade(s) | Coverage | Tier |
|---|---|---|:---:|
| **Locale** | `IcuLocale`, `IcuLocaleCanonicalizer`, `IcuLocaleExpander`, `IcuLocaleDirectionality`, `IcuLocaleFallbacker` | Parse + canonicalize + maximize/minimize + RTL/LTR + CLDR fallback chain | A |
| **Plural rules** | `IcuPluralRules` | Cardinal + ordinal, every CLDR locale; `categoryOfDecimal` for operand-exact selection (trailing-zero aware, e.g. `1.0` ≠ `1`) | A |
| **Decimal numbers** | `IcuNumberFormat` | `style: "decimal"` portion of ECMA-402 NumberFormat, incl. `formatToParts` (typed part output). The full digit + rounding surface — minimum/maximum fraction and integer digits, minimum/maximum significant digits, `roundingMode` (all nine), `roundingIncrement`, `trailingZeroDisplay`, `signDisplay` — lives on the shared digit shaper (a `format()` option bag), so every number facade below inherits it | A |
| **Compact numbers** | `IcuCompactFormat` | ECMA-402 `notation: "compact"` — short ("1.2M") / long ("1.2 million"), CLDR significand rounding, grouping, `formatToParts` (abbreviation → one `compact` part) | C ⚠ |
| **Currency** | `IcuCurrencyFormat` | Symbol / narrow / ISO-code widths (`currencyDisplay: "code"` with CLDR alpha-next-to-number spacing) + long form (plural-correct "1 US dollar" / "2 US dollars"); grouping; `formatToParts` (symbol/name → `currency` part) | C ⚠ |
| **Percent** | `IcuPercentFormat` | Standard / approximate / explicit-sign; grouping; `formatToParts` (→ `percentSign`, typed signs) | C ⚠ |
| **Units** | `IcuUnitFormat` | CLDR unit identifier (e.g. `"kilometer-per-hour"`); long / short / narrow widths; grouping; `formatToParts` (unit name → one `unit` part) | C ⚠ |
| **Date** | `IcuDateFormat` | 10 field-set constructors (ymd, md, ymde, mde, de, y, m, d, e, ym), length / alignment / year-style | A |
| **Time** | `IcuTimeFormat` | length / time-precision / alignment | A |
| **Date+Time** | `IcuDateTimeFormat` | 7 field sets (dt, mdt, ymdt, det, mdet, ymdet, et) | A |
| **Zoned date+time** | `IcuZonedDateTimeFormat` | 6 field sets × 8 zone styles (specific/localized-offset/generic × long/short + location + exemplarCity) | A |
| **Standalone time-zone** | `IcuTimeZoneFormat` | 8 zone styles | A |
| **Lists** | `IcuListFormat` | and / or / unit × long / short / narrow | A |
| **Collation** | `IcuCollator` | UCA collation: 5 strengths, alternate handling, BCP47 numeric (`-u-kn`) | A |
| **Segmentation** | `IcuSegmenter`, `IcuLineSegmenter` | UAX #29 grapheme/word/sentence + UAX #14 line break | A |
| **Casing** | `IcuCaseMapper` | Locale-aware lower/upper/titlecase (Turkish dotted I, German ß, Greek sigma); fold / Turkic fold | A |
| **Normalization** | `IcuNormalizer` | NFC / NFD / NFKC / NFKD | A |
| **Bidi** | `IcuBidi` | UAX #9 paragraph levels + visual reorder | A |
| **Properties** | `IcuProperties`, `IcuPropertySet` | 45 binary properties (alphabetic / lowercase / emoji / xidStart …) | A |
| **Enum properties** | `IcuEnumProperty` family | 11 enum maps (GeneralCategory, Script, BidiClass, LineBreak, WordBreak, SentenceBreak, GraphemeClusterBreak, EastAsianWidth, HangulSyllableType, JoiningType, CanonicalCombiningClass) | A |
| **Property names** | `IcuPropertyName` | code ↔ name resolution for 10 enum properties | A |
| **Locale exemplars** | `IcuExemplarCharacters` | 5 sets (main / auxiliary / punctuation / numbers / index headers) | A |
| **Display names** | `IcuRegionDisplayNames`, `IcuLocaleDisplayNames` | Region + locale; narrow / short / long / menu styles; dialect / standard | B |
| **Calendars** | `IcuCalendar`, `IcuCalendarDate` | 17 systems (Gregorian, Japanese, Buddhist, Ethiopian / EthiopianAmeteAlem, Indian, Coptic, Dangi, Chinese, Hebrew, Hijri ×4, Persian, ROC, ISO) | A |
| **Relative time** | `IcuRelativeTimeFormat` | 8 units × 3 widths × always/auto | B |
| **IDNA** | `IcuIdna` | UTS #46 + RFC 3492 Punycode codec; URL / strict / UTS46-conformance modes | D |
| **Data layer** | `IcuData`, `IcuDataSource`, `IcuDataProvider` | Two size levers (fat/lean binary via `bundleCldrData` / `setup --lean`; per-locale postcards via `slice`, with facade-family marker presets) plus three runtime policies (`bundled`, optionally locale-gated as a loud allow-list / `lazy` / `composite`) | A |

Tier legend: **A** = STABLE (`icu_*` Rust crates). **B** = STABLE-WITH-CAVEAT (`icu_experimental`'s relativetime + displaynames; Rust API stable for 1+ year). **C** = EXPERIMENTAL (Rust API still being redesigned; `@experimental` annotation at every entry point). **D** = locale-data-free (uses `idna` Rust crate, not ICU4X).

⚠ Tier C facades are pending [unicode-org/icu4x PR #7789](https://github.com/unicode-org/icu4x/pull/7789)'s unified `CurrencyDisplay` API. Migration story documented in `CHANGELOG` when upstream stabilizes.

---

## Table 2 — Platform support

| Platform | Backend | Build hook | Tested |
|---|---|:---:|:---:|
| macOS arm64 | dart:ffi | ✓ | ✓ |
| macOS x64 | dart:ffi | ✓ | ✓ |
| iOS arm64 (device) | dart:ffi | ✓ | ✓ |
| iOS arm64 (simulator) | dart:ffi | ✓ | needs CI runner |
| Linux x64 | dart:ffi | ✓ | needs CI runner |
| Windows x64 | dart:ffi | ✓ | needs CI runner |
| Android arm64 / x64 | dart:ffi | ✓ | needs Android NDK on CI |
| Web (WASM) | dart:js_interop | n/a (`tool/build_wasm.dart`) | ✓ (`fvm dart test -p chrome`) |

Build-hook works on every platform. Test coverage gap is CI matrix only — every binary built locally has been smoke-tested.

### Web engines — three ways to ship the data

Web has three interchangeable engines behind the same facade. The two ICU4X engines carry ICU4X and produce byte-identical output everywhere. The browser Intl engine carries nothing — it serves the facade off the browser's own `Intl` (ECMA-402), so it ships **zero bytes** but covers only what `Intl` covers, and its output tracks each browser's CLDR version.

| Engine | Download | Data source | Select with |
|---|---|---|---|
| ICU4X (bundled) | ~19 MB | ICU4X, all locales | `icu_kit:setup` |
| ICU4X (lean) | ~2.1 MB + postcards | ICU4X, sliced locales | `icu_kit:setup --lean` |
| Browser Intl | 0 bytes | the browser's `Intl` | `IcuKit.init(webEngine: WebEngine.browserIntl)` |

The per-facade capability breakdown for the browser Intl engine (FULL / PARTIAL / THROW per family) lives in one place: [README → Browser Intl mode capability matrix](../README.md#browser-intl-mode-zero-download). It's the user-facing decision surface, so it's kept there rather than duplicated here.

The browser Intl engine registers every facade class; the ones it can't serve raise `IcuUnsupportedError` at the call, never a silent wrong answer. A drift guard (`test/browser_engine/contract_guard_test.dart`) derives the full class set from the binding source and fails if the shim misses one — see [`UPDATING.md`](UPDATING.md).

---

## Table 3 — Test coverage

| Coverage type | What | Where |
|---|---|---|
| **Behavioral** | One test file per facade. Asserts behavior against known outputs. ~42 files. Compiled-data path. | `test/facade/*_test.dart` |
| **Corpus (per-row)** | UCD + ICU4X JSON fixtures. Every row asserted; no thresholds. ~91k bidi rows alone. | `test/_corpus/*_test.dart` |
| **Data layer (shapes)** | `IcuData` / `IcuDataSource` shapes, `IcuKit.init` state machine, `preloadLocale`, locale-restricted gating. | `test/data/icu_data_test.dart` |
| **Data layer (round-trip)** | Real ICU4X postcard bytes → working facades. Proves IcuDataSource.{bytes,callback,assets} + IcuData.composite walk semantics end-to-end. | `test/data/postcard_round_trip_test.dart` |
| **WithProvider arm (stable)** | Lazy/postcard arm of dispatch for the 6 stable facade families (plurals, decimal, date, time, IDNA). | `test/data/with_provider_arm_test.dart` |
| **WithProvider arm (experimental)** | Lazy/postcard arm for the 4 IDL-patched experimental facades (currency, percent, unit, relative-time). Uses `--features=unstable` postcards. | `test/data/with_provider_arm_experimental_test.dart` |
| **Validation matrix** | `bundleCldrData × IcuData` truth table — every cell that throws or warns at init time has a row. | `test/data/validation_matrix_test.dart` |
| **Marker presets** | `slice`'s preset → marker expansion against the live vendored registry: every preset resolves to a non-empty registry subset, `format-core` stays identical to the regen tool's `stableMarkers`, `kit` is the family union, mistyped presets throw with a hint. | `test/hook/marker_presets_test.dart` |
| **Locale-error law (battery)** | One shared spec instead of a rule re-proven per facade: every locale-taking entry point (27 cases, constructor- and method-shaped) throws `IcuLocaleParseError` on an unparseable tag; experimental entries tagged. | `test/batteries/facades_grammar_test.dart` |
| **Errors** | Sealed `IcuError` hierarchy contract. | `test/errors/icu_error_test.dart` |
| **Example journeys** | The example app's four tabs (Format / Text / Locale / Data) driven end to end through the REAL engine, across a 6-device profile matrix on the host VM. Robot harness in `test_support/`. | `example/test/journeys/*_test.dart` |
| **Flavor probe** | The binary-flavor detection mechanism: the compiled-data probe symbol resolves on the fat binary; a genuinely missing `@Native` symbol throws a catchable `ArgumentError` (the lean-detection mechanism). | `test/runtime/native/flavor_probe_test.dart` |
| **Lean binary (end to end)** | The one flavor the main suite can never exercise: `test_fixtures/lean_smoke/` is its own hooks root with `bundleCldrData: false`, so the hook builds the no-CLDR binary — the probe detects it, init without lazy data throws AT INIT, and postcards carry real formatting. `make test-lean`; in `check`. | `test_fixtures/lean_smoke/test/lean_smoke_test.dart` |
| **Lean WASM (end to end)** | The lean wasm (2.1 MB vs 19 MB — built by `tool/build_wasm.dart --lean`, installed by `setup --lean`, shipped as the `wasm-icu4x-lean.wasm` release asset) proven in real Chrome: the web probe detects it, init refuses without lazy data, fetched postcards carry real formatting. `make test-web-lean`; in `check`. | `test_fixtures/lean_smoke/test/lean_wasm_web_test.dart` |
| **Example integration smoke** | Every facade family exercised programmatically against the REAL native library on a real target (desktop / iOS / Android / web) — proves the per-target build + link, including Android's 16 KB page size. | `example/integration_test/icu_kit_smoke_test.dart` |
| **Lean example journeys** | The SAME journeys on the no-CLDR binary + generated postcards (`example_lean/` is a build-config shell whose pubspec flips `bundleCldrData: false`; both app roots share the suite bodies in `test_support/`), proving the runtime probe branch + async postcard preload UX. `make test-example-lean-matrix`; CI-only (slicing the `kit` preset per locale is slow). `make verify-web-lean` builds the lean web app end to end. | `example_lean/` (shared suites in `example/test_support/lib/`) |

| Corpus | Source | Rows |
|---|---|---|
| `bidi_corpus_test` | UCD `BidiCharacterTest.txt` | 91,707 |
| `plural_rules_corpus_test` | ICU4X `plurals/categories.json` | every (langid, plural_type) |
| `locale_canonicalizer_corpus_test` | ICU4X `locale/canonicalize.json` (extended) | 100+ |
| `locale_core_corpus_test` | ICU4X `locale_core/canonicalize.json` | round-trip |
| `locale_expander_corpus_test` | ICU4X `locale/{maximize,minimize}.json` (extended) | 59 |
| `case_map_corpus_test` | UCD `CaseFolding.txt` + `SpecialCasing.txt` | per-row |
| `normalizer_corpus_test` | UCD `NormalizationTest.txt` | per-row |
| `idna_corpus_test` | UTS #46 conformance corpus | 100% pass |
| `segmenter_corpus_test` | UAX #29 + #14 break tables | per-row |
| `properties_corpus_test` | UCD `DerivedCoreProperties.txt` + others | per-property |

Provenance ledger: [`test/_corpus/PROVENANCE.md`](../test/_corpus/PROVENANCE.md). Refresh procedure + the add-a-new-facade recipe: [`UPDATING.md`](UPDATING.md).

Facades without per-row corpus (relative-time, currency, percent, unit, display names, fallbacker, calendar arithmetic, exemplar chars) have rich behavioral tests but no upstream conformance corpus. CLDR's relativetime fixtures + ICU4X's experimental crates' tests would fill these gaps when refresh is feasible.

---

## Table 4 — Known gaps

| Gap | Why deferred | Trigger |
|---|---|---|
| Tier C facades carry `@experimental` annotations | Upstream Rust API still being redesigned (PR #7789) | Upstream lands the unified `CurrencyDisplay` |
| `formatToParts` covers the NUMBER family only — date/time, list, and relative-time part output is not built yet | Only the number formatters have parts patches so far | Add per-formatter parts patches (same collect → flatten → gap-fill shape) |
| No `resolvedOptions` ECMA-402 introspection | ICU4X's Rust API doesn't expose the resolved option bag | Upstream exposes it, or we derive it facade-side |
| `Intl.Segmenter.containing` / `.before` / `.after` helpers | ICU4X iterator-only model | Add Dart-side helpers without changing ICU4X |
| Deprecated calendars (`japaneseExtended`, `iso8601`-only) | ICU4X 2.2 marks them deprecated | Tracking upstream removal in 2.3+ |
| No automated staleness check for the icu4x submodule | Manual bumps are acceptable at a once-a-quarter cadence; a CI job that watches upstream tags and opens an issue is unbuilt | When bump cadence starts hurting |
| No `record_use` link-time tree-shaking of unused native symbols | The link hook is a passthrough. API-level symbol stripping needs `--enable-experiment=record-use` (dev-channel Dart, Linux-only today) plus unstable hooks APIs — the official `icu4x` pub package pins `hooks: 2.0.2` for the same reason. The Dart-side surface is already trimmed by the used-surface dispatch filter; the native binary's symbols are not. | `record-use` ships on stable Dart |
| **LAUNCH BLOCKER — first release must validate the distribution pipeline** | The pdf_manipulator distribution model is BUILT (hook download waterfall, `setup` targets incl. `--lean`, `tool/compile_rust.sh`, release.yml compiling 26 native variants + both wasm variants, `--update-tag-hashes` stamping) but has never run in CI: no release exists, `asset_hashes.dart` is empty, and consumers still fall to source compile. (The wasm-opt size question is settled: the bundled wasm stays ~19 MB because compiled CLDR is data, not shrinkable code — the lean build's 2.8 → 2.1 MB shows wasm-opt working.) | First release run on GitHub |

## Table 5 — Won't do

| Capability | Reason |
|---|---|
| Pure-Dart re-implementation of any ICU4X feature | The whole point is to inherit ICU4X's correctness. We're a binding, not a competing implementation. |
| ICU4C bindings | ICU4C is C++ heavy, ~30 MB, and can't compile to WebAssembly cleanly; ICU4X targets wasm32 from day one. The moment web is a requirement there is no second option. |
| `localPath` / bring-your-own-dylib user_define (the official `icu4x` package's `buildMode: local`) | The bindings are generated from the patched vendor fork — a consumer-built upstream dylib is missing the fork's symbols and fails at symbol resolution with a confusing late error. The supported custom path is forking the vendor and letting the hook compile it. The official package can afford `local` because its binding surface equals upstream exactly; ours doesn't. |
| Custom CLDR data import | `icu4x-datagen` already does it correctly. We vendor it as `bin/slice.dart` rather than re-implement. |
| Locale-subset baked binary (`ICU4X_DATA_DIR`) | Measured against the vendored tree (icu4x 2.2). The locale-*independent* floor swamps the win: segmentation dictionaries (~11 MB) + Unicode property tables (~1.7 MB) bake whole regardless of locale count, so a one-locale subset binary still lands near 8–10 MB — the big saving is on dates (14 MB across all locales collapses to 0.5 MB for one), but the floor dominates unless you also drop segmentation and collation. It is also incompatible with the experimental formatters (currency, units, percent, IDNA, transliteration): those pull an older ICU data layout (`idna → idna_adapter → icu 1.x`) that reads the same global `ICU4X_DATA_DIR` env but expects a layout datagen 2.2 no longer emits, so the build fails unless `experimental` is dropped. Lean + preset postcards already delivers "small footprint, chosen locales, works offline" (3 MB + 68 KB/locale for `format-core`) with every facade intact and nothing lost. |
| Subset of the ECMA-402 surface (e.g. Fluent-only) | Apps that need a tiny subset use `fluent_kit`'s pure-Dart `intl` backend. We're the full ECMA-402 facade. |
| Backwards-compat polyfills for `package:intl` API | Different shape, different lifecycle, different goals. Apps migrate explicitly. |
| Upstreaming the facade / dispatch / WASM layers to `unicode.org/package:icu4x` | Upstream is a slow consensus body (6–12-month patch cycles) and targets the bare FFI — the facade + IcuData conveniences would be out of scope there, and our IDL patches expose APIs upstream hasn't stabilized. Re-evaluated when upstream ships web support. |
| Features ICU4X doesn't expose | The package binds; it never reimplements, polyfills, or works around upstream gaps. Coverage is 100% of what ICU4X offers (bindings are generated, so completeness is cheap) — and exactly that. |
| Stub-default conditional exports on the platform seams | The stub-default pattern exists to protect pana's platform attribution; pana already reports all six platforms against the current native-default seams (`runtime/bindings.dart`, `runtime/dispatch.dart`, the init loaders, the flavor probes), and `make platforms` fails CI if that ever regresses — so the protection is delivered mechanically. Adding it anyway would mean stub twins duplicating each seam's public surface, a lockstep-maintenance surface (a drift bomb) guarding against a platform with neither `dart.library.io` nor `dart.library.js_interop`, which does not exist. Revisit only if pana misattributes. |

---

## Table 6 — Vendor + patch ledger

| Component | Pinned at | Maintenance window |
|---|---|---|
| `vendor/icu4x` (submodule) | tag `icu@2.2.0` on branch `icu_kit/2.2.0-patches` | Bumped on each minor ICU4X release. Each bump: reapply IDL patches, regen bindings, regen dispatch. |
| Diplomat (built from submodule's `tools/make/diplomat-gen`) | matches the ICU4X tag | Auto-bumped with the submodule. |
| Pinned Rust nightly | `build.json` `nightlyToolchain` | Matches upstream's `vendor/icu4x/ffi/capi/build.sh`. Bumped when upstream bumps. |
| Local IDL patches | Marker-wrapped files under `vendor/icu4x/ffi/capi/` AND `vendor/icu4x/components/` — `grep -rl "icu_kit patch" ffi/capi/ components/` inside the vendor is the authoritative inventory (12 + 11 files as of the ECMA-402 knob patches) | See ARCHITECTURE.md "Local IDL patches" for the file list + removal triggers. |

Refresh procedure + the add-a-new-facade recipe: [`UPDATING.md`](UPDATING.md).

