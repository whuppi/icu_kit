# Contributing

Contributions are welcome.

---

## Setup

```bash
git clone --recursive https://github.com/whuppi/icu_kit.git
cd icu_kit
make hooks               # activates commit-msg + pre-commit (run once)
fvm install              # downloads the SDK version pinned in .fvmrc
fvm dart pub get
fvm dart test            # build hook compiles icu_capi from source automatically
```

**Requires:** [Rust](https://rustup.rs), [FVM](https://fvm.app)
(`.fvmrc` pins the exact SDK version). The build hook detects
`vendor/icu4x` and runs `cargo build` — no manual compilation step.

**Without FVM:** all Makefile commands accept `DART` and `FLUTTER`
overrides:

```bash
make check DART=dart FLUTTER=flutter
```

For web development:

```bash
make build-wasm              # nightly Rust + wasm-opt → web_assets/icu4x.wasm
```

---

## Before submitting a PR

```bash
make check
```

Runs `lint-shell` + `analyze` (format + Dart + Rust warnings in our
patched lines) + `analyze-floor` + `platforms` (the pana six-platform
gate) + `test` (the VM suite) + `test-web` (the same suites in real
Chrome). Must pass. Don't suppress with
`// ignore:` — fix the underlying issue (`make analyze` fails on any
ignore comment outside generated `.g.dart` files).

---

## PR workflow

All PRs target `dev`. That's the only branch contributors touch.

```
your fork / feature branch ──PR──► dev
                                    ↓ CI: the make targets above
                                    ↓ PR title: Conventional Commits (feat: / fix: / etc.)
                                    ↓ squash-merge when green
                                    ↓ Full test suite via "ready-to-test" label
```

CI calls Makefile targets via the `make-target` orchestrator action.
Same commands locally and in CI.

You don't write changelog entries, bump versions, or touch `prod`.
The maintainer handles releases.

---

## Code style

- Match existing code in the repo.
- The public barrel stays platform-blind: native code behind `dart:ffi`
  conditional exports, web behind `dart:js_interop` — `make platforms`
  fails if pub.dev would drop a platform.
- Generated code is never hand-edited. `lib/src/ffi/bindings/` comes
  from Diplomat via `make regen-bindings`; fixes belong in the
  generator post-step in `tool/regen_bindings.dart`.
- Corpus tests assert against UCD/CLDR data files as declared truth —
  never against the package's own output re-derived.

---

## The vendored fork

One git submodule at `vendor/icu4x` — a fork of
[unicode-org/icu4x](https://github.com/unicode-org/icu4x) carrying
icu_kit's patches. Provenance, the fork contract, and recipes live in
[`docs/UPDATING.md`](docs/UPDATING.md).

**PRs to the fork** ([`whuppi/icu4x`](https://github.com/whuppi/icu4x)):
target the patches branch — never `main`, which is a clean mirror of
upstream. The current patch-branch name is listed in
[`docs/UPDATING.md`](docs/UPDATING.md).

After editing Rust in `vendor/icu4x`: wrap the change in
`── icu_kit patch ──` markers, run `make regen-bindings` if the capi
surface changed, then commit AND push the submodule before opening a PR.

---

## Releases

Handled by the maintainer. Details in [`docs/UPDATING.md`](docs/UPDATING.md).
