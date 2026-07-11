# icu_kit — Architecture

How the package is wired. For usage examples and the bundle-size recipes see [`../README.md`](../README.md). For capability status see [`CAPABILITY_ROADMAP.md`](CAPABILITY_ROADMAP.md); for maintenance recipes see [`UPDATING.md`](UPDATING.md).

---

## The contract

- **One API, six platforms, one engine.** Native (dart:ffi) and web (WebAssembly) run the same vendored ICU4X revision with the same CLDR — identical output everywhere, asserted by running the same suites on the VM and in Chrome.
- **Init validates reality.** `IcuKit.init` detects the loaded binary's flavor at runtime (compiled-data probe) and checks the `IcuData` argument against it; a misconfiguration throws a typed, actionable error at init, never mid-run.
- **Failures are loud and typed.** Every failure mode is a sealed `IcuError` subclass. A locale-gated or lazily-missing locale throws; nothing silently falls back to root data.
- **Facades are thin and locale-pinned.** Constructed once per `(locale, options)`, reusable across calls. The generated bindings underneath are never hand-edited.
- **Every behavior change is a reviewable commit.** The submodule pins a release tag; a CLDR update only arrives via an explicit bump (see `UPDATING.md`).

---

## Source tree

```
lib/
  icu_kit.dart               — public barrel
  src/
    icu_kit.dart             — IcuKit: init(), preloadLocale(), hasCompiledData
    version.dart             — stamped by the release tooling
    data/                    — the IcuData model (platform-blind)
      icu_data.dart, icu_data_source.dart, icu_data_resolver.dart
    errors/                  — sealed IcuError hierarchy
    facade/                  — 31 single-source facades (one file each,
                               written once, compiled for both platforms)
    runtime/                 — THE platform boundary: every platform quirk
                               lives here, nothing platform-shaped outside it
      bindings.dart          — binding-surface selector (native ⇄ web)
      dispatch.dart          — dispatch selector (native ⇄ web)
      native/
        bindings/            — 186 Diplomat-generated Dart FFI files
        bindings.dart        — barrel: bindings/lib.g.dart + extras.dart
        dispatch.g.dart      — generated FFI-typed dispatch twin
        extras.dart          — tiny hand-written native adds (asBcp47)
        flavor_probe.dart    — compiled-data symbol probe
        init.dart            — IcuKit (native loader)
      web/
        bindings/            — hand-written js_interop mirrors of the FFI
                               bindings' Dart-visible signatures (used
                               surface only; one file per binding class)
        bindings.dart        — mirror barrel
        dispatch.g.dart      — generated mirror-typed dispatch twin
        flavor_probe.dart    — wasm compiled-data export probe
        init.dart            — IcuKit (web loader: module import + probe)
    hook/                    — resolver.dart (binary waterfall),
                               asset_hashes.dart (stamped per release),
                               marker_presets.dart (slice presets)
bin/                         — setup.dart (web installer), slice.dart (postcards)
hook/build.dart              — the native build hook
tool/                        — regen_* generators, build_wasm.dart,
                               verify_readme_sizes.dart, analyze gates, ci/
web_assets/                  — icu4x.wasm + icu4x-lean.wasm (gitignored,
                               built/downloaded) + committed Diplomat JS bindings
vendor/icu4x/                — the fork submodule (pub-ignored; see UPDATING.md)
test/  test_fixtures/  example/  example_lean/
```

---

## 1. Five layers

Every facade call walks the same five layers, top to bottom:

```
USER
  ↓ IcuKit.init(data: ...) + IcuPluralRules.cardinal('en') etc.
FACADE LAYER       lib/src/facade/*.dart — 31 single-source files
  ↓ idiomatic Dart, hand-written ONCE, compiled for both platforms.
DISPATCH LAYER     lib/src/runtime/dispatch.dart → native/dispatch.g.dart
  ↓                or web/dispatch.g.dart — generated TWINS with identical
  ↓ Dart signatures. Per-locale: IcuKit.providerFor(localeStr) → null ?
  ↓   compiled-data factory : *WithProvider factory.
RESOLVER           lib/src/data/icu_data_resolver.dart — shared
  ↓ holds the active IcuData tree. Walks bundled / lazy / composite layers.
  ↓ caches per-locale. Pre-loaded via IcuKit.preloadLocale().
BINDINGS SEAM      lib/src/runtime/bindings.dart
  ↓ resolves to runtime/native/bindings (FFI) or runtime/web/bindings
  ↓ (mirrors); same class names + Dart-visible signatures on both sides.
FFI BINDINGS       lib/src/runtime/native/bindings/*.g.dart, web_assets/lib/*.mjs
  ↓ Diplomat-generated. We never edit. Native uses @Native annotations,
  ↓ web is reached through the hand-written js_interop mirrors.
ICU4X (Rust)
```

Each layer is the only thing that can change without ripple. If a Diplomat regen renames a binding method, only the dispatch generator + dispatch.g.dart change (facade-visible names come from the FFI side); if a JS-side name shifts, the affected runtime/web mirror. If we add a new IcuData variant, only the resolver changes. The facades stay the same shape forever.

---

## 2. The four-tier API surface

ICU4X groups its functionality into stable / experimental crates. Our facade exposes everything via one tier system:

### Tier A — STABLE
Backed by stable `icu_*` crates. Public API guaranteed across ICU4X minor versions.

`IcuPluralRules`, `IcuNumberFormat`, `IcuDateFormat`, `IcuTimeFormat`, `IcuDateTimeFormat`, `IcuZonedDateTimeFormat`, `IcuTimeZoneFormat`, `IcuListFormat`, `IcuCollator`, `IcuSegmenter`, `IcuLineSegmenter`, `IcuCaseMapper`, `IcuNormalizer`, `IcuBidi`, `IcuProperties`, `IcuPropertySet`, `IcuLocaleCanonicalizer`, `IcuLocaleExpander`, `IcuLocaleDirectionality`, `IcuLocaleFallbacker`, `IcuCalendar`, `IcuCalendarDate`, `IcuEnumProperty` family (11 maps), `IcuExemplarCharacters`, `IcuPropertyName`, `IcuLocale`, `IcuDataProvider`.

### Tier B — STABLE-WITH-CAVEAT
Backed by `icu_experimental`'s relativetime + displaynames modules. Rust API has been stable for 1+ year but the crate is labelled experimental upstream. We expose as STABLE in our facade and accept the responsibility of rolling our facade if upstream breaks it.

`IcuRelativeTimeFormat`, `IcuRegionDisplayNames`, `IcuLocaleDisplayNames`.

### Tier C — EXPERIMENTAL
Backed by `icu_experimental` AND the Rust API itself is being redesigned upstream. Marked `@experimental` at every entry point.

`IcuCurrencyFormat`, `IcuPercentFormat`, `IcuUnitFormat` — pending [unicode-org/icu4x PR #7789](https://github.com/unicode-org/icu4x/pull/7789)'s unified `CurrencyDisplay` API.

### Tier D — IDNA (locale-data-free)
Backed by the `idna` Rust crate (servo/url, reqwest use the same). Not ICU4X. Locale-independent — no CLDR data at runtime.

`IcuIdna`.

### Local IDL patches

Where upstream's Diplomat IDL doesn't expose a feature we need, we add a local patch under `vendor/icu4x/ffi/capi/src/` on the submodule's `icu_kit/2.2.0-patches` branch. Each patch carries a removal trigger comment.

Why vendor at all: the Unicode Consortium's own `package:icu4x` ships the raw machine-generated bindings without the web packaging icu_kit needs, and icu_kit needs both worlds from one source. Vendoring + running Diplomat ourselves produces Dart AND JS bindings from one Rust source — the cost is this submodule and the build hook. The submodule pins a release tag, never a branch: a plural-rule update is a user-visible behavior change, so every ICU4X bump is an explicit, reviewable commit. When upstream ships web support, switching back is evaluated (the loss would be these IDL patches).

| Patch | Exposes | Removal trigger |
|---|---|---|
| `currency_formatter.rs` | `CurrencyFormatter` + `LongCurrencyFormatter` + provider variants | Upstream PR #7789 lands the unified API |
| `percent_formatter.rs` | `PercentFormatter` + provider variant | Same as currency |
| `units_formatter.rs` | `UnitsFormatter` + provider variant | Same as currency |
| `relative_time_formatter.rs` | `RelativeTimeFormatter` (24 width × unit ctors) + 24 provider variants | `icu_experimental::relativetime` promoted into stable `icu` |
| `idna_processor.rs` | `IdnaProcessor` + UTS #46 / Punycode codec | Upstream icu_capi exposes IDNA directly |
| `bidi.rs` (edit) | Paragraph embedding level + reordered levels (UCD BidiCharacterTest columns 2 + 3) | Upstream exposes the reordered-levels accessors |
| `lib.rs` (edit) | Registers the five facade modules | Falls away with the last facade patch |
| `Cargo.toml` (edit) | `tinystr` + `idna` deps behind `experimental` | Falls away with its consumers |
| `build.rs` (edit) | Android 16 KB page-size link args (Google Play API 35+) | Upstream sets the alignment itself |

The authoritative inventory is the markers, not this table: `grep -rl "icu_kit patch" ffi/capi/` inside the vendor.

All four patched formatters now expose `*WithProvider` factory variants, so lean-binary mode (`bundleCldrData: false`) works for every facade. `IdnaProcessor` is locale-data-free; no provider needed.

---

## 3. Cross-platform paths

The same Dart facade runs on six platforms via two backends.

### 3a. Native (`dart:ffi`)

```
hook/build.dart
  ↓ on `pub get` / `flutter run`
  ├─ Reads pubspec user_define `bundleCldrData` (default true) →
  │    picks build.json's `native` or `nativeLean` feature set and the
  │    matching release-asset variant name.
  ├─ Detects target Rust triple from CodeConfig.
  ├─ RESOLVES the binary via the 5-step waterfall (§7): hash-verified
  │    cache → hash-verified GitHub Release download → cargo compile
  │    from vendor → submodule init → error. pub.dev consumers download;
  │    git/path checkouts compile (`cargo rustc --crate-type=cdylib
  │    --release`, + simple_logger).
  └─ Registers the .dylib/.so/.dll/.a as a code asset under
     `package:icu_kit/src/runtime/native/bindings/lib.g.dart`. The Diplomat-generated
     @Native symbols inside the bindings library resolve to that asset.
```

The pinned Rust nightly toolchain lives in `build.json` (`nightlyToolchain`, currently `nightly-2025-09-27`) and matches upstream's `vendor/icu4x/ffi/capi/build.sh`.

### 3b. Web (`dart:js_interop` + WebAssembly)

```
tool/build_wasm.dart
  ↓ run manually when ICU4X / IDL changes
  ├─ Runs upstream's vendor/icu4x/ffi/capi/build.sh with
  │    TARGET=wasm32-unknown-unknown (nightly Rust + -Zbuild-std).
  ├─ Outputs web_assets/icu4x.wasm (~19 MB raw, ~8 MB gzipped).
  └─ Runs `cargo run -p diplomat-gen -- js` to regenerate JS bindings
     under web_assets/lib/ (~370 .mjs + .d.ts).

bin/setup.dart
  ↓ run by consumer apps via `flutter pub run icu_kit:setup`
  ├─ Resolves icu4x.wasm via the same waterfall the native hook uses
  │    (downloads `wasm-icu4x.wasm` from the release, hash-verified;
  │    compiles via tool/build_wasm.dart on a git checkout).
  └─ Copies the committed JS bindings (web_assets/lib/ +
     diplomat.config.mjs) into the app's web/icu_kit/, where Flutter's
     web build pipeline serves them as static assets.

lib/src/runtime/web/init.dart
  ↓ at app start, via IcuKit.init()
  ├─ Calls importModule('icu_kit/lib/index.mjs') (IcuKit.moduleUrl).
  ├─ Probes the sibling diplomat-wasm.mjs for a compiled-data export —
  │    detects the loaded wasm's flavor (IcuKit.hasCompiledData).
  └─ Stores the module on IcuKit.module for facades to use.

lib/src/facade/*.dart (the same single-source facades as native)
  ↓ on every facade method call
  └─ Calls dispatch.X(localeStr, loc.ffi, ...) — the web dispatch twin —
     which calls module.getProperty<JSObject>('Foo')
     .callMethod('createBar', ...), wrapping the result in the matching
     runtime/web mirror.
```

One facade source serves both platforms; only the binding layer under the
seam differs. Tests run on both platforms.

---

## 4. The platform seams

Facades are written ONCE. All platform switching happens at three
conditional-import seams below them:

```dart
// lib/src/runtime/bindings.dart — the binding-class selector
export 'native/bindings.dart'
    if (dart.library.js_interop) 'web/bindings.dart';

// lib/src/runtime/dispatch.dart — the dispatch selector
export 'native/dispatch.g.dart'
    if (dart.library.js_interop) 'web/dispatch.g.dart';

// plus lib/src/icu_kit.dart (the IcuKit selector → runtime/*/init.dart)
```

Everything platform-shaped lives inside `lib/src/runtime/` — the two
selector files at its root, and the `native/` + `web/` halves under
them. Nothing outside `runtime/` mentions a platform (the same
`runtime/{native,web}` boundary pdf_manipulator and device_io use).

A facade imports `../runtime/bindings.dart as icu` and
`../runtime/dispatch.dart as dispatch`; under native compilation those
resolve to the FFI bindings + FFI-typed dispatch, under web to the
js_interop mirrors + mirror-typed dispatch. Because both resolutions
expose the SAME class names and Dart-visible signatures, the facade
compiles against either — the Dart compiler itself is the parity gate
(`dart analyze` checks the native resolution; the chrome test suite
compiles and runs the web one).

Why conditional exports and not runtime branching: `dart:ffi` and
`dart:js_interop` cannot coexist in one library, dead-code elimination
ships only the selected branch (keeps web binaries small), and a missing
binding fails at compile time instead of in production.

The `tool/analyze.sh` facade-import wall enforces the discipline: no file
under `lib/src/facade/` may reference `runtime/native` or `runtime/web`
directly — only the two selectors at `runtime/`'s root.

---

## 5. The dispatch layer

`lib/src/runtime/native/dispatch.g.dart` and `lib/src/runtime/web/dispatch.g.dart` are generator-emitted TWINS with identical Dart signatures — the native twin speaks FFI types, the web twin the js_interop mirrors (converting params and wrapping returns internally), so one facade call site serves both. The generator emits only the dispatch methods some facade actually calls (a `dispatch.<name>(` scan of lib/src) and formats its own output, so regeneration is byte-idempotent. The layer exists because threading the data provider through ~30 facades by hand (~150 call sites) would make every new `IcuData` configuration a facade-wide edit; with the generated seam, adding `IcuData.composite` was a one-line resolver change and no facade moved. Each method has the same shape:

```dart
// native
icu.PluralRules pluralRulesCardinal(String localeStr, icu.Locale locale) {
  final p = IcuKit.providerFor(localeStr);
  return p == null
      ? icu.PluralRules.cardinal(locale)
      : icu.PluralRules.cardinalWithProvider(p, locale);
}
```

```dart
// web — same name, same signature, JS-interop call mechanism
JSObject pluralRulesCardinal(String localeStr, JSAny? locale) {
  final cls = IcuKit.module.getProperty<JSObject>('PluralRules'.toJS);
  final p = IcuKit.providerFor(localeStr);
  if (p == null) {
    return cls.callMethod<JSObject>('createCardinal'.toJS, locale);
  }
  return cls.callMethod<JSObject>('createCardinalWithProvider'.toJS, p, locale);
}
```

`IcuKit.providerFor(localeStr)` consults the resolver (the active `IcuData` tree). The resolver returns `null` for "compiled data covers this locale" or a `DataProvider` opaque holding the lazy-loaded postcard bytes for that locale.

Apps in the default `IcuData.bundled()` configuration always get `null` — every facade call hits the compiled-data form. Apps in `IcuData.lazy(...)` configuration get a non-null provider after `preloadLocale(...)` resolved the bytes — every call hits the provider form.

### The generator

`tool/regen_dispatch.dart` walks `lib/src/runtime/native/bindings/*.g.dart`, finds every `(method, methodWithProvider)` factory pair, and emits one Dart function per pair on each platform. Two protocols handled:

- `Class.fooWithProvider` — paired with `Class.foo`. Most factories.
- `Class.withProvider` (lowercase, no base) — paired with `Class()` default ctor. Used by some classes (`Bidi`, `CaseMapper`, `LocaleFallbacker`, etc.).

The generator is idempotent: running twice produces byte-identical output. After every Diplomat regen (when the bindings change), the dispatch regen is one command.

Type-mismatch handling: when compiled and WithProvider factories take different parameter types at the same position (e.g. `GeneralCategoryGroup` vs `int`), the generator emits the appropriate cast (`.mask` for typed-enum → int).

Run the generator:

```sh
fvm dart run tool/regen_dispatch.dart
```

---

## 6. The IcuData / IcuDataSource model

Three sealed-class variants cover every realistic data-loading shape:

```dart
sealed class IcuData {
  factory IcuData.bundled({List<String>? locales}) = BundledIcuData;
  factory IcuData.lazy(IcuDataSource source, {String? fallbackLocale}) = LazyIcuData;
  factory IcuData.composite(List<IcuData> sources) = CompositeIcuData;
}

abstract class IcuDataSource {
  factory IcuDataSource.assets({required Future<ByteData> Function(String key) load,
                            String? prefix}) = _AssetsSource;
  factory IcuDataSource.callback(Future<ByteBuffer?> Function(String locale) fetch)
      = _CallbackSource;
  factory IcuDataSource.bytes(ByteBuffer bytes) = _BytesSource;
}
```

The resolver walks the tree synchronously per-locale. For lazy layers, it requires `await IcuKit.preloadLocale(locale)` to have populated the bytes cache first; if not, it throws `IcuMissingDataError` (with optional `fallbackLocale` rescue path).

These three variants are runtime *policy*: they choose which data serves and how loudly a missing locale fails. They do not change binary size. Binary size is a separate build lever — `bundleCldrData` (native) / `setup --lean` (web) picks the fat or lean binary (§7); a lean binary is fed by per-locale postcards from `slice`. The README's "Bundle size" section is the consumer-facing recipe, including why there is no locale-subset binary between fat and lean (measured in `CAPABILITY_ROADMAP.md`). Every facade routes through the dispatch layer, so every policy works for every facade with no carve-outs; `IcuIdna` is locale-data-free and works under any policy.

`IcuKit.init` validates the DETECTED binary flavor against the `IcuData` argument. The truth table — asserted cell by cell by `test/data/validation_matrix_test.dart`:

| Detected flavor | `IcuData` | Outcome |
|---|---|---|
| bundled (default) | `IcuData.bundled()` | works |
| bundled | `IcuData.bundled(locales: [...])` | works; uncovered locales throw at format time |
| bundled | `IcuData.lazy(...)` | works, but logs a warning — the compiled data ships unused |
| bundled | `IcuData.composite([bundled, lazy])` | works; bundled serves, lazy stays cold |
| lean | `IcuData.bundled(...)` | throws `IcuMissingDataError` at init — no statics in the binary |
| lean | `IcuData.lazy(...)` | works |
| lean | `IcuData.composite([bundled, lazy])` | works; bundled tier is inert, lazy serves |

The composite row pair is what lets one `init` call run unchanged on both flavors: the `BundledIcuData` layer reports itself inert when the flavor probe finds no compiled data, so the resolver walks past it to the lazy tier instead of claiming locales it cannot serve.

---

## 7. The build hook

`hook/build.dart` is the package's only build orchestrator. It resolves the native binary through the same 5-step waterfall pdf_manipulator uses (`lib/src/hook/resolver.dart`): hash-verified cache → hash-verified download from GitHub Releases → compile from vendor source → submodule init + compile → explanatory error. pub.dev consumers download (the vendored ICU4X source is far past the pub archive limit, so it's `.pubignore`d — unlike pdf_manipulator's vendor); git/path checkouts compile from source, where dev version `0.0.0` skips the download step so cargo's fingerprint check owns freshness.

Per hook invocation it:

1. Loads `build.json` — crate, repo, nightly pin, feature sets, web asset map. The single source of truth shared with `tool/compile_rust.sh` and the S7 analyze gate.
2. Reads `userDefines['bundleCldrData']` (default `true`). Picks the `native` or `nativeLean` feature set — and the matching release-asset variant (`{targetKey}-libicu_capi.*` vs `{targetKey}-lean-libicu_capi.*`).
3. Detects target via `CodeConfig.targetOS` + `targetArchitecture`; maps to the Rust triple (15 supported — see `_toRustTarget`).
4. Resolves via the waterfall, caching downloads in `outputDirectoryShared` keyed by triple + variant.
5. When compiling: `cargo rustc --crate-type=cdylib --release` on stable — or `staticlib` on the pinned nightly with `-Zbuild-std` when the link-mode PREFERENCE is static (iOS). Optimization flags (panic=abort, codegen-units=1) come from cargo config. Never force static merely because linking is enabled; release/AOT builds route the same dynamic asset through the passthrough link hook.
6. Registers the library as a `CodeAsset` under the asset ID matching `lib/src/runtime/native/bindings/lib.g.dart`, with the link mode derived from the same preference.
7. Tracks dependencies: `build.json`, `asset_hashes.dart`, `resolver.dart`, `pubspec.yaml`, the bindings barrel, the hook itself — plus, when the submodule is present, every `.rs` file under `vendor/icu4x/{components,utils,provider,ffi/capi}` and `Cargo.lock`.

Cargo's intermediate `target/` lives in `outputDirectoryShared` (per-hook scratch shared across builds). The compiled binary lands in `outputDirectory` where the Dart build pipeline picks it up.

The web half of the same machinery is `resolveWeb()` (public, called by `bin/setup.dart`): the WASM binary goes through the identical waterfall (`wasm-icu4x.wasm` release asset ↔ `tool/build_wasm.dart` source fallback), while the committed Diplomat JS bindings (`web_assets/lib/`, ~370 files) and `diplomat.config.mjs` are copied straight from the package — they ship in the pub archive like Dart source, so per-file release assets would add nothing. The web size dial is `setup --lean`, which resolves the `wasm-icu4x-lean.wasm` asset (2.1 MB vs 19 MB; `tool/build_wasm.dart --lean` is its source fallback) under the SAME local name, `icu4x.wasm` — the runtime flavor probe detects which variant loaded, so nothing else changes, and switching variants is just re-running setup (the hash check sees the other variant's hash and re-resolves). The bindings tree is flavor-independent: a lean wasm merely lacks the compiled-data exports, and dispatch never calls them. Release binaries are produced by `tool/compile_rust.sh` (mirroring the hook's exact cargo invocation, both CLDR variants per target and both wasm variants) and their hashes are stamped into `lib/src/hook/asset_hashes.dart` on the tag by the release workflow.

---

## 8. The test harness

Every test file calls `IcuKit.init()` in `setUpAll` so the resolver is configured before facades are constructed. Tests pass on native via `dart test` and on Chrome via `dart test -p chrome` (web tests need `tool/build_wasm.dart` to have produced the artifacts under `web_assets/`).

Test layout:

```
test/
  batteries/
    locale_grammar_battery.dart             — The locale-error law as ONE spec:
                                              register-only, no main
    facades_grammar_test.dart               — Runner + fleet table: every
                                              locale-taking entry point throws
                                              IcuLocaleParseError on a bad tag
  errors/
    icu_error_test.dart                     — Sealed error hierarchy contract
  data/
    icu_data_test.dart                      — IcuData / IcuDataSource / IcuKit.init shape
    postcard_round_trip_test.dart           — Real ICU4X bytes → working facades
                                              for IcuDataSource.{bytes,callback,assets}
                                              + IcuData.composite walk semantics
    with_provider_arm_test.dart             — Lazy/postcard arm of dispatch for the
                                              stable facades (plurals, decimal,
                                              datetime, time, IDNA)
    with_provider_arm_experimental_test.dart — Same arm for the 4 IDL-patched
                                              experimental facades (currency,
                                              percent, unit, relative-time)
    validation_matrix_test.dart             — bundleCldrData × IcuData truth table
  hook/
    marker_presets_test.dart                — Preset → marker expansion against the
                                              live vendored registry; format-core
                                              stays identical to the regen tool's
                                              stableMarkers
  runtime/
    native/
      flavor_probe_test.dart                — Compiled-data probe symbol resolves
                                              on fat; missing @Native symbol throws
                                              catchably (the lean-detection mechanism)
  facade/
    plural_rules_test.dart                  — One file per facade; behavioral
    ...                                       (compiled-data path)
  _corpus/
    bidi_corpus_test.dart                   — UCD BidiCharacterTest.txt (91k+ rows)
    plural_rules_corpus_test.dart
    ...                                       One file per corpus source
    postcards/                              — Generated ICU4X data blobs for the
                                              data/ tests above (~1.5 MB total)
```

Corpus tests assert per-row, no thresholds. A failed row triggers a named investigation, not a silent threshold raise.

The corpus fixtures + their provenance live under `test/_corpus/` with a [`PROVENANCE.md`](../test/_corpus/PROVENANCE.md) ledger. See [`UPDATING.md`](UPDATING.md) for the refresh procedure (including the postcard fixtures, regenerated by `tool/regen_test_postcards.dart`).

The main suite always runs against the BUNDLED flavor (icu_kit's own pubspec doesn't flip the switch, and `user_defines` bind to the build root). The lean flavor is proven two ways, each its own build-root package (the only way to flip the switch under test):

- `test_fixtures/lean_smoke/` — a minimal consumer whose pubspec IS the lean switch, with a native suite (`make test-lean`, hook builds the no-CLDR binary) and a chrome suite (`make test-web-lean`, real lean wasm installed the way `setup --lean` installs it). Both in `check`.
- `example_lean/` — the example app itself under the lean switch: a two-line shell that re-runs `example/`'s code and the shared `test_support/` suites, so the SAME journeys drive the real UI on the no-CLDR binary with asset postcards (`make test-example-lean-matrix`; `make verify-web-lean` for the web build). CI-only — slicing the `kit` preset per locale takes minutes.

---

## 9. Diplomat divergences

Bindings are generated, never handrolled: ICU4X exposes ~1500 FFI symbols, and Diplomat emits Dart and JS from one Rust IDL — a regen per version bump replaces months of drift-prone manual FFI.

ICU4X's Diplomat tool generates bindings for both Dart (native) and JavaScript (web) from the same Rust IDL. The two sides have small naming + protocol divergences that the facades absorb:

| Divergence | Native | Web | Adapter |
|---|---|---|---|
| Constructors with `try_new` semantics | `Foo.variant()` factory | `static createVariant()` static method | Web facade calls `create*` form |
| Plain `try_new` constructors (no variants) | `Foo()` factory | `new Foo(...)` via `callAsConstructor` | Web facade uses `callAsConstructor` |
| Boolean-returning methods | Returns `bool` directly | Returns 0/1 as `JSNumber` (`JSBoolean.toDart` throws on dart2js) | Web facades have a `_readBool` helper |
| Iterator protocol | `Iterator.moveNext()` + `current` | JS protocol: `next() → {value, done}` | `IcuLocaleFallbacker` web facade adapts |
| Time-zone IANA constructor | `TimeZone.fromIanaId(...)` | `TimeZone.createFromIanaId(...)` | Web facade uses `create*` form |
| Enum value lookup | `.values[index]` | `.getProperty<JSObject>('Name')` | Web facades index by name string |
| GeneralCategory integer values | Indices NOT contiguous (otherPunctuation=23, mathSymbol=24, currencySymbol=25, …; initialPunctuation=28, finalPunctuation=29) | Same FFI numeric values | Both facades use a manual `_decodeGeneralCategory` switch |

When a divergence is discovered, document it here and add a unit test that fails LOUDLY if Diplomat changes the protocol.

---

## 10. Where to look when X happens

| Symptom | First place to look |
|---|---|
| New facade method's binding doesn't appear after Diplomat regen | `vendor/icu4x/ffi/capi/src/<name>.rs` — does the `pub fn` have `#[diplomat::attr(... named_constructor = "...")]`? Without it, Diplomat emits as `static` not `factory`. The dispatch generator only matches factories. |
| Dispatch regen doesn't pick up a new factory pair | `tool/regen_dispatch.dart` — check `_extractPairs`. The base name (with `WithProvider` / `AndProvider` suffix stripped) must match an existing factory in the same class. |
| Native test fails, web passes (or vice versa) | The facade source is shared, so the divergence is under the seams: the `runtime/web/bindings/` mirror for the class (a wrong JS name fails only at runtime with `_this[method] is not a function`) or the dispatch twins (`lib/src/runtime/{native,web}/dispatch.g.dart`) for that method. |
| Lean-binary build fails at link time | Cargo `compiled_data` feature was dropped but a facade still calls a `*` factory (no provider). The facade must route through dispatch — every facade should. |
| Lean binary but init doesn't throw for bundled-only data | The flavor probe (`lib/src/runtime/native/flavor_probe.dart`) resolved its symbol — check the binary actually lacks compiled data (`nm <lib> \| grep create_cardinal_mv1`) and that the probe's symbol still matches the vendored `#[cfg(feature = "compiled_data")]` gate. |
| Web tests fail with "module not found" | `tool/build_wasm.dart` hasn't run, or `bin/setup.dart` hasn't been run from the consumer app. |

---

## 11. The one-line summary

> **Five layers, generator-driven dispatch, conditional-import facades, build hook + WASM tool. Every facade routes through dispatch — bundled, locale-restricted, lazy, composite all work without facade changes. IDL patches add what upstream doesn't expose; the generator absorbs the rest.**
