# icu_kit example

A Flutter app exercising every `icu_kit` facade — number, date, and list
formatting, plural rules, collation, segmentation, case mapping,
normalization, bidi, IDNA, display names, and the locale algebra. Pick a
locale in the app bar and watch every surface re-render in that culture's
shape. Nothing touches assets or the network; the CLDR data is compiled
into the native library by the build hook. Runs on macOS, iOS, Android,
Windows, Linux, and web.

## Run

```bash
cd example

# desktop (the build hook compiles icu_capi on first run; needs Rust)
fvm flutter run -d macos

# web (setup copies the WASM + JS bindings into web/)
fvm flutter pub run icu_kit:setup --force web
fvm flutter run -d chrome

# any connected device
fvm flutter run -d <device>
```

## Tests

```bash
# host-VM journey matrix — the four tabs driven end to end through the
# REAL engine, across every device profile; no device needed:
cd example
fvm flutter test test/journeys

# integration smoke — every facade against the REAL native library on a
# real target (also proves the Android 16 KB page-size build):
fvm flutter test integration_test/icu_kit_smoke_test.dart -d macos
fvm flutter test integration_test/icu_kit_smoke_test.dart -d <device>

# or from the package root:
cd ..
make test-example-matrix
make test-example-macos

# one real target at a time (CI's full-test runs each of these):
make test-example-android   # also: -ios, -linux, -windows, -web
make verify-macos           # release build; also: -android, -ios, -linux, -windows, -web
```

The host journeys drive the exact UI a user sees against the real engine
— the locale picker, the plural stepper, and the live text/locale input
fields — and run across every device profile, so a locale whose output
overflows the phone-small layout fails locally on every run, never first
in CI. The integration smoke re-runs the same assertions programmatically
on real targets, pinning the engine itself so a target-specific
build/link/data regression can't hide behind widget behavior. The Data
journey owns the only tests that mutate global engine state (loading a
bundled subset) — `flutter test` isolates suites per file, so the other
journeys never see the subset.

## What's inside

Four tabs, one per facade family, all reactive to the app-bar locale
picker:

| Tab | Facades | What it covers |
|---|---|---|
| **Format** | `IcuNumberFormat`, `IcuCurrencyFormat`, `IcuPercentFormat`, `IcuUnitFormat`, `IcuPluralRules`, `IcuDateFormat`, `IcuTimeFormat`, `IcuDateTimeFormat`, `IcuRelativeTimeFormat`, `IcuListFormat` | Decimal grouping, currency, percent, and unit formatting; an interactive plural stepper driving real CLDR categories; dates, times, relative time, and list conjunctions. |
| **Text** | `IcuSegmenter`, `IcuCaseMapper`, `IcuNormalizer`, `IcuBidi`, `IcuIdna` | Thai word segmentation (no spaces), locale-aware case mapping (Turkish dotted İ, German ß → SS), NFC composition, mixed-direction bidi analysis, and live IDNA punycode round-trips. |
| **Locale** | `IcuLocale`, `IcuLocaleExpander`, `IcuLocaleDirectionality`, `IcuLocaleFallbacker`, `IcuRegionDisplayNames`, `IcuLocaleDisplayNames`, `IcuCollator` | Live parse/canonicalize, likely-subtags maximize/minimize, direction, fallback chains, display names, and Swedish collation (å/ö after z). |
| **Data** | `IcuKit.init`, `IcuData` | The binary-size dial: load a bundled `en + fr` subset and watch every other locale flip to `IcuDataError`, then restore. The rejection is the feature — ship only the locales you support, and the miss is loud, not garbled. |

Every facade call is wrapped so an uncovered locale renders as an
`IcuDataError` row instead of crashing the demo — the error surface is
itself part of the tour (see the Data tab).

## One file on purpose

The whole app lives in `lib/main.dart` because pub.dev renders that file
as the package's Example tab — splitting it would hide everything else
from that page.

## No `dart:io`

The host journeys stay in memory — they drive the UI through the real
engine, which needs no filesystem. The same code compiles unchanged for
native and web; real on-device concerns (the per-target build, the
Android 16 KB page size) live in the integration smoke.
