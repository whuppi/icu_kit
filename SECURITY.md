# Security Policy

## Reporting a vulnerability

Report privately via [GitHub Security Advisories](https://github.com/whuppi/icu_kit/security/advisories/new). Do not open a public issue.

## What's in scope

- **The vendored fork's patch integrity** — the build hook compiles `icu_capi` from `vendor/icu4x`, a fork of unicode-org/icu4x carrying icu_kit's marker-wrapped patches. A tampered patch branch, a base tag on the fork that no longer matches upstream's, or patch content hidden outside the documented markers is a valid security report.

- **Crafted input causing memory unsafety across the FFI boundary** — Rust's memory safety mitigates this inside the engine, but if malformed text, locale IDs, or CLDR data achieve anything beyond a typed error or a crash through the Dart↔C ABI surface, report it here.

- **The WebAssembly asset** — `web_assets/icu4x.wasm` is built from the same vendored source by `tool/build_wasm.dart`. A wasm binary that doesn't correspond to the vendored source is a supply-chain report.

## What's NOT in scope

- **Crashes or panics from malformed input** — bugs, not vulnerabilities. Report them as [regular issues](https://github.com/whuppi/icu_kit/issues).

- **Network fetching** — the package never makes network requests. CLDR data is either baked into the binary at compile time or loaded from caller-supplied bytes (`IcuData.lazy`).

- **Upstream ICU4X bugs** not introduced by icu_kit's patches — report to [unicode-org/icu4x](https://github.com/unicode-org/icu4x/issues). The patch markers (`── icu_kit patch ──`) delimit exactly what is ours.

## Operational notes (known, accepted)

These are conscious trade-offs, documented so they aren't mistaken for oversights:

- **Consumers compile from source.** The build hook requires the Rust toolchain and compiles the vendored crate locally — there is no prebuilt-binary download path yet, so there is also no binary supply chain to compromise. If prebuilt distribution ships later, hash-verified downloads come with it.

- **`git:`-ref consumers fetch the vendored fork at build time.** Depending on this package by git ref initializes the `vendor/icu4x` submodule from `whuppi/icu4x`. The supply-chain trust is the same as any git dependency.

## Response

Valid reports are fixed and shipped as patch versions.
