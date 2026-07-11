# lean_smoke — the lean-flavor gate

A minimal icu_kit consumer whose `pubspec.yaml` IS the lean switch
(`bundleCldrData: false`). It exists because `user_defines` bind to the
build-root package: icu_kit's own test suite always builds the BUNDLED
binary, so the lean flavor can only be exercised by a separate package
that opts in — this one.

Two suites, one contract each:

| Suite | Runs via | Proves |
|---|---|---|
| `test/lean_smoke_test.dart` | `make test-lean` (VM) | The hook builds the no-CLDR native binary; the flavor probe detects it; `init()` without lazy data throws actionably; postcards carry real formatting; uncovered locales fail loudly. |
| `test/lean_wasm_web_test.dart` | `make test-web-lean` (Chrome) | The same four proofs against the real lean WASM, installed under the standard `icu4x.wasm` name exactly as `setup --lean` installs it (the make target prepares `web_mirror/`). |

Both are in `make check` and run as CI rows.

This package doubles as the smallest READABLE lean consumer: the
pubspec shows the one-line switch, the tests show `IcuData.lazy` +
`preloadLocale` + formatting on a lean binary. For the full app-shaped
story (locale switching with on-demand preload, asset postcards), see
`example_lean/`.
