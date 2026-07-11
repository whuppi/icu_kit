# icu_kit example — lean binary

The same app as [`../example/`](../example/), run under the **lean**
(no-bundled-CLDR) binary. It is a build-config shell, not a second app:
the only authored code is this package's `pubspec.yaml` and a two-line
`lib/main.dart` that re-runs the real example. All widgets, all journeys,
and all smoke tests come from `../example/` and its `test_support/`
package, so the two flavors cannot drift apart.

## What makes it lean

One line in `pubspec.yaml` — the switch a real consumer flips:

```yaml
hooks:
  user_defines:
    icu_kit:
      bundleCldrData: false
```

`user_defines` bind to the build-root package, so launching from *this*
directory makes the build hook fetch/compile the no-CLDR binary. The app
detects that at runtime (`IcuKit.hasCompiledData`) and loads locale data
from asset postcards on demand — see how `../example/lib/main.dart`
branches the locale-switch handler on the probe.

## Run it

```sh
# from the package root
make postcards-example-lean            # slice the demo locales' postcards
cd example_lean
flutter run                            # native: lean binary + postcards
flutter run -d chrome                  # web: needs `setup --lean` first
```

The postcards are generated (the `kit` preset — every facade family the
showcase exercises; ~91 MB across the demo's 12 locales, most of it in
`und.postcard`, which carries the locale-independent property tables and
segmenter dictionaries), so they are gitignored and sliced by the make
target above rather than committed. Per-preset sizes live in the main
README's "Postcard sizes by preset" table.

## Lanes

- `make test-example-lean-matrix` — the journeys on the lean binary; the
  preload UX and postcard path proven live.
- `make verify-web-lean` — the full web consumer story: clean →
  `setup --lean` → `flutter build web --release`.

For the minimal (non-app) lean proof, see
[`../test_fixtures/lean_smoke/`](../test_fixtures/lean_smoke/).
