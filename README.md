<!--
  Banner stays <picture> for GitHub's dark/light. pub.dev strips <picture>
  when sanitizing the README, so the publish step flattens it to the inner
  <img> via `tool/ci/release.sh --stamp-readme` (the repo copy is untouched).
  Drop both once pub.dev renders <picture>. Tracking:
  dart-lang/pub-dev#5923, dart-lang/pub-dev#6363, google/dart-neats#383.
-->
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)"  srcset="assets/banner_dark-web-min.webp">
    <source media="(prefers-color-scheme: light)" srcset="assets/banner_light-web-min.webp">
    <img alt="icu_kit — every locale, every platform. ICU4X internationalization for Dart & Flutter"
         src="assets/banner_light-web-min.webp" width="100%">
  </picture>
</p>

<p align="center">
  <a href="https://pub.dev/packages/icu_kit"><img src="https://img.shields.io/pub/v/icu_kit.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/icu_kit/score"><img src="https://img.shields.io/pub/likes/icu_kit" alt="likes"></a>
  <a href="https://pub.dev/packages/icu_kit/score"><img src="https://img.shields.io/pub/points/icu_kit" alt="pub points"></a>
  <a href="https://github.com/whuppi/icu_kit"><img src="https://img.shields.io/github/stars/whuppi/icu_kit?style=flat&logo=github" alt="GitHub stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license: MIT"></a>
</p>

Everything a Dart or Flutter app needs to work in any language: number formatting, plural rules, date/time formatting, lists, locale-aware sorting, breaking text into words/sentences, case mapping, normalization, right-to-left layout helpers, calendars (Hebrew, Hijri, Japanese, …), time zones, internationalized domain names. Unicode's **ICU4X** engine is compiled in — the same engine, the same output, on every platform: native via `dart:ffi`, web via WebAssembly.

> **Status:** 0.x. The API can change between minor versions until `1.0.0` — pre-1.0, the minor is the breaking axis, so pin `^0.N.0` and read the changelog on minor bumps. Separately, three formatters (currency, percent, unit) are `@experimental` because upstream ICU4X is still redesigning their API; those can change even after 1.0 and are flagged where they appear.

> like it? a [⭐ star](https://github.com/whuppi/icu_kit) or [👍 like](https://pub.dev/packages/icu_kit) is the entire marketing budget. [Bugs & features →](https://github.com/whuppi/icu_kit/issues)

---

<details>
<summary><b>👀 Peek inside</b></summary>

- [Install](#install)
  - [Add the dependency](#add-the-dependency)
  - [Native](#native)
  - [Web](#web)
- [Quick start](#quick-start)
- [Usage](#usage)
  - [Numbers](#numbers)
  - [Dates and times](#dates-and-times)
  - [Lists, sorting, relative time](#lists-sorting-relative-time)
  - [Splitting text the right way](#splitting-text-the-right-way)
  - [Casing, normalization, bidi](#casing-normalization-bidi)
  - [Locale properties + display names](#locale-properties--display-names)
  - [Calendar arithmetic](#calendar-arithmetic)
  - [Unicode properties](#unicode-properties)
  - [Domain names that aren't English](#domain-names-that-arent-english)
- [Error handling](#error-handling)
- [Bundle size — making icu_kit small](#bundle-size--making-icu_kit-small)
  - [Pick your shape](#pick-your-shape)
  - [Going lean](#going-lean)
  - [Postcard sizes by preset](#postcard-sizes-by-preset)
  - [Runtime data policy](#runtime-data-policy)
  - [Why no locale-subset binary](#why-no-locale-subset-binary)
  - [Custom data sources](#custom-data-sources)
- [Platform support](#platform-support)
- [Choosing icu_kit (and when not to)](#choosing-icu_kit-and-when-not-to)
- [Docs](#docs)
- [License](#license)

</details>

---

## Install

### Add the dependency

```yaml
dependencies:
  icu_kit:
```

### Native

Nothing to do. On iOS, Android, macOS, Windows, and Linux, the build hook downloads the right binary on first build — hash-verified against the release. Both flavors are published per target: the default with the CLDR baked in, and the lean one for apps that opt out via `bundleCldrData` (see [Bundle size](#bundle-size--making-icu_kit-small)).

### Web

Web can't auto-download native assets, so run setup once. It fetches the prebuilt WASM engine and installs the JS bindings into `web/icu_kit/`. Run it again after any `pub upgrade`, since the asset is tied to the package version:

```sh
flutter pub run icu_kit:setup
```

Pin the version, too, so a `pub upgrade` can't silently bump it and leave that fetched asset stale:

```yaml
icu_kit: X.Y.Z  # exact version
```

<details>
<summary><b>🧰 all the setup commands</b></summary>

```sh
flutter pub run icu_kit:setup                  # web (default)
flutter pub run icu_kit:setup <target>         # web|android|ios|macos|linux|windows
flutter pub run icu_kit:setup --lean           # web, lean WASM (see Bundle size)
flutter pub run icu_kit:setup --force <target> # re-resolve (debugging)
```

</details>

<details>
<summary><b>🧩 wait — why does web need a setup step?</b></summary>

<br>

Flutter's build system automatically downloads native binaries for
iOS, Android, etc., but it doesn't support web assets (WASM, JS)
yet. The setup command fills that gap: it downloads the pre-built
WASM engine, or compiles it from the vendored Rust source when
you're on a git checkout (that path needs the Rust toolchain and a
`--recursive` clone — see [CONTRIBUTING](CONTRIBUTING.md)).

This will go away when Dart/Flutter adds WASM/JS asset support to
build hooks. Tracking: [dart-lang/native#988](https://github.com/dart-lang/native/issues/988)

</details>

---

## Quick start

A whirlwind tour. Same numbers, three locales, three writing systems — each correct for the language it's rendered in:

```dart
import 'package:icu_kit/icu_kit.dart';

Future<void> main() async {
  await IcuKit.init();

  // Numbers — same value, three locales
  final n = 1234567.89;
  print(IcuNumberFormat.decimal(locale: 'en-US').format(n));  // "1,234,567.89"
  print(IcuNumberFormat.decimal(locale: 'fr').format(n));     // "1 234 567,89"
  print(IcuNumberFormat.decimal(locale: 'de').format(n));     // "1.234.567,89"

  // Plurals — which form a number takes ("1 item" vs "5 items")
  final rules = IcuPluralRules.cardinal('en');
  rules.category(1);    // IcuPluralCategory.one
  rules.category(5);    // IcuPluralCategory.other
  // Polish has more forms: 1 → one, 2 → few, 5 → many. CLDR knows the rules.

  // Dates
  final today = DateTime.now();
  print(IcuDateFormat.ymd(locale: 'en-US').format(today));    // "Apr 28, 2026"
  print(IcuDateFormat.ymd(locale: 'ja').format(today));       // "2026/04/28"
}
```

`IcuKit.init()` is the one bootstrap step. Call it once at app startup, await it, then construct facades freely. Each facade is locale-pinned at construction; reuse instances across calls for the same `(locale, options)` tuple.

---

## Usage

One capability per section — every formatter follows the same shape:
parse an `IcuLocale`, construct the facade, call it.

### Numbers

Decimal, currency, percent, and units. Each is a separate facade because they have different option spaces.

```dart
// Same number, three locales. German swaps period and comma — easy to miss
// without a formatter, very embarrassing in a finance UI.
print(IcuNumberFormat.decimal(locale: 'en-US').format(1234.5));   // "1,234.5"
print(IcuNumberFormat.decimal(locale: 'de').format(1234.5));      // "1.234,5"
print(IcuNumberFormat.decimal(locale: 'ja').format(1234567));     // "1,234,567"
```

```dart
// Currency — pick the locale once, switch currency per call.
// JPY has no decimals; CLDR knows.
final shop = IcuCurrencyFormat.symbol(locale: 'en-US');
print(shop.format(1234.56, currencyCode: 'USD'));   // "$1,234.56"
print(shop.format(1234.56, currencyCode: 'EUR'));   // "€1,234.56"
print(shop.format(1234.56, currencyCode: 'JPY'));   // "¥1,235"

// Long form pluralizes the currency name. One dollar, two dollars — automatic.
final receipt = IcuCurrencyFormat.long(locale: 'en-US', currencyCode: 'USD');
print(receipt.format(1));    // "1 US dollar"
print(receipt.format(2));    // "2 US dollars"
```

```dart
// Percent — heads-up: does NOT auto-scale (50 → "50%", not 0.5 → "50%").
// For ECMA-402's `Intl.NumberFormat({style:'percent'})` semantics, scale yourself.
final pct = IcuPercentFormat(locale: 'en-US');
print(pct.format(42.5));   // "42.5%"
```

```dart
// Units — pluralization is CLDR's problem, not yours.
final speed = IcuUnitFormat(locale: 'en', unit: 'kilometer-per-hour');
print(speed.format(1));     // "1 kilometer per hour"
print(speed.format(120));   // "120 kilometers per hour"  ← the 's' is automatic

// 730+ CLDR unit identifiers. Bytes, hectares, fluid-ounces, fortnights — pick one.
final fr = IcuUnitFormat(locale: 'fr', unit: 'kilogram', width: IcuUnitWidth.short);
print(fr.format(2.5));      // "2,5 kg"
```

> **Note:** `IcuCurrencyFormat`, `IcuPercentFormat`, and `IcuUnitFormat` are marked `@experimental` because they're backed by `icu_experimental` Rust crates pending [unicode-org/icu4x PR #7789](https://github.com/unicode-org/icu4x/pull/7789)'s unified `CurrencyDisplay` API. The current API works; if upstream changes shape, we'll document the migration.

---

### Dates and times

Three classes for date-only, time-only, and combined. You pick which parts to show (year+month+day? just month+day?). The locale picks the punctuation, ordering, AM/PM vs 24-hour, and the wording.

```dart
// Date-only — 10 shapes to choose from (ymd, md, ymde, mde, de, y, m, d, e, ym).
// You pick which parts; the locale fills in the rest.
final date = IcuDateFormat.ymd(locale: 'en-US');
print(date.format(DateTime.now()));    // "Apr 28, 2026"

final long = IcuDateFormat.ymd(locale: 'fr', length: IcuDateLength.long);
print(long.format(DateTime.now()));    // "28 avril 2026"  ← month name + lowercase

// Time-only — length + time-precision + alignment. Locale picks 12h or 24h.
print(IcuTimeFormat(locale: 'en-US').format(DateTime.now()));   // "2:32 PM"
print(IcuTimeFormat(locale: 'fr').format(DateTime.now()));       // "14:32"

// Combined — 7 field sets (dt, mdt, ymdt, det, mdet, ymdet, et).
final dt = IcuDateTimeFormat.ymdt(locale: 'de', length: IcuDateLength.short);
print(dt.format(DateTime.now()));   // "28.04.26, 14:32"
```

#### Calendar systems, numbering systems, hour cycles via BCP47

The locale string is a remote control. Pass `-u-ca-` / `-u-nu-` / `-u-hc-` extensions and the formatter swaps calendar, numerals, or clock without touching anything else:

```dart
// 'en' UI text + Reiwa-era dates? One locale string, no extra config.
final reiwa = IcuDateFormat.ymd(locale: 'en-u-ca-japanese', length: IcuDateLength.long);
print(reiwa.format(DateTime.now()));   // "April 28, 8 Reiwa"

// English month name with Arabic-Indic digits — pick mix-and-match.
final mixed = IcuDateFormat.ymd(locale: 'en-u-nu-arab');
print(mixed.format(DateTime.now()));   // "Apr ٢٨, ٢٠٢٦"

// Force 24-hour clock in en-US (which would otherwise be 12-hour).
final military = IcuTimeFormat(locale: 'en-US-u-hc-h23');
print(military.format(DateTime(2026, 4, 28, 14, 32)));   // "14:32"
```

#### Time zones

```dart
// One formatter, IANA zone id per call. CLDR knows DST → "PDT" not "PST" in summer.
final zoned = IcuZonedDateTimeFormat.ymdt(
  locale: 'en-US',
  zoneStyle: IcuZoneStyle.specificShort,
);
print(zoned.format(
  DateTime.now(),
  ianaTimeZoneId: 'America/Los_Angeles',
  utcOffsetSeconds: -7 * 3600,
));   // "Apr 28, 2026, 2:32:07 PM PDT"

// Standalone label, in the user's language.
final tz = IcuTimeZoneFormat(locale: 'fr', style: IcuTimeZoneStyle.genericLong);
print(tz.format(
  ianaTimeZoneId: 'America/Los_Angeles',
  date: DateTime.now(),
  utcOffsetSeconds: -7 * 3600,
));   // "heure du Pacifique nord-américain"
```

---

### Lists, sorting, relative time

```dart
// Lists — Oxford comma in English, "ou" in French. CLDR knows the joiners.
final and = IcuListFormat.and(locale: 'en');
print(and.format(['Aria', 'Kael', 'Mira']));    // "Aria, Kael, and Mira"

final or = IcuListFormat.or(locale: 'fr');
print(or.format(['rouge', 'vert', 'bleu']));    // "rouge, vert ou bleu"

// Japanese uses '、' as the joiner — same call, different glyph.
print(IcuListFormat.and(locale: 'ja').format(['赤', '青', '緑']));  // "赤、青、緑"
```

```dart
// Locale-aware sorting — Swedish doesn't think 'Åsa' belongs next to 'Anna'.
final sv = IcuCollator(locale: 'sv');
final names = ['Östen', 'Anna', 'Åsa']..sort(sv.compare);
print(names);   // ['Anna', 'Åsa', 'Östen']  ← Swedish puts å, ö after z

// Numeric collation — the "file2 vs file10" annoyance, solved per locale.
final numeric = IcuCollator(locale: 'en-u-kn-true');
final files = ['file10.txt', 'file2.txt']..sort(numeric.compare);
print(files);   // ['file2.txt', 'file10.txt']
```

```dart
// Relative time — "tomorrow", not "in 1 day". `numeric: auto` is the trick.
final rel = IcuRelativeTimeFormat(
  locale: 'en',
  unit: IcuRelativeTimeUnit.day,
  numeric: IcuRelativeTimeNumeric.auto,
);
print(rel.format(1));    // "tomorrow"
print(rel.format(-1));   // "yesterday"
print(rel.format(7));    // "in 7 days"

// Polish picks the right plural form per count — 4 categories, all handled.
final pl = IcuRelativeTimeFormat(locale: 'pl', unit: IcuRelativeTimeUnit.day);
print(pl.format(2));     // "za 2 dni"
print(pl.format(5));     // "za 5 dni"
```

---

### Splitting text the right way

Counting characters the way humans see them, finding word and sentence boundaries, knowing where it's OK to wrap a line. Useful for emoji counts, building your own text widget, custom text layout.

```dart
// "🇯🇵👨‍👩‍👧!" — Dart's `.length` says 11. A user would say 4.
final graphemes = IcuSegmenter.grapheme();
print(graphemes.segments('🇯🇵👨‍👩‍👧!').length);   // 4 — flag, family, !, end

// Word boundaries, language-aware. Thai writes without spaces;
// ICU4X uses a small ML model to find word breaks.
final words = IcuSegmenter.word(locale: 'th');
for (final s in words.segments('สวัสดีครับ')) {
  print(s.text);   // "สวัสดี" then "ครับ"
}

// Sentence boundaries — knows "Mr. Smith" isn't two sentences.
final sentences = IcuSegmenter.sentence(locale: 'en');
print(sentences.segments('Hello world. How are you?').length);   // 2

// Where can a line legally wrap? (Building your own text widget? Start here.)
final lines = IcuLineSegmenter.auto();
for (final i in lines.breakOpportunities('The quick brown fox')) {
  print(i);   // 4, 10, 16, 19
}
```

---

### Casing, normalization, bidi

```dart
// Locale-aware case mapping — "ISTANBUL" or "İSTANBUL"? Turkish picks the dotted I.
final cm = IcuCaseMapper();
print(cm.uppercase('istanbul', locale: 'tr'));   // "İSTANBUL"  ← dotted, not "ISTANBUL"
print(cm.uppercase('straße', locale: 'de'));     // "STRASSE"   ← ß → SS in German
print(cm.lowercase('İSTANBUL', locale: 'tr'));   // "istanbul"  ← round-trips

// Case-insensitive comparison via fold (the right way — `.toLowerCase()` lies).
print(cm.fold('Hello'));     // "hello"
print(cm.foldTurkic('İi'));  // Turkic-correct fold for searching/matching
```

```dart
// "café" can be one composed codepoint OR five decomposed ones. Same string visually.
// NFC composes; NFD decomposes. Compare strings safely → normalize first.
final nfc = IcuNormalizer(IcuNormalizationForm.nfc);
print(nfc.normalize('e\u{0301}'));    // "é" (1 codepoint)

final nfd = IcuNormalizer(IcuNormalizationForm.nfd);
print(nfd.normalize('é'));            // "e\u{0301}" (2 codepoints)

// NFKC: ligatures, presentation forms, and "compatibility" tricks decompose to plain letters.
final nfkc = IcuNormalizer(IcuNormalizationForm.nfkc);
print(nfkc.normalize('ﬁ'));           // "fi"  ← single ligature glyph → 2 letters
```

```dart
// "Hello مرحبا world" — the Arabic part flips when displayed.
// This tells you the visual order. (Flutter's Text widget does it for you;
// reach for this when building your own text widget.)
final bidi = IcuBidi();
final analysis = bidi.analyze('Hello مرحبا world');
final paragraph = analysis.paragraph(0)!;
print(paragraph.direction);   // IcuBidiDirection.mixed
print(paragraph.reorderLine(0, paragraph.size));   // visual reorder for rendering
```

---

### Locale properties + display names

```dart
// Country picker in French? Locale picker in Japanese? Done.
final regions = IcuRegionDisplayNames(locale: 'fr');
print(regions.of('US'));    // "États-Unis"
print(regions.of('JP'));    // "Japon"

final locales = IcuLocaleDisplayNames(locale: 'ja');
print(locales.of('en-GB'));   // "イギリス英語"
print(locales.of('zh-Hant')); // "繁体字中国語"
```

```dart
// "Should I render this RTL?" — without hardcoding a list of RTL languages.
final dir = IcuLocaleDirectionality();
print(dir.isRtl('ar'));     // true
print(dir.isLtr('en'));     // true

// What does ICU4X try when 'en-Latn-US' has no data? Walk its fallback chain.
final fb = IcuLocaleFallbacker();
print(fb.chain('en-Latn-US').toList());   // ['en-Latn-US', 'en-US', 'en']

// CLDR's canonicalization — "cka" really means "cmr".
final canon = IcuLocaleCanonicalizer();
print(canon.canonicalize('cka'));         // "cmr"
print(canon.canonicalize('nob-bokmal'));  // "nb"

// Maximize / minimize subtags — same trick as JS's `Intl.Locale.maximize()`.
final exp = IcuLocaleExpander();
print(exp.maximize('en'));         // "en-Latn-US"
print(exp.minimize('en-Latn-US')); // "en"
```

```dart
// Which characters does a language actually write with? Useful for
// keyboard layouts, input validation, "is this text plausibly German?".
final de = IcuExemplarCharacters(locale: 'de', set: IcuExemplarSet.main);
print(de.contains('ß'.runes.first));   // true
print(de.contains('ñ'.runes.first));   // false — Spanish, not German

// Five sets per locale: main, auxiliary, punctuation, numbers, index headers.
```

---

### Calendar arithmetic

17 calendars beyond Gregorian — Hebrew, Hijri (4 variants), Buddhist, Japanese, Persian, ROC, Coptic, Ethiopian (Amete-Mihret + Amete-Alem), Indian, Chinese, Dangi, ISO. Each one knows its own months, eras, and leap rules.

```dart
// What's today's date in the Reiwa era?
final japanese = IcuCalendar(IcuCalendarKind.japanese);
final reiwaToday = IcuCalendarDate.fromDartDateTime(DateTime.now(), calendar: japanese);
print('${reiwaToday.era} ${reiwaToday.eraYearOrRelatedIso}');
// "reiwa 8"  ← April 28, 2026 = Reiwa 8

// Convert any Gregorian date to the Hebrew calendar.
final hebrew = IcuCalendar(IcuCalendarKind.hebrew);
final hebrewDate = IcuCalendarDate.fromGregorian(
  year: 2026, month: 4, day: 28,
  calendar: hebrew,
);
print('${hebrewDate.year}/${hebrewDate.month}/${hebrewDate.day}');
// → the corresponding Hebrew calendar date

// Pair this with `IcuDateFormat.ymd(locale: 'en-u-ca-hebrew')` for rendering.
```

See `IcuCalendarKind` for the full enum.

---

### Unicode properties

```dart
// 45 binary properties — perfect for input validators and tokenizers.
print(IcuProperties.isEmoji(0x1F680));        // true   ← 🚀
print(IcuProperties.isXidStart(0x41));        // true   ← 'A' starts a Dart identifier
print(IcuProperties.isAlphabetic(0x03B1));    // true   ← Greek α

// 11 enum properties — Script tells you which writing system a codepoint belongs to.
final gc = IcuGeneralCategoryMap();
print(gc.get(0x41));    // IcuGeneralCategory.uppercaseLetter   ← 'A'
print(gc.get(0x1F680)); // IcuGeneralCategory.otherSymbol       ← 🚀

final scripts = IcuScriptMap();
print(scripts.get(0x4E2D));   // 17 (Han script — '中')
```

---

### Domain names that aren't English

For URL host validation, email handling, anywhere a domain might use non-English letters. The DNS itself only speaks ASCII, so `日本.jp` is stored as `xn--wgv71a.jp` — these helpers convert both ways.

```dart
final idna = IcuIdna.url();
print(idna.toAscii('日本.jp'));            // "xn--wgv71a.jp"
print(idna.toAscii('münchen.de'));         // "xn--mnchen-3ya.de"
print(idna.toUnicode('xn--wgv71a.jp'));    // "日本.jp"
```

Three modes for different needs: `IcuIdna.url()` (what browsers do — most lenient, default), `IcuIdna.strict()` (DNS-only), `IcuIdna.uts46()` (strict standards conformance).

IDNA doesn't need any locale data — it works no matter how you set up the data loading below.

---

## Error handling

`IcuError` is a sealed hierarchy. Every failure mode is a typed subclass; pattern-match to handle.

```dart
try {
  IcuLocale.parse('not a locale');
} on IcuLocaleParseError catch (e) {
  print(e.message);   // "Invalid BCP-47 tag: 'not a locale'"
}

try {
  IcuIdna.strict().toAscii('xn--');
} on IcuIdnaError catch (e) {
  print(e.message);
}
```

The full hierarchy:

| Error | Thrown when |
|---|---|
| `IcuLocaleParseError` | A locale string isn't valid BCP-47 |
| `IcuFormatError` | A formatter rejects an input value |
| `IcuDataError` | CLDR data lookup failed (formatter unavailable for this locale) |
| `IcuIdnaError` | IDNA conformance failure |
| `IcuMissingDataError` | Lazy-loaded locale isn't available (see "Bundle size" below) |
| `IcuLoadError` | Internal: facade can't reach the underlying ICU4X (e.g., `IcuKit.init` not awaited) |

All extend `IcuError` if you want a single catch-all.

---

## Bundle size — making icu_kit small

The binary comes in two builds. The **fat** build (the default) carries every CLDR locale inside it. The **lean** build carries no locale data and reads it from files at runtime:

| Binary | Native app, on disk | Web, browser download |
|---|---:|---:|
| **Fat** — every locale included (default) | ~21 MB | ~8 MB gzipped (19 MB raw) |
| **Lean** — no locale data | ~3 MB | 0.6 MB gzipped (2.1 MB raw) |

A native binary ships inside the app install, so only its disk size matters. The web binary is downloaded by the browser; servers compress it and browsers cache it, so the first visit is the worst case.

For most apps the fat default is fine. When the size matters, you make two choices:

1. **Which binary?** Fat or lean. This is the only choice that changes binary size, and it is all-or-nothing: there is no binary with "just my ten locales" inside ([why](#why-no-locale-subset-binary)).
2. **Which data files?** A lean binary reads per-locale **postcards** — data files you generate with the `slice` tool and ship as assets. Their size depends on which facades you include, from 68 KB to 7.3 MB per locale ([measured](#postcard-sizes-by-preset)).

The `IcuData` argument to `init()` is a third, separate knob. It picks *which* data serves at runtime and *how loudly* a missing locale fails. It never changes binary size ([full rules](#runtime-data-policy)).

### Pick your shape

| Your app | Choose | You ship |
|---|---|---|
| Serves many locales, size is not a concern | fat (the default) + `IcuKit.init()` | the binary, nothing else |
| Serves a known set of locales | lean + postcards as Flutter assets | the lean binary + one postcard per locale |
| Adds or downloads locales at runtime | lean + postcards fetched from your server | the lean binary; postcards download on demand |

### Going lean

Four steps take you from the fat default to a lean binary fed by postcards.

**Step 1 — generate the postcards** from your app's directory:

```sh
dart run icu_kit:slice --locales=und,en,fr,ja --markers=kit --per-locale
```

This writes `assets/icu/und.postcard`, `en.postcard`, `fr.postcard`, `ja.postcard`. The default `--out=assets/icu/` matches `IcuDataSource.assets`'s default prefix, so no extra wiring. Pick a lighter `--markers` preset when you don't need every facade ([measured sizes](#postcard-sizes-by-preset)).

`und` is not a typo: the locale-independent data — segmentation dictionaries, Unicode property tables — lives under the `und` locale, and the text facades read it for every language. Slice and preload `und` whenever your preset includes those facades; an app that only formats numbers and dates with `format-core` can skip it.

**Step 2 — declare the assets** in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/icu/
```

**Step 3 — drop the bundled CLDR data from the binary.** One switch per world.

Native, in your app's `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    icu_kit:
      bundleCldrData: false
```

Web, by re-running setup with the lean flag (installs the lean wasm in place of the fat one; run setup without the flag to switch back):

```sh
flutter pub run icu_kit:setup --lean
```

That is the whole switch. It drops the cargo `compiled_data` feature, so the build hook (native) or setup (web) fetches the lean binary. At startup `IcuKit.init` **detects** which binary it actually got and validates your `IcuData` against it, so a misconfiguration fails at init, loudly ([full rules](#runtime-data-policy)).

**Step 4 — init lazily:**

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:icu_kit/icu_kit.dart';

Future<void> main() async {
  await IcuKit.init(data: IcuData.lazy(
    IcuDataSource.assets(load: rootBundle.load),
  ));

  // Pre-load 'und' (if you sliced it) and the locale your app starts in.
  // After this completes, every formatter for that locale constructs
  // synchronously.
  await IcuKit.preloadLocale('und');
  await IcuKit.preloadLocale('en');

  runApp(const MyApp());
}
```

When the user switches locale at runtime, call `preloadLocale` for the new one.

### Postcard sizes by preset

<details>
<summary><b>🧰 measured for <code>de</code>, icu4x 2.2 — seven presets</b></summary>

<br>

`slice` groups markers into presets that match icu_kit's facade families, so you write `--markers=format-core` instead of naming fourteen markers. Measured for locale `de`, icu4x 2.2:

| `--markers` | Covers | `de.postcard` |
|---|---|---:|
| `format-core` | numbers, plurals, Gregorian dates and times, locale parse, IDNA | 68 KB |
| `format-extended` | the above plus currency, percent, units, relative time, lists, compact, duration | 224 KB |
| `locale` | collation, display names, likely-subtags | 775 KB |
| `text` | segmentation, case mapping, normalization, properties, bidi | 4.6 MB |
| `kit` | every family above, what the example app uses | 5.6 MB |
| `all` (default) | every marker icu4x ships, including non-Gregorian calendars and time zones | 7.3 MB |
| exact `DecimalSymbolsV1,PluralsCardinalV1` | just those two markers | 198 B |

`text` and `kit` are heavy because they carry the Unicode property tables and segmentation dictionaries, which is inherent to those facades rather than waste. An app that only formats numbers and dates ships `format-core` at 68 KB per locale. You can also pass a comma-separated list of exact marker names for a hand-picked set.

</details>

### Runtime data policy

<details>
<summary><b>🧩 what the <code>IcuData</code> argument actually controls</b></summary>

<br>

The `IcuData` argument to `init()` chooses which data serves and how a missing locale fails. None of these change binary size:

- `IcuData.bundled()` (the default) serves every locale the binary carries. Fat binary only.
- `IcuData.bundled(locales: [...])` serves **only** the listed locales; a request for any other throws loudly instead of silently falling back to root data. A correctness guard — the binary still contains every locale.
- `IcuData.lazy(source)` loads postcards on demand, from assets or from your server. The lean path.
- `IcuData.composite([bundled, lazy])` tries the binary's data first, then the postcards. This is the one call that works unchanged on **both** binaries: on a fat binary the bundled tier serves and the postcards are never read; on a lean binary the bundled tier has nothing and the postcards serve. Useful when the same code ships in apps with different builds — the example app runs this way (see [`example_lean/`](example_lean/)).

At startup, `IcuKit.init` checks the binary it actually loaded against this argument and throws an actionable error on a mismatch: a lean binary with no lazy source configured fails at init, not mid-run. The full binary × `IcuData` truth table is in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md); the short version is that only one combination is fatal (lean binary, bundled-only data) and one is wasteful (fat binary, lazy-only data — you ship ~19 MB of CLDR and never read it; init logs a warning).

</details>

### Why no locale-subset binary

<details>
<summary><b>🧩 we measured it — the numbers say no</b></summary>

<br>

You might expect a third option between fat and lean: a binary with *only your locales* inside and no runtime files. ICU4X can build one, and we measured it. The result is not worth shipping: much of the data (segmentation dictionaries, Unicode property tables) is the same for every locale, so a one-locale binary still lands near 8–10 MB, and the mechanism is incompatible with the experimental formatters, which would quietly disappear from such a build. A lean binary plus postcards gives the same outcome (small footprint, only your locales, works offline) with every facade intact. The full measurements are in [`docs/CAPABILITY_ROADMAP.md`](docs/CAPABILITY_ROADMAP.md).

</details>

### Custom data sources

<details>
<summary><b>🧰 CDN, single blob, tiered fallback</b></summary>

<br>

`IcuDataSource.assets` is the easy path. For more control:

```dart
// Fetch postcards from your CDN
IcuDataSource.callback((locale) async {
  final res = await http.get(Uri.parse('https://cdn.example.com/$locale.postcard'));
  return res.bodyBytes.buffer;
});

// One blob covering multiple locales
final blob = await rootBundle.load('assets/icu/app_data.postcard');
IcuDataSource.bytes(blob.buffer);

// Tiered fallback: try local cache first, then network
IcuData.composite([
  IcuData.lazy(IcuDataSource.assets(load: rootBundle.load)),
  IcuData.lazy(IcuDataSource.callback(httpFetcher)),
]);
```

</details>

---

## Platform support

Same public API on every platform. Conditional imports decide the underlying mechanism at compile time.

| Platform | Backend | Status |
|---|---|:---:|
| iOS | `dart:ffi` → `libicu_capi.dylib` | ✓ |
| Android | `dart:ffi` → `libicu_capi.so` | ✓ |
| macOS | `dart:ffi` → `libicu_capi.dylib` | ✓ |
| Linux | `dart:ffi` → `libicu_capi.so` | ✓ |
| Windows | `dart:ffi` → `icu_capi.dll` | ✓ |
| Web | `dart:js_interop` → `icu_capi.wasm` | ✓ |

### Which browsers?

Every modern browser. The web backend is a WebAssembly module (`wasm32`) loaded through `dart:js_interop` — no threads, no SharedArrayBuffer, no cross-origin-isolation headers required. Chrome, Firefox, Safari, and Edge have all shipped the needed WASM + BigInt support for years. The engine is single-threaded, so it works the same whether or not the page is cross-origin isolated.

---

## Choosing icu_kit (and when not to)

icu_kit is built on ICU4X — the Unicode Consortium's modern Rust implementation of ICU, written by contributors from Google, Mozilla, Amazon, and others. 2.0 stable shipped May 2025; icu_kit tracks the 2.x line.

On capabilities, icu_kit is a superset of the Dart alternatives: everything they format, it formats, on the same engine. What they genuinely offer is on other axes — zero bundle bytes, official backing, a lighter job. The questions you're probably asking:

**"I already use `package:intl`."** Keep it — for what it's for. Message translation (ARB catalogs, `Intl.message`) is a different job, and icu_kit doesn't do it; the two run side by side. For *formatting*, `intl` covers common numbers and dates, and the moment you need more — currency long names, time zones, non-Gregorian calendars, non-Latin numbering, segmentation, locale-aware casing, normalization, bidi — that's what icu_kit is for.

**"On web, `Intl.*` is free."** True, and zero bytes is hard to argue with (it also has `formatToParts`, which ICU4X doesn't expose yet). The costs: it's web-only, and its output changes with each user's browser engine and that engine's CLDR version. Reach for icu_kit when you also ship native, or when "the same input formats the same everywhere" matters.

**"Isn't [`intl4x`](https://pub.dev/packages/intl4x) the official one?"** Yes — the Dart team's package, currently experimental. It runs ICU4X on native but delegates to the browser's `Intl` on web, so the same value can format differently on native and web. Every capability it has exists in icu_kit too; icu_kit adds the rest of the Unicode surface, identical output on every platform including web, and the lean-binary data dial. What intl4x offers instead: official backing, and a smaller web bundle (no engine shipped).

**"Why not the raw [`icu4x`](https://pub.dev/packages/icu4x) bindings?"** That's Unicode's own package, published straight from the ICU4X repo — same engine, official packaging. What it ships is the machine-generated API with no facade layer (`DateTimeLength.Medium`, `Locale.fromString`), no web support yet, and one binary shape: a prebuilt library with all CLDR data baked in, which its README puts at about 15 MB added to your app on most platforms (tree-shaking of unused APIs currently needs a dev-channel Dart flag, Linux only). The right pick if you want the official artifact and will build your own ergonomics on top — intl4x does exactly that. icu_kit is that layer, already built: typed facades, loud data errors, web via WebAssembly, the lean-binary data dial, docs.

**"What about ICU4C?"** The C++ classic — reasonable on servers where it's already installed. It's ~30 MB with data and doesn't compile cleanly to WebAssembly; ICU4X was designed for the client-side world icu_kit lives in.

And if your app ships one language and formats nothing, use string constants — don't pay ~19 MB of CLDR for data you never read.

---

## Docs

The README covers the everyday stuff. wanna go deeper?

| Doc | What's inside |
|---|---|
| [Architecture](docs/ARCHITECTURE.md) | How it's built: the five layers, the dispatch seam, the vendored fork, the test harness |
| [Capabilities](docs/CAPABILITY_ROADMAP.md) | What's shipped, what's experimental, what won't happen |
| [Updating](docs/UPDATING.md) | The fork contract, patch markers, and every maintenance recipe |
| [Contributing](CONTRIBUTING.md) | Setup, PR workflow, the `make check` gate |

---

## License

MIT — see [LICENSE](LICENSE). Free for commercial use. If you're building a normal app, there is nothing to do here.

<details>
<summary><b>🧩 what about the Unicode data inside the binary?</b></summary>

<br>

The binary carries CLDR locale data from ICU4X, licensed under the Unicode License v3 — also permissive, also free for commercial use. Its one condition: Unicode's copyright notice travels with copies. That happens on its own — the notice is included in this package's `LICENSE`, and Flutter bundles every dependency's `LICENSE` into your app's licenses page at build time. You'd only handle it yourself when shipping the binary outside a Flutter app (a bare `dart compile` executable, or an SDK of your own): include the notice from `LICENSE` with your distribution, done.

</details>
