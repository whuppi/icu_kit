# Updating icu_kit

The procedures for keeping the package in sync with upstream ICU4X. For the architecture context, see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## The vendored fork

One git submodule — a fork of the upstream repo with a named patch branch.

| Crate | Upstream | Fork | Branch | Base tag | Submodule |
|---|---|---|---|---|---|
| icu_capi (in the icu4x workspace) | [`unicode-org/icu4x`](https://github.com/unicode-org/icu4x) | [`whuppi/icu4x`](https://github.com/whuppi/icu4x) | `icu_kit/2.2.0-patches` | `icu@2.2.0` | `vendor/icu4x/` |

### Bumping the fork's base tag — update every place it lives

A base tag lives in more than one spot; change all of them together or they
drift. For icu4x moving to a new upstream `icu@X.Y.Z`:

1. the fork's patch branch — rename to `icu_kit/X.Y.Z-patches`; its name is
   what `make analyze` reads when the submodule is on that branch
2. `build.json` → `baseTag` — the off-branch fallback for the warning-diff.
   CI checks the submodule out detached, so this is the value CI actually
   uses; it MUST equal the branch's version
3. the **Branch** and **Base tag** columns in the table above

### The fork contract

The fork carries exactly three things — anything else is debris and gets
deleted on sight:

| Ref | Why it exists |
|---|---|
| `main` | Clean mirror of upstream main. Synced in §1's mirror step; never carries our commits. |
| The patch branch | All our patches, rebased onto the base tag. The only branch the submodule points at. |
| `icu@*` tags | Rebase bases. `make analyze` derives the base tag from the patch-branch name and diffs against it, so the tag must exist on the fork. |

Debris that does NOT belong on the fork: upstream `release/*` branches,
contributor scratch branches, `zarchive/*`, and upstream's per-crate
`ind/*` + `x/ffi/*` tags (fork-time copies, instantly stale — every such
ref still exists on upstream, so deletion loses nothing).

Never `git push --mirror` the fork: mirror mode deletes every remote ref
that doesn't exist locally, including `main` and any patch branch not
currently checked out.

### Disable Actions on the fork

The vendored fork is consumed as **source** — this repo's own CI
(`make analyze` / `make check` / the test targets) is the gate. The fork's
inherited upstream workflows (Release, language-binding CI, CodeQL, OpenSSF
Scorecard, scheduled scans) validate nothing this repo uses. On the fork, once:

**Settings → Actions → General → "Disable actions for this repository".**

- **Free-tier drain.** Public-repo Actions are free but not unthrottled — a
  fork's heavy Rust/scan pipelines burn org-wide runner allocation and can
  throttle the whole org's hosted runners (every repo's jobs stuck "Waiting for
  a runner"). ICU4X's upstream pipelines are especially heavy.
- **Accidental publish.** §1 pushes the patch branch and an `icu@*` tag to the
  fork on every bump; an upstream `on: push tags` Release pipeline fires on that
  tag and can cut a GitHub release / publish from your mirror. Disabling
  defuses it.
- **Off by default.** The fork is home; upstream is just the base. Routine fork
  work — patches, rebases, tag-moves — never needs the fork's own CI; this
  repo's CI is the gate. The only exception is a deliberate, standalone upstream
  PR (occasional, never during a fix): flip Actions on for that one PR, then
  back off. Off is the resting state.

Disable at the **setting** level — never delete the workflow YAMLs. Deleting
them diverges the mirror from upstream and breaks the clean rebase-on-tag in
§1; the files stay byte-identical to upstream and just never fire.

### The marker discipline

The in-file markers are the authoritative inventory of what we patch —
never maintain a list by hand. Patches live under `ffi/capi/` (the
Diplomat IDL surface) AND, since formatToParts, under `components/` (the
one component patch: `dimension/percent/format.rs` adds `write_to_parts`
so the percent formatter emits typed parts):

```sh
cd vendor/icu4x
grep -rl "icu_kit patch" ffi/capi/ components/
```

- **Hand-edits to existing upstream files** sit between paired
  `// ── icu_kit patch ──` / `// ── end icu_kit patch ──` lines
  (`# ── … ──` in TOML).
- **Entirely-new files** carry one `── icu_kit patch (entire file) ──`
  line in the header instead of pairs.
- **Generated output** (`ffi/dart/`, `ffi/npm/`, the bindings under
  icu_kit's `lib/src/runtime/native/bindings/`) carries no markers — Diplomat is
  the marker; regen commits say so.
- **Patch commits on the branch use the `patch: <description>` message
  convention**, one logical patch per commit, regen output in its own
  `patch: regenerate …` commit.

---

## When to update

| Trigger | Procedure |
|---|---|
| New ICU4X release tag | §1 — Bump submodule + reapply IDL patches |
| Diplomat changes (rare; usually ICU4X release co-release) | §1 — same procedure |
| Local IDL patch needs amending | §2 |
| New corpus fixture available | §3 |
| Rust nightly bump (rare; matches upstream's `build.sh`) | §4 |
| New facade wanted (upstream exposes something we don't wrap yet) | §5 |
| Cutting a release | §6 |

---

## §1 — Bump the ICU4X submodule

1. **Move the submodule to the new tag.**

   ```sh
   cd vendor/icu4x
   git fetch --tags
   git checkout icu@<new-tag>
   ```

2. **Reapply our local IDL patches.**

   The patches live on the `icu_kit/<icu-version>-patches` branch of the submodule. After checking out the new upstream tag, rebase the patch branch on top:

   ```sh
   git checkout icu_kit/<old-icu-version>-patches
   git rebase icu@<new-tag>
   # Resolve any conflicts in ffi/capi/src/{currency,percent,units,relative_time,idna}_formatter.rs,
   # ffi/capi/src/{formatted_parts,decimal}.rs, and components/experimental/src/dimension/percent/format.rs
   git checkout -b icu_kit/<new-icu-version>-patches
   ```

   The submodule should end up on the new patch branch.

3. **Verify the patches still build — with the warning gate.**

   From the package root:

   ```sh
   make analyze
   ```

   The Rust half checks `icu_capi` in BOTH feature configurations
   (bundled CLDR on and off) and fails on any cargo warning inside a
   line we changed vs the base tag. Then run `make test-rust` — the
   patched crate's cargo tests with the hook's native feature set — so
   a mis-resolved rebase conflict fails here, not three layers up in a
   Dart suite. The lean config is the one that
   catches feature-gated import gaps — fix them by cfg-gating the
   import to the config that uses it, never by adding a blanket import
   the other config warns on.

   Before rebasing, check conflict risk with the markers (they ARE the
   list):

   ```sh
   cd vendor/icu4x
   for f in $(grep -rl "icu_kit patch" ffi/capi/ components/); do
     count=$(git diff icu@OLD..icu@NEW -- "$f" | wc -l | tr -d ' ')
     [ "$count" -gt "0" ] && echo "RISK : $f ($count lines)" || echo "clean: $f"
   done
   ```

4. **Regenerate Dart bindings.**

   From the icu_kit package root:

   ```sh
   fvm dart run tool/regen_bindings.dart
   ```

   Output: `lib/src/runtime/native/bindings/*.g.dart` (186 files).

5. **Regenerate JS bindings + WASM.**

   ```sh
   fvm dart run tool/build_wasm.dart
   ```

   Output: `web_assets/icu4x.wasm` + `web_assets/lib/*.{mjs,d.ts}` (~370 files).

6. **Regenerate the dispatch layer.**

   ```sh
   fvm dart run tool/regen_dispatch.dart
   ```

   Output: `lib/src/runtime/native/dispatch.g.dart`, `lib/src/runtime/web/dispatch.g.dart`. If the generator skips a binding pair (`skip <ClassName>.<method>: no compiled-data pair found`), check that both the compiled-data factory AND the WithProvider factory have `#[diplomat::attr(... named_constructor = "...")]` in the IDL.

7. **Regenerate the postcard test fixtures.**

   ```sh
   fvm dart run tool/regen_test_postcards.dart
   ```

   Output: `test/_corpus/postcards/{en,fr,ja}_{minimal,experimental}.postcard`. The fixtures change byte-for-byte across ICU4X bumps; commit them alongside the submodule pin. If a marker renames upstream, the tool fails fast — see §3 for the details.

   **Re-verify the marker presets.** `lib/src/hook/marker_presets.dart` maps `slice`'s `--markers` presets to concrete marker names. It reads the marker universe live from `vendor/icu4x/provider/registry/src/lib.rs`, so new markers in a family are picked up automatically on a bump. But two things still need a human check: (a) `_formatCore` is a list of *exact* marker names kept identical to `tool/regen_test_postcards.dart`'s `stableMarkers` — if a marker in that set renames upstream, update both; (b) `resolveMarkerSpec` throws if any preset matches zero markers, and `test/hook/marker_presets_test.dart` asserts every preset resolves to a registry subset and that `format-core` still equals `stableMarkers` — run it after the bump. A preset that silently narrowed because a prefix stopped matching is the failure those tests guard against.

8. **Run the test suite + analyzer.**

   ```sh
   fvm dart analyze .
   fvm dart test
   ```

   All ~513 native tests + ~460 chrome tests must pass (the exact counts
   grow with new suites — green is the contract, not the number), analyzer
   must be clean.

9. **Verify the size numbers.**

   ```sh
   make verify-readme-sizes
   ```

   Measures the real artifacts (postcards via datagen, wasm raw + gzipped, the hook-built cdylibs) and fails if any size number in `README.md` no longer matches reality — data sizes drift on every CLDR/icu4x bump. Update the README numbers it flags (grep for the old string; prose mentions share the same number as the tables).

10. **Update the version reference.**

    In [`ARCHITECTURE.md`](ARCHITECTURE.md), update the pinned-nightly callout if the upstream `vendor/icu4x/ffi/capi/build.sh` changed it. In [`CAPABILITY_ROADMAP.md`](CAPABILITY_ROADMAP.md) Table 6, update the submodule pin row.

11. **Re-verify upstream licenses.** icu_kit is MIT over vendored
    Unicode-3.0 (ICU4X code + CLDR data). The upstream copyright and
    permission notice is reproduced VERBATIM inside our `LICENSE` (the
    vendor tree is pub-ignored, so the pointer alone would break for pub
    consumers). Diff `vendor/icu4x/LICENSE` across the bump; if the
    notice text changed (new copyright years, new terms), re-copy it into
    our `LICENSE` third-party section.

12. **Rename the branch + sync the fork mirror.**

    ```sh
    cd vendor/icu4x
    git branch -m icu_kit/OLD-patches icu_kit/NEW-patches
    git push origin icu_kit/NEW-patches
    git push origin --delete icu_kit/OLD-patches
    git push origin refs/remotes/upstream/main:refs/heads/main
    git push origin refs/tags/icu@NEW
    ```

    Keeps the fork contract: `main` stays a clean mirror, and the new
    base tag exists on the fork so `make analyze` and future rebases can
    resolve it from a fork-only clone. The `main` push is a fast-forward;
    if it isn't, the mirror drifted — investigate before forcing.

12. **Commit.**

    ```sh
    git add vendor/icu4x lib/src/runtime/ web_assets/ test/_corpus/postcards/
    git commit -m "icu_kit: bump ICU4X to <new-tag>"
    ```

    The submodule pointer change is the load-bearing diff. The regenerated bindings + dispatch + postcards are downstream of it.

---

## §2 — Amend a local IDL patch

When upstream changes the Rust API (renaming a `try_new` → `try_new_v2`) or our patch needs a new method:

1. Edit `vendor/icu4x/ffi/capi/src/<patch>.rs` directly. Diplomat attribute reminder:

   - Compiled-data factory: `#[cfg(feature = "compiled_data")]` + `#[diplomat::attr(all(supports = fallible_constructors, supports = named_constructors), named_constructor = "<dart_name>")]`
   - Provider factory: same attr but with `_with_provider` suffix on the named_constructor; gate with `#[cfg(feature = "buffer_provider")]`; first arg is `provider: &DataProvider`.

2. Verify cargo compiles in BOTH feature configurations (see §1 step 3).

3. Wrap the change in markers (see "The marker discipline" above) and
   commit on the patch branch with the `patch:` convention:

   ```sh
   cd vendor/icu4x
   git add ffi/capi/src/<patch>.rs
   git commit -m "patch: <what>"
   ```

4. Run the regen pipeline (steps 4–7 of §1).

5. Push the submodule branch:

   ```sh
   git push origin icu_kit/<icu-version>-patches
   ```

6. Update the parent commit pointer:

   ```sh
   cd ../..
   git add vendor/icu4x
   git commit -m "icu_kit: amend IDL patch — <what>"
   ```

---

## §3 — Refresh test corpus fixtures

Three corpus sources to refresh independently.

### ICU4X JSON fixtures (plural rules, locale canonicalize, locale expand)

The fixtures under `test/_corpus/icu4x/*.json` are pulled from the ICU4X submodule's `provider/source/data/*` paths. When ICU4X bumps:

```sh
cp vendor/icu4x/provider/source/data/plurals/categories.json \
   test/_corpus/icu4x/plurals_categories.json
cp vendor/icu4x/provider/source/data/locale/canonicalize.json \
   test/_corpus/icu4x/locale_canonicalize.json
cp vendor/icu4x/provider/source/data/locale/maximize.json \
   test/_corpus/icu4x/locale_maximize.json
cp vendor/icu4x/provider/source/data/locale/minimize.json \
   test/_corpus/icu4x/locale_minimize.json
```

### UCD files (bidi, normalizer, properties, segmenter, casing)

Pulled from `https://www.unicode.org/Public/<version>/ucd/`:

```sh
UCD=16.0.0   # match the Unicode version in the new ICU4X release
cd test/_corpus/ucd
curl -O https://www.unicode.org/Public/$UCD/ucd/BidiCharacterTest.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/auxiliary/SentenceBreakTest.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/auxiliary/WordBreakTest.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/auxiliary/GraphemeBreakTest.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/auxiliary/LineBreakTest.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/NormalizationTest.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/CaseFolding.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/SpecialCasing.txt
curl -O https://www.unicode.org/Public/$UCD/ucd/DerivedCoreProperties.txt
```

### ICU4X postcard fixtures (data-layer round-trip + WithProvider arm tests)

The fixtures under `test/_corpus/postcards/` are binary postcards generated by the upstream `icu4x-datagen` Rust tool. They back the `test/data/postcard_round_trip_test.dart`, `test/data/with_provider_arm_test.dart`, and `test/data/with_provider_arm_experimental_test.dart` suites — proving the lazy/postcard data path constructs working facades from real ICU4X bytes.

Regenerate against the new submodule:

```sh
fvm dart run tool/regen_test_postcards.dart
```

The tool wraps `cargo run --manifest-path vendor/icu4x/provider/icu4x-datagen/Cargo.toml` so the postcards stay byte-for-byte reproducible against the vendored ICU4X. It writes both stable (`<locale>_minimal.postcard`) and experimental (`<locale>_experimental.postcard`) sets per locale. The experimental set requires the upstream datagen crate's `unstable` feature, which the tool enables automatically.

If a marker disappears or renames upstream (especially for the experimental facades, which track unstable APIs), the tool fails fast with `Unknown marker "<name>"`. Update the `stableMarkers` / `experimentalMarkers` constants in `tool/regen_test_postcards.dart` to match the new upstream names, then re-run.

Update [`test/_corpus/PROVENANCE.md`](../test/_corpus/PROVENANCE.md) with the new Unicode version + ICU4X tag the fixtures came from.

Run the corpus tests:

```sh
fvm dart test test/_corpus/
```

Every row must pass. If a corpus test fails, the failure mode says which row. Investigate before raising any threshold (corpus tests don't use thresholds — failures are bugs to fix).

---

## §4 — Bump pinned Rust nightly

Nightly is needed for exactly two build shapes — everything else builds on
**stable**:

- **iOS static libs** (`--crate-type=staticlib` + `-Zbuild-std=std,panic_abort` — a nightly-only cargo flag that rebuilds std with panic=abort for a clean staticlib).
- **wasm** (`wasm32-unknown-unknown` is no_std here: `-Zbuild-std=core,alloc` — also nightly-only).

This mirrors upstream's `build.sh` exactly (`([[ $TYPE == static ]] || [[ $NO_STD == 1 ]]) && "+$NIGHTLY"`). The dynamic native builds (macOS / Linux / Windows / Android) use stable — no nightly, no `-Zbuild-std`.

The pin has **one source of truth per world, and they must agree**:

| Source | Drives | Bumped by |
|---|---|---|
| `build.json` → `nightlyToolchain` | our native static build (`hook/build.dart`, `tool/compile_rust.sh`) | us, in this repo |
| upstream `vendor/icu4x/ffi/capi/build.sh` → `PINNED_CI_NIGHTLY` default | wasm (`tool/build_wasm.dart` delegates to `build.sh`; it has NO nightly const of its own) | upstream, arrives with a submodule bump |

`make analyze` fails if the two disagree (`tool/analyze.sh`'s nightly-consistency check) — so a submodule bump that changes upstream's nightly forces a matching `build.json` bump. When that gate fires:

```sh
# Inspect upstream's value (the wasm build uses this)
grep "nightly-" vendor/icu4x/ffi/capi/build.sh

# Match build.json to it (the native-static build uses this)
#   build.json → "nightlyToolchain": "nightly-<date>"
```

Commit:

```sh
git add build.json
git commit -m "icu_kit: bump pinned Rust nightly to <date> (match upstream build.sh)"
```

Test by running a fresh `fvm dart test` — the build hook picks up the new toolchain.

---

## §5 — Add a new facade

1. Verify the upstream Rust ICU4X API exposes the feature (`vendor/icu4x/components/<crate>/src/`).
2. Verify the Diplomat IDL exposes it (`vendor/icu4x/ffi/capi/src/<file>.rs`). If not, add a local IDL patch on the patches branch with `#[cfg(feature = "compiled_data")]` + `#[cfg(feature = "buffer_provider")]` parallel factory ctors and `#[diplomat::attr(... named_constructor = "...")]` attrs so Diplomat emits factories.
3. `fvm dart run tool/regen_bindings.dart` — pull the new factories into the bindings.
4. `cargo run -p diplomat-gen -- js && cp vendor/icu4x/ffi/capi/bindings/js/*.{mjs,d.ts} web_assets/lib/` — JS bindings.
5. Extend `lib/src/runtime/web/bindings/` with mirrors for any binding classes the new facade uses that aren't mirrored yet (see §5b below).
6. Write ONE facade at `lib/src/facade/icu_<name>.dart` — import `../runtime/bindings.dart as icu` + `../runtime/dispatch.dart as dispatch`, call `dispatch.X(localeStr, loc.ffi, ...)`.
7. `fvm dart run tool/regen_dispatch.dart` — the generator scans for your new `dispatch.X(` calls and emits the twin dispatch methods (it only emits the used surface, so this step comes AFTER the facade exists).
8. Export from `lib/icu_kit.dart`.
9. Write `test/facade/<name>_test.dart` — at least 5 behavioral cases.
10. Update Table 1 in [`CAPABILITY_ROADMAP.md`](CAPABILITY_ROADMAP.md).
11. Run `fvm dart analyze . && fvm dart test && fvm dart test -p chrome`. All must pass — analyze checks the facade against the native binding resolution; chrome compiles and runs the web one.

## §5b — mirror maintenance (runtime/web/bindings/)

`lib/src/runtime/web/bindings/` holds hand-written js_interop mirrors of the FFI bindings' Dart-visible signatures — used surface only, one file per binding class. Rules:

- **The native Dart binding is the canonical signature.** Same class name, same factory/method/getter names, same Dart-visible parameter and return types. The Dart↔JS name mapping (a JS `create` prefix on some statics, etc.) lives INSIDE the mirror.
- **Never guess a JS name** — grep the generated JS (`web_assets/lib/<Class>.mjs`) for the `static`/method declaration. `dart analyze` cannot catch a wrong JS-name string; only the chrome suite does, failing at runtime with `_this[method] is not a function`. When you see that error, a mirror's JS name is wrong.
- Opaques are `extension type X._(JSObject _self) implements JSObject` with a `fromDispatch` factory. Binding enums are Dart enums with a `toJs()` doing the module lookup. Structs are extension types whose factory builds the plain JS options object.
- Extension types cannot declare `toString`/`hashCode`/`==` — expose the value under a plain shared name instead (native gets a one-line extension in `runtime/native/extras.dart`, the mirror declares the same member; `Locale.asBcp47` is the precedent).
- **On an icu4x submodule bump:** rerun the regen tools, then run the chrome suite — its failures point at exactly the mirrors whose JS names or shapes changed.

## §5c — browser Intl engine (runtime/web_intl/)

`lib/src/runtime/web_intl/` is the browser Intl engine: a Dart-built module object served off `globalThis.Intl` instead of the WASM module, built by `buildBrowserIntlModule()` and installed at the same `IcuKit.module` seam by `IcuKit.init(webEngine: WebEngine.browserIntl)` (which deferred-loads this directory). One file per facade family (`locale.dart`, `number_format.dart`, …, `datetime.dart`), each overriding throw-all defaults for the classes it can serve. Rules:

- **The web binding + dispatch are the canonical shape.** Every class the browser module registers must match what `lib/src/runtime/web/{bindings,dispatch.g.dart}` reaches via `IcuKit.module.getProperty('X')` — same class name, same static/ctor/method names, same arg order. When the binding calls a static `createYmd(locale, length, …)`, the browser module's `DateFormatter` registers a `createYmd` taking those args in that order.
- **The drift guard is the completeness radar.** `test/browser_engine/contract_guard_test.dart` (VM) derives the full class-name set from the binding source — direct `getProperty('X')` literals plus the two helper indirections (`_fromIntegerValue('X', …)`, `_jsEnum('X', …)`) — and asserts it equals the committed snapshot (`surface_snapshot.g.dart`). The chrome twin asserts the built module resolves every name. **If a binding adds a class the shim doesn't register, the guard fails** — it would otherwise be a silent browser crash (`getProperty` on an unregistered class).
- **On a binding change that adds/renames a module class:** regenerate the snapshot (`fvm dart run tool/browser_engine/gen_surface_snapshot.dart`), update the two hardcoded counts in the guard tests, add the class to `kAllClasses` in `throwing.dart` (so it gets a throw-all default), then either implement it in the matching family file or leave it throw-all (a documented gap). If the binding adds a **new** indirection helper (not `_fromIntegerValue` / `_jsEnum`), extend the extractor's `_helperClassArg` pattern too, or the guard will miss the helper's literals. The extractor + generator live in `tool/browser_engine/` (dart:io tooling); the chrome guards reach the module through `test/browser_engine/module_probe.dart` (conditional loader; its web half is the one browser-only file, registered in the Makefile `test-guards` allowlist).
- **Behavior is verified per family, not by the guard.** The guard only proves every class resolves; the `*_chrome_test.dart` suites prove each family formats correctly and that engine-gap methods raise `IcuUnsupportedError`. A class present only as a throw-all passes the guard yet is behaviorally a gap — the family test is what documents the real coverage.
- **The suite runs on BOTH web compilers.** `make test-browser-engine` runs Chrome under `dart2js` AND `dart2wasm` (`-c chrome:dart2js -c chrome:dart2wasm`). The shim is pure `js_interop`, and a pattern can compile clean yet diverge at runtime between the two compilers (e.g. how a `Symbol` property key marshals). When a family uses a new interop shape, probe it under `dart2wasm` before relying on it — a green `dart2js` run alone proves nothing about the wasm build the package also ships.

## §6 — Cut a release

The release pipeline is `.github/workflows/release.yml` (push + manual dispatch). It owns versions, tags, and publishing: it gates the two changelogs, compiles every release asset (26 native variants + both wasm variants), uploads them, and stamps their hashes into `lib/src/hook/asset_hashes.dart` on the tag. Your only authored input is the changelog entry — the comment block at the top of `CHANGELOG.pre.md` / `CHANGELOG.md` is the standard, including the VERSION SCHEME (0.x stables, per-version `-dev.N` prereleases).

The pipeline has never run end to end — validating it IS the first release. See the launch-blocker row in [`CAPABILITY_ROADMAP.md`](CAPABILITY_ROADMAP.md) Table 4.

### Branch model

The two-lane branch model (`dev` prereleases, `prod` stable) and the
squash-vs-merge-commit rule are the shared model. See
whuppi/ci/docs/ARCHITECTURE.md "The versioned-release model + the
stamping rule".

### The rules

- **NEVER push directly to `dev` or `prod`.** Every change goes through
  a PR. No exceptions.
- **NEVER force-push protected branches** unless syncing prod to dev
  after a divergence (and only with the documented procedure below).
- **NEVER run destructive git commands** (`reset --hard`, `clean -fd`,
  `stash drop`, `gh pr close --delete-branch`) without explicit
  permission.

### The release pipeline

The gate → discover → compile → upload → publish orchestration
(changelog gate, version discovery, the approval-gate pause,
`pub publish`, version-level concurrency, idempotent reruns) is the
shared release engine. See whuppi/ci/docs/ARCHITECTURE.md "The release
surface".

What icu_kit's release adds on top:

- **Native compile matrix** — the compile step checks out the tag and
  builds all 6 target groups in parallel (26 native variants: every
  target × bundled + lean CLDR, plus both wasm variants).
- **Submodule deregistration** — at `--discover` the shared engine
  de-registers the vendored submodule into the stamped tag: gitlink
  dropped, `vendor/icu4x/.git` + `.gitmodules` removed, the vendor
  tree force-added as regular tracked files, and `false_secrets:
  /vendor/icu4x/**` stamped into pubspec for pub's secret scanner
  (mechanism: whuppi/ci `release.sh`, `cmd_discover`). Both the tag
  AND the pub tarball therefore carry raw ICU4X source — a pub.dev
  install can compile from source or run `slice` even if every
  GitHub release asset disappears. Same survivability model as
  pdf_manipulator.
- **Asset hashes into the tag** — after upload, `--update-tag-hashes`
  writes the binary hashes back into the tag, so `git: ref: <tag>`
  users get verified binary downloads.

### Prerelease

```
1. Add ## X.Y.Z-dev.N at top of CHANGELOG.pre.md
2. PR to dev → squash and merge
3. (automatic) gate → discover → compile → upload
4. (manual) approve "publish" environment → pub.dev
```

### Stable release

```
1. Add ## X.Y.Z at top of CHANGELOG.md
2. PR to dev → squash and merge (dev ignores stable changelog — no release triggered)
3. PR from dev → prod → create a merge commit (NOT squash, NOT rebase)
4. (automatic) gate → discover → compile → upload
5. (manual) approve "publish" environment → pub.dev
```

### Manual re-trigger

```sh
# Must use --ref to run on the correct branch
gh workflow run "Release" --repo whuppi/icu_kit --ref dev --field branch=dev
gh workflow run "Release" --repo whuppi/icu_kit --ref prod --field branch=prod
```

`--ref` controls which branch the workflow runs ON. `--field branch`
is the input the script reads. Both must match. Without `--ref`, the
workflow runs on the default branch regardless of the input.

### Delete and recreate a release

When a release needs to be rebuilt (broken binaries, missing assets):

```sh
gh release delete vX.Y.Z --repo whuppi/icu_kit --yes
git push origin --delete refs/tags/vX.Y.Z
gh workflow run "Release" --repo whuppi/icu_kit --ref <branch> --field branch=<branch>
```

### Syncing prod to dev (after divergence)

If prod diverges from dev (e.g. an accidental squash merge on a
promotion PR), force-sync it. Prod normally forbids force-push, so the
procedure is **allow → sync → re-forbid** — steps 1 and 3 are the same
protection-PUT call with only the final `allow_force_pushes` flag
flipped (`true`, then `false`).

```sh
# Step 1 — allow force-push (allow_force_pushes=true):
gh api repos/whuppi/icu_kit/branches/prod/protection -X PUT \
  -F "required_status_checks[strict]=true" \
  -F "required_status_checks[checks][][context]=checks / Conventional Commit" -F "required_status_checks[checks][][app_id]=15368" \
  -F "required_status_checks[checks][][context]=Full Test Gate" -F "required_status_checks[checks][][app_id]=15368" \
  -F "required_status_checks[checks][][context]=CI Gate" -F "required_status_checks[checks][][app_id]=15368" \
  -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
  -F "required_pull_request_reviews[require_code_owner_reviews]=true" \
  -F "required_pull_request_reviews[required_approving_review_count]=2" \
  -F "enforce_admins=false" -F "restrictions=null" -F "allow_force_pushes=true" \
  --silent

# Step 2 — force-sync:
git push origin dev:prod --force-with-lease

# Step 3 — re-forbid: rerun the Step 1 command with allow_force_pushes=false
```

### Failure recovery

| Failure | Fix |
|---|---|
| Compile failed (infra) | Rerun via workflow_dispatch (idempotent) |
| Compile failed (code bug) | Fix on dev via PR, bump prerelease version |
| Upload failed | Rerun — clobber overwrites |
| Publish failed | Rerun — approval gate shows again |
| Tag exists but no Release | Rerun via workflow_dispatch |
| Wrong release notes | Delete release + tag, re-trigger |

---

## Flutter version pinning

`.fvmrc` (root + `example/.fvmrc` + `example_lean/.fvmrc`) is the single
source of truth for the Flutter SDK version. Never hardcode the version
anywhere else.

`upgrade-check.yml` runs daily and splits the work by risk into two
draft PRs. The `pins` job re-hashes the current pins to catch a repoint,
then bumps every pinned version Dependabot can't see (the Flutter SDK,
the binaryen + pana pins in `tool/versions.env`, sha256s recomputed from
the upstream assets) onto `chore/pins`. The `lockfiles` job refreshes
the lockfiles onto `chore/lockfiles`. Review, test, merge each when
ready.

---

## Reading the failure modes

| Failure | First check |
|---|---|
| `Missing vendor/icu4x submodule` | `git submodule update --init` |
| `cargo: command not found` | Install Rust via `rustup` |
| `unknown feature 'buffer_provider'` | Submodule is on a tag that pre-dates the feature. Bump first. |
| `regen_dispatch skipped <Class>.<method>` | Check IDL patch — both factories need `#[diplomat::attr(named_constructor = "...")]` |
| `dart analyze` finds undefined methods after regen | The facade calls a binding name that Diplomat changed. Update the facade. |
| Lean-mode build warns/fails on an import | cfg-gate the import to the feature config that uses it — a blanket import passes one config and warns in the other, which `make analyze` fails. |
| Web tests fail with module-not-found | Re-run `tool/build_wasm.dart` and re-run `bin/setup.dart` from the consumer app. |

---

## Submodule patch inventory

For each ICU4X release we maintain patches on `vendor/icu4x` branch `icu_kit/<icu-version>-patches`. The per-file table (what each patch exposes + its removal trigger) lives in [`ARCHITECTURE.md`](ARCHITECTURE.md) §"Local IDL patches"; the authoritative inventory is the markers themselves: `grep -rl "icu_kit patch" ffi/capi/ components/` inside the vendor.

When a removal trigger fires (each patch file's leading comment cites it), drop the patch and switch to the upstream binding. The dispatch generator picks up the new factories automatically; only the facade may need adjustment for any naming-shape change.


