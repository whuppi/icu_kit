# Changelog

<!--
═══════════════════════════════════════════════════════════════════════
CHANGELOG STANDARD — read before editing. Applies to both changelogs.
═══════════════════════════════════════════════════════════════════════
Two INDEPENDENT lane changelogs — do NOT mirror one from the other:
  • CHANGELOG.pre.md — the prerelease lane (`## X.Y.Z-dev.N`). Add an
    entry per prerelease you cut on dev.
  • CHANGELOG.md — the stable lane (`## X.Y.Z`). Add an entry per stable
    release, CONSOLIDATING the prerelease entries that ship under it.
They share prose but track their OWN version sequences. There is no
`cp + sed` regen: that mirror falsely assumed every prerelease becomes a
same-numbered stable, so it manufactured stable headings for versions
that never shipped — which the release tooling's `--check-versions` flags.
Hand-edit each lane's file directly.

ADDING A VERSION
  Add a heading at the TOP (newest first) of the right lane's file and
  write the summary. Exactly ONE new (untagged) version may sit at the
  top of each file — every heading BELOW it must already have its git tag
  (or a verified `release: no-tag` HTML-comment directive). `--check-versions`
  enforces this at PR + release time: a second un-released version is
  rejected, since it would collapse into the one release the merge cuts.
  Versions, commit lists, tags, publishing — the release tooling owns all
  of it; you only write the human summary.

ENTRY SHAPE
  ## X.Y.Z-dev.0
  <one-line prose lead — only to frame a big release or signal "no
   behavior change"; omit when the bullets speak for themselves>
  - **Breaking:** <what changed> → <migration step, INLINE>   ← always first
  - <upgrade action>                                          ← any required action next
  - Added/Changed <capability or improvement>                ← then improvements
  - Fixed <bug> ([#N](issue-url) reported by [@user](abs-url), [PR #N](abs-url))  ← fixes last

  Order IS the grouping — Breaking → action → added/changed → fixed. No
  `###` subsections: bullet order carries the categories. Only Breaking
  is bold-tagged; everything else is verb-led. Fixes start with "Fixed".

  EXCEPTION — the genesis entry (a ground-up build, no prior published
  version) uses facet tags instead of deltas: **API:** / **Platforms:** /
  etc., describing the new package's dimensions. See the 0.1.0-dev.0 entry.

CONTENT RULES (never change)
  • Migrate from the entry ALONE — breaking changes inline, old → new.
    (pub.dev freezes each version's CHANGELOG as a snapshot, so an entry
    can't rely on anything that later moves.)
  • NEVER link a living doc (README, docs/*) from an entry — it rots when
    the doc moves on.
  • Links point only at IMMUTABLE targets — a PR, commit, or issue:
    ([#N](https://github.com/whuppi/icu_kit/issues/N) reported by
    [@user](https://github.com/user), [PR #N](https://github.com/whuppi/icu_kit/pull/N)).
    Credit the issue + reporter when a reported issue drove the fix; the PR
    (or commit) link alone otherwise.
  • No capability inventories — "what's shipped" lives in README +
    docs/CAPABILITY_ROADMAP.md; the changelog says only what CHANGED.
  • Engine/submodule bump → web re-fetch action (NEVER miss this). When a
    release bumps the vendored engine submodule (vendor/icu4x), the web
    WASM is rebuilt and consumers must re-fetch it, so ALWAYS add the
    action bullet:
      - Engine updated — web: re-run `flutter pub run icu_kit:setup --force web` (native updates itself)
    Native self-updates via the build hook; only web needs the manual step.
    When cutting a release, diff the submodule pointer against the previous
    tag (`git ls-tree <prev-tag> vendor/icu4x`) so an engine bump never
    ships without the bullet.

VERSION SCHEME (icu_kit)
  The public line is 0.x STABLE releases (0.1.0, 0.2.0, …) — usable and
  pinnable (`^0.N.0`); pre-1.0, breaking changes bump the MINOR. 1.0.0
  ships when the API freezes. Every version — 0.x and beyond — may be
  preceded by -dev.N prereleases: those are the maintainer's testing
  channel (pub's resolver never auto-selects a prerelease), not a line
  for consumers to pin. Until the FIRST tag exists, the single
  0.1.0-dev.0 genesis entry at the top absorbs every change — amend it,
  never add a second version. The stable lane (CHANGELOG.md) gets its
  first entry when 0.1.0 ships, consolidating that version's dev
  entries.
═══════════════════════════════════════════════════════════════════════
-->

<!-- Add new versions below, newest first. -->

## 0.1.0

First release — full ECMA-402 / Unicode internationalization for Dart and Flutter on all six platforms.

- **API:** one Dart API for number, currency, percent, and unit formatting (as strings or typed `formatToParts` parts); plural rules; dates and times across 17 calendars; time zones; relative time; lists; collation; display names; segmentation; case mapping; normalization; bidi; Unicode properties; exemplar characters; and IDNA. No Flutter dependency.
- **Engines:** native via dart:ffi (the build hook compiles icu_capi from the vendored ICU4X source); web via a bundled WebAssembly build of that engine (19 MB, or a 2.1 MB lean variant, 0.6 MB gzipped, via `dart run icu_kit:setup --lean`); or the browser's built-in `Intl` with no ICU4X download (`IcuKit.init(webEngine: WebEngine.browserIntl)`).
- **Data:** CLDR ships bundled, or loads lazily per-locale (`bundleCldrData: false` + `IcuData.lazy`) for a lean binary. `slice` cuts per-locale data by facade family (68 KB to 5.6 MB). One binary serves bundled and lazy data without a flag — see `example_lean/`.
- **Vendoring:** ICU4X 2.2.0 as a fork submodule carrying icu_kit's patches on a named branch.
