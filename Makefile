.PHONY: check hooks analyze analyze-floor platforms lint-shell format \
        test test-lean test-web test-web-lean test-guards \
        postcards-example-lean test-example-lean-matrix verify-web-lean \
        build-wasm build-wasm-lean regen-bindings clean \
        test-example test-example-matrix test-example-macos test-example-device \
        test-example-android test-example-ios test-example-linux \
        test-example-windows test-example-web \
        verify-android verify-ios verify-macos verify-linux \
        verify-windows verify-web verify-readme-sizes \
        compile-macos compile-ios compile-android compile-linux \
        compile-windows compile-wasm compile-natives

# ═══════════════════════════════════════════════════════════════════
# SDK resolution
#
# Uses fvm by default (.fvmrc pins the SDK). Contributors without fvm
# can override: make check DART=dart
# icu_kit is pure Dart — no Flutter dependency anywhere in the gate.
# ═══════════════════════════════════════════════════════════════════

DART    ?= fvm dart
FLUTTER ?= fvm flutter
CARGO   ?= cargo
TEST_RESULTS_DIR ?= test-results
TIMEOUT := $(if $(CI),--timeout=30x,)
VERBOSE := $(if $(CI),--verbose,)

# ═══════════════════════════════════════════════════════════════════
# § 1 — Gate
# ═══════════════════════════════════════════════════════════════════
#
# make check    Full local gate before PR.

check: lint-shell analyze analyze-floor platforms test-guards test test-lean \
       test-web test-web-lean test-example-matrix

# make hooks    Activate the repo's git hooks (commit-msg, pre-commit).
#               Run once after cloning — they stay dormant otherwise.
#               Idempotent.
hooks:
	@git config core.hooksPath .githooks
	@echo "✓ git hooks active (core.hooksPath → .githooks)"

# ═══════════════════════════════════════════════════════════════════
# § 2 — Analyze
# ═══════════════════════════════════════════════════════════════════
#
# make analyze  Dart format + shared Dart core (stamped from whuppi/ci)
#               + Rust warnings in our patched lines (both native
#               feature configs). Needs the Rust toolchain — the same
#               requirement the build hook already imposes.

analyze:
	@DART="$(DART)" FLUTTER="$(FLUTTER)" bash tool/analyze.sh

# make analyze-floor  Resolve to the OLDEST in-range dependencies and analyze
#                     the shipped code (lib bin hook). The wide lower bounds
#                     are only honest if the code analyzes against them, not
#                     just the newest a fresh build resolves. Static analysis
#                     only — no native build. Tests are excluded on purpose;
#                     a consumer sees lib, never your tests. Snapshots and
#                     restores the lock so a local run leaves the tree clean.
analyze-floor:
	@cp pubspec.lock pubspec.lock.floorbak; \
	$(DART) pub downgrade >/dev/null && $(DART) analyze --fatal-infos lib bin hook; rc=$$?; \
	mv pubspec.lock.floorbak pubspec.lock; \
	$(DART) pub get >/dev/null 2>&1 || true; \
	exit $$rc

# make platforms  Gate pub.dev platform support: pana (the exact analyzer
#                 pub.dev runs, pinned + radar-tracked) must still report all
#                 6 platforms, else a regression like an unconditional
#                 dart:io/dart:ffi import in the wrong layer silently drops
#                 web. Shared gate tool/platforms_gate.sh (canonical in
#                 whuppi/ci, stamped into tool/); PANA_VERSION comes from
#                 this repo's tool/versions.env.
platforms:
	@DART="$(DART)" EXPECTED_PLATFORMS="android ios linux macos windows web" bash tool/platforms_gate.sh

# make lint-shell  Shell portability gate: shellcheck + a bash 4.0+ scan
#                  that catches macOS bash 3.2 breaks in scripts and in
#                  workflow run: blocks. Stamped from whuppi/ci.
lint-shell:
	@bash tool/lint_shell.sh

# make format   Format in place (analyze also formats; this is the
#               standalone entry). The example and its test_support
#               harness are separate packages — format each from its own
#               root so `dart format` reads its own resolution.
format:
	@$(DART) format lib bin test tool hook
	@[ -d example ] && ( cd example && $(DART) format lib test integration_test test_driver ) || true
	@[ -d example/test_support ] && ( cd example/test_support && $(DART) format lib ) || true

# ═══════════════════════════════════════════════════════════════════
# § 3 — Test
# ═══════════════════════════════════════════════════════════════════
#
# make test     The full VM suite. The build hook compiles icu_capi from
#               vendor/icu4x on first run (needs the Rust toolchain);
#               incremental cargo caches make later runs fast.

test:
	@echo "=== VM suite (build hook compiles icu_capi on first run) ==="
	@mkdir -p $(TEST_RESULTS_DIR)
	@$(DART) test $(TIMEOUT) --file-reporter json:$(TEST_RESULTS_DIR)/vm.json

# make test-lean  The LEAN binary end to end: test_fixtures/lean_smoke/ is its own
#                 hooks root whose pubspec flips bundleCldrData off, so the
#                 hook builds icu_capi WITHOUT compiled data — proving the
#                 flavor probe detects it, init fails actionably without
#                 lazy data, and postcards carry real formatting. The one
#                 flavor the main suite (always fat) can never exercise.

test-lean:
	@echo "=== Lean-binary suite (hook builds the no-CLDR flavor) ==="
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd test_fixtures/lean_smoke && $(DART) test $(TIMEOUT) --file-reporter json:../../$(TEST_RESULTS_DIR)/lean.json

# make test-guards  Mechanical suite rules. Every suite here runs on BOTH
#                   the VM and Chrome, so a VM-only import in a shared suite
#                   breaks the browser world silently at load time. dart:io /
#                   dart:ffi are allowed only in the conditional-import
#                   corpus loader's VM side (corpus_loader_io.dart) or files that declare
#                   @TestOn('vm').
test-guards:
	@bad=""; \
	for f in $$(grep -rlnE "import 'dart:(io|ffi)'" test/ --include="*.dart"); do \
	  case "$$f" in test/_corpus/corpus_loader_io.dart) continue ;; esac; \
	  grep -q "@TestOn('vm')" "$$f" || bad="$$bad$$f\n"; \
	done; \
	if [ -n "$$bad" ]; then \
	  echo "VM-only import in a two-world suite (add @TestOn('vm') or move"; \
	  echo "the IO behind the conditional-import loader):"; \
	  printf "$$bad"; exit 1; fi
	@bad=$$(grep -rlnE "import '(package:web/|dart:js_interop)" test/ --include="*.dart" \
	  | grep -v "^test/_corpus/corpus_loader_web.dart" || true); \
	if [ -n "$$bad" ]; then \
	  echo "browser-only import outside the web corpus loader — every other"; \
	  echo "suite must compile on the VM:"; \
	  echo "$$bad"; exit 1; fi
	@echo "✓ test guards clean"

# make test-web  The same suites in real Chrome (dart test -p chrome).
#                Needs web_assets/icu4x.wasm — build once via make build-wasm
#                (gitignored artifact; CI provisions it via the wasm-cache /
#                wasm-build capabilities).
test-web:
	@echo "=== Chrome suite (dart test -p chrome) ==="
	@test -f web_assets/icu4x.wasm || { echo "web_assets/icu4x.wasm missing — run: make build-wasm"; exit 1; }
	@mkdir -p $(TEST_RESULTS_DIR)
	@$(DART) test -p chrome $(TIMEOUT) --file-reporter json:$(TEST_RESULTS_DIR)/web.json

# make test-web-lean  The LEAN WASM end to end in real Chrome — the web
#                     half of what test-lean proves for native. Prepares
#                     test_fixtures/lean_smoke/web_mirror/ (bindings tree + the
#                     lean wasm under the standard icu4x.wasm name — the
#                     exact layout `setup --lean` installs) and runs the
#                     lean_smoke chrome suite against it. Needs
#                     web_assets/icu4x-lean.wasm — built by the
#                     build-wasm-lean dependency when missing.
test-web-lean: build-wasm-lean
	@echo "=== Lean-WASM Chrome suite ==="
	@rm -rf test_fixtures/lean_smoke/web_mirror
	@mkdir -p test_fixtures/lean_smoke/web_mirror
	@cp web_assets/diplomat.config.mjs test_fixtures/lean_smoke/web_mirror/
	@cp -R web_assets/lib test_fixtures/lean_smoke/web_mirror/lib
	@cp web_assets/icu4x-lean.wasm test_fixtures/lean_smoke/web_mirror/icu4x.wasm
	@cp test/_corpus/postcards/en_minimal.postcard test_fixtures/lean_smoke/web_mirror/
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd test_fixtures/lean_smoke && $(DART) test -p chrome $(TIMEOUT) --file-reporter json:../../$(TEST_RESULTS_DIR)/web-lean.json

# ═══════════════════════════════════════════════════════════════════
# § 3b — Example app (journeys + integration smoke + release verify)
# ═══════════════════════════════════════════════════════════════════
#
# make test-example         Host-VM journeys + the macOS integration smoke.
# make test-example-matrix  Host-VM journeys: the four tabs driven end to
#                           end through the real engine, across every
#                           device profile. No device needed. In `check`.
# make test-example-macos   Integration smoke on macOS (real library).
# make test-example-device  Integration smoke on DEVICE=<id>.
# make test-example-<plat>  Integration smoke on one real target — CI's
#                           full-test runs each (android/ios/linux/windows/web).
# make verify-<plat>        Release build of the example — proves the build
#                           hook links for that target (incl. Android's
#                           16 KB page size).
#
# The example builds icu_capi from vendor/icu4x for its OWN build output on
# first run (needs the Rust toolchain), separate from the package's cache.

DEVICE ?=

test-example: test-example-matrix test-example-macos

test-example-matrix:
	@echo "=== Example journeys (host VM, real engine, every device) ==="
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd example && $(FLUTTER) test $(VERBOSE) $(TIMEOUT) test/journeys --file-reporter json:../$(TEST_RESULTS_DIR)/example-matrix.json

test-example-macos:
	@cd example && $(FLUTTER) test $(TIMEOUT) integration_test/icu_kit_smoke_test.dart -d macos

test-example-device:
	@cd example && $(FLUTTER) test $(TIMEOUT) integration_test/icu_kit_smoke_test.dart -d $(DEVICE)

test-example-android:
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd example && $(FLUTTER) test $(VERBOSE) $(TIMEOUT) integration_test/icu_kit_smoke_test.dart --file-reporter json:../$(TEST_RESULTS_DIR)/int-android.json

test-example-ios:
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd example && $(FLUTTER) test $(VERBOSE) $(TIMEOUT) integration_test/icu_kit_smoke_test.dart --file-reporter json:../$(TEST_RESULTS_DIR)/int-ios.json

test-example-linux:
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd example && $(FLUTTER) test $(VERBOSE) $(TIMEOUT) integration_test/icu_kit_smoke_test.dart -d linux --file-reporter json:../$(TEST_RESULTS_DIR)/int-linux.json

test-example-windows:
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd example && $(FLUTTER) test $(VERBOSE) $(TIMEOUT) integration_test/icu_kit_smoke_test.dart -d windows --file-reporter json:../$(TEST_RESULTS_DIR)/int-windows.json

# Web needs the WASM + JS bindings copied into example/web via the
# consumer setup executable; build-wasm produces the artifact first.
test-example-web: build-wasm
	@cd example && $(FLUTTER) pub get && $(FLUTTER) pub run icu_kit:setup --force web
	@cd example && $(FLUTTER) drive \
		--driver=test_driver/integration_test.dart \
		--target=integration_test/icu_kit_smoke_test.dart \
		-d chrome --browser-name=chrome --headless

# ── Verify: release builds of the example ──
verify-android:
	@cd example && $(FLUTTER) build apk --release

verify-ios:
	@cd example && $(FLUTTER) build ios --release --no-codesign

verify-macos:
	@cd example && $(FLUTTER) build macos --release

verify-linux:
	@cd example && $(FLUTTER) build linux --release

verify-windows:
	@cd example && $(FLUTTER) build windows --release

verify-web: build-wasm
	@cd example && $(FLUTTER) pub get && $(FLUTTER) pub run icu_kit:setup --force web
	@cd example && $(FLUTTER) build web --release

# ═══════════════════════════════════════════════════════════════════
# § 3c — Lean example (example_lean/ — the app under the LEAN binary)
# ═══════════════════════════════════════════════════════════════════
#
# example_lean/ is a build-config shell: its pubspec flips bundleCldrData
# off (so the hook builds the no-CLDR binary) and re-runs example/'s code
# + shared suites. It needs asset postcards to feed the lean binary —
# generated on demand (markers=all is ~7 MB/locale, far too big to
# commit), gitignored. These lanes are CI + on-demand, NOT in the fast
# `check` (slicing every locale is minutes of datagen).
#
# make postcards-example-lean  Slice the journey/smoke locale set into
#                              example_lean/assets/icu/.
# make test-example-lean-matrix Host-VM journeys on the LEAN binary —
#                              the preload UX + postcard path proven live.
# make verify-web-lean         The full web consumer story: clean →
#                              setup --lean → build web, with postcards.

# Locale union the journeys + smoke format under. Sliced with the `kit`
# preset (every facade family the showcase exercises: format + text +
# locale), NOT `all` — `kit` drops the non-Gregorian calendars and time
# zones the example never touches.
LEAN_EXAMPLE_LOCALES := und,en,en-US,de,fr,hi,ja,ar,th,sv,tr,zh-Hant

postcards-example-lean:
	@echo "=== Slicing postcards for example_lean (markers=kit) ==="
	@cd example_lean && $(DART) run icu_kit:slice \
		--locales=$(LEAN_EXAMPLE_LOCALES) --markers=kit --per-locale --out=assets/icu

test-example-lean-matrix: postcards-example-lean
	@echo "=== Lean example journeys (host VM, no-CLDR binary + postcards) ==="
	@mkdir -p $(TEST_RESULTS_DIR)
	@cd example_lean && $(FLUTTER) pub get && $(FLUTTER) test $(VERBOSE) $(TIMEOUT) \
		test/journeys --file-reporter json:../$(TEST_RESULTS_DIR)/example-lean-matrix.json

verify-web-lean: build-wasm-lean postcards-example-lean
	@cd example_lean && $(FLUTTER) pub get && $(FLUTTER) pub run icu_kit:setup --lean --force web
	@cd example_lean && $(FLUTTER) build web --release

# Measures the real artifacts (postcards via datagen, wasm raw+gzipped,
# hook-built cdylibs) and fails if any size number in README.md doesn't
# match reality. Slow (datagen runs) — on demand + release checklist,
# not in `check`.
verify-readme-sizes:
	@$(DART) run tool/verify_readme_sizes.dart

# ═══════════════════════════════════════════════════════════════════
# § 4 — Build + Compile (release pipeline — one target per CI job)
# ═══════════════════════════════════════════════════════════════════
#
# make build-wasm      Rebuild web_assets/icu4x.wasm + the JS bindings
#                      (nightly Rust + wasm-opt; see tool/build_wasm.dart).
# make build-wasm-lean web_assets/icu4x-lean.wasm — the no-CLDR variant
#                      (~2 MB vs ~19 MB). Skips when already built;
#                      delete the artifact to force a rebuild.
# make regen-bindings  Regenerate the Diplomat Dart/JS bindings inside
#                      vendor/icu4x after editing a capi patch.
#
# make compile-macos    macOS arm64 + x64 (bundled + lean variants each).
# make compile-ios      iOS device + simulators (static, nightly).
# make compile-android  Android arm64, arm, x64, x86 (needs the NDK).
# make compile-linux    Linux x64 + arm64 (cross-compile).
# make compile-windows  Windows x64 + arm64 (MSVC).
# make compile-wasm     WASM via tool/build_wasm.dart.
# make compile-natives  All native targets the host can build.
#
# The release workflow runs one compile-* per CI job with
# COMPILE_OUTPUT_DIR=out and uploads out/ as release assets — the
# hash-verified binaries the build hook downloads for consumers.

compile-macos:
	bash tool/compile_rust.sh macos

compile-ios:
	bash tool/compile_rust.sh ios

compile-android:
	bash tool/compile_rust.sh android

compile-linux:
	bash tool/compile_rust.sh linux

compile-windows:
	bash tool/compile_rust.sh windows

compile-wasm:
	bash tool/compile_rust.sh wasm

compile-natives:
	bash tool/compile_rust.sh native

build-wasm:
	@$(DART) run tool/build_wasm.dart

build-wasm-lean:
	@if [ -f web_assets/icu4x-lean.wasm ]; then \
	  echo "web_assets/icu4x-lean.wasm present — skipping (delete it to rebuild)"; \
	else \
	  $(DART) run tool/build_wasm.dart --lean; \
	fi

regen-bindings:
	@$(DART) run tool/regen_bindings.dart

clean:
	@rm -rf .dart_tool web_assets/icu4x.wasm web_assets/icu4x-lean.wasm \
	  test_fixtures/lean_smoke/web_mirror test_fixtures/lean_smoke/.dart_tool $(TEST_RESULTS_DIR)
	@echo "✓ clean (vendor cargo caches left intact — cargo clean inside vendor/icu4x if you really mean it)"
