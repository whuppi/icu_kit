#!/bin/bash
# Run all static analysis: format + the shared Dart core (stamped from
# whuppi/ci) + Rust warnings in our patched lines.
# Called by: make analyze
# Run from package root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(dirname "$SCRIPT_DIR")"

# SDK command — REQUIRED, no fallback. The caller (the Makefile) passes it;
# a missing one fails loud, never guesses. icu_kit is pure Dart: no FLUTTER.
: "${DART:?analyze: DART must be set by the caller, e.g. fvm dart}"
# The stamped core requires FLUTTER even though this gate never touches it
# (the pure-Dart package needs no Flutter SDK). The Flutter `example/` is
# its own package — analyzed and formatted from its OWN root by the
# `analyze-example` / `format` make targets, never folded in here, so its
# `package:flutter/...` imports resolve against its own pubspec.
: "${FLUTTER:?analyze: FLUTTER must be set by the caller, e.g. fvm flutter}"

# ── Resolve BEFORE formatting ───────────────────────────────────────
# `dart format`'s output depends on the file's resolved LANGUAGE VERSION,
# read via .dart_tool/package_config.json. With no package_config the
# formatter falls back to the SDK's latest — a DIFFERENT style than a
# resolved package produces. Resolve first; identical output local + CI.
# The Flutter example (and its nested test_support harness) are separate
# packages — resolve each from its own root so its Flutter deps and
# language version are its own.
echo "=== Dart: pub get ==="
$DART pub get --no-example
[ -d "$PKG_ROOT/example" ] && ( cd "$PKG_ROOT/example" && $FLUTTER pub get )
[ -d "$PKG_ROOT/example/test_support" ] && \
  ( cd "$PKG_ROOT/example/test_support" && $FLUTTER pub get )
[ -d "$PKG_ROOT/test_fixtures/lean_smoke" ] && \
  ( cd "$PKG_ROOT/test_fixtures/lean_smoke" && $DART pub get )
# The lean example is a separate package (its pubspec IS the lean switch);
# resolve from its own root so its Flutter deps + language version are its
# own.
[ -d "$PKG_ROOT/example_lean" ] && \
  ( cd "$PKG_ROOT/example_lean" && $FLUTTER pub get )

# ── Dart formatting ─────────────────────────────────────────────────
# Locally: format in place (the gate fixes what it finds).
# CI: fail on any diff — unformatted code never lands unnoticed.
# The package dirs format from the root; the example and test_support
# format from THEIR own roots (own resolution).
echo "=== Dart: format ==="

# fmt <workdir> <target...> — format from <workdir>, failing on a diff
# under CI. A helper (not an array-of-flags) so an empty flag never trips
# `set -u` on macOS bash 3.2.
fmt() {
  local wd="$1"
  shift
  if [ -n "${CI:-}" ]; then
    ( cd "$wd" && $DART format --set-exit-if-changed "$@" )
  else
    ( cd "$wd" && $DART format "$@" )
  fi
}

ROOT_TARGETS=()
for d in lib bin test tool hook; do
  [ -e "$PKG_ROOT/$d" ] && ROOT_TARGETS+=("$d")
done
fmt "$PKG_ROOT" "${ROOT_TARGETS[@]}"

if [ -d "$PKG_ROOT/example" ]; then
  EX_TARGETS=()
  for d in lib test integration_test test_driver; do
    [ -e "$PKG_ROOT/example/$d" ] && EX_TARGETS+=("$d")
  done
  [ "${#EX_TARGETS[@]}" -gt 0 ] && fmt "$PKG_ROOT/example" "${EX_TARGETS[@]}"
  [ -d "$PKG_ROOT/example/test_support/lib" ] && fmt "$PKG_ROOT/example/test_support" lib
fi
if [ -d "$PKG_ROOT/example_lean" ]; then
  EXL_TARGETS=()
  for d in lib test integration_test test_driver; do
    [ -e "$PKG_ROOT/example_lean/$d" ] && EXL_TARGETS+=("$d")
  done
  [ "${#EXL_TARGETS[@]}" -gt 0 ] && fmt "$PKG_ROOT/example_lean" "${EXL_TARGETS[@]}"
fi
[ -d "$PKG_ROOT/test_fixtures/lean_smoke/test" ] && fmt "$PKG_ROOT/test_fixtures/lean_smoke" test

# ── Shared Dart analysis core (stamped from whuppi/ci) ──────────────
# Suppression-comment ban + dart analyze --fatal-infos over the package
# dirs, plus `flutter analyze` over example/ from its own resolution.
# Canonical script lives in whuppi/ci; a gate change lands here through a
# re-stamp, never an edit to this copy.
ANALYZE_DIRS="lib bin test tool hook" \
  DART="$DART" FLUTTER="$FLUTTER" bash "$SCRIPT_DIR/analyze_core.sh"

# The core's `flutter analyze` covers example/'s own code; the nested
# test_support harness is a separate package, so analyze it directly.
if [ -d "$PKG_ROOT/example/test_support" ]; then
  echo "=== Flutter: analyze example/test_support ==="
  ( cd "$PKG_ROOT/example/test_support" && $FLUTTER analyze --fatal-infos )
fi

# The lean example is a separate package — analyze from its own root so its
# lean-switch pubspec + path deps resolve.
if [ -d "$PKG_ROOT/example_lean" ]; then
  echo "=== Flutter: analyze example_lean ==="
  ( cd "$PKG_ROOT/example_lean" && $FLUTTER analyze --fatal-infos )
fi

# The lean fixture is its own package (its pubspec IS the lean switch).
if [ -d "$PKG_ROOT/test_fixtures/lean_smoke" ]; then
  echo "=== Dart: analyze test_fixtures/lean_smoke ==="
  ( cd "$PKG_ROOT/test_fixtures/lean_smoke" && $DART analyze --fatal-infos )
fi

# ── Facade import wall (unified bindings) ───────────────────────────
# Facades are single-source over the ONE binding seam. A facade that
# imports a platform binding layer directly reintroduces the dual-facade
# split the unified-bindings rewrite removed.
echo "=== Dart: facade import wall ==="
if grep -rnE "runtime/native|runtime/web" "$PKG_ROOT/lib/src/facade/"; then
  echo "FAIL: facades must import only the runtime/ selectors (bindings.dart, dispatch.dart)" >&2
  exit 1
fi
echo "  clean — facades speak only the bindings seam"

# ── Rust analysis (warnings in our patched lines only) ──────────────
# The vendored fork carries icu_kit's patches on a named branch (the
# fork contract in docs/UPDATING.md). This gate fails on any cargo
# warning whose span falls inside a line WE changed vs the upstream
# base tag — upstream's own warnings are upstream's business.
#
# The base tag is derived from the patch-branch name
# (icu_kit/2.2.0-patches → icu@2.2.0); CI checks the submodule out
# detached, so build.json's baseTag is the off-branch fallback. Both
# feature configs the build hook can produce are checked (bundled CLDR
# on and off) — an import used by only one config must be cfg-gated,
# not left to warn in the other.

VENDOR="$PKG_ROOT/vendor/icu4x"
json_get() { python3 -c "import json,sys;print(json.load(open('$PKG_ROOT/build.json'))$1)"; }

# ── Nightly-pin consistency (drift guard) ───────────────────────────
# The native-static build reads build.json's nightlyToolchain; the wasm
# build reads upstream build.sh's PINNED_CI_NIGHTLY (build_wasm.dart
# delegates to it, no const of its own). A submodule bump can change
# upstream's nightly — if build.json isn't bumped to match, native-static
# and wasm would compile with DIFFERENT nightlies. See the nightly-bump
# procedure in docs/UPDATING.md.
BUILDSH="$VENDOR/ffi/capi/build.sh"
if [ -f "$BUILDSH" ]; then
  echo "=== Rust: nightly-pin consistency (build.json vs upstream build.sh) ==="
  json_nightly=$(json_get "['nightlyToolchain']")
  # PINNED_CI_NIGHTLY="${PINNED_CI_NIGHTLY:=nightly-YYYY-MM-DD}"
  upstream_nightly=$(grep -oE 'nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}' "$BUILDSH" | head -1)
  if [ "$json_nightly" != "$upstream_nightly" ]; then
    echo "  MISMATCH: build.json pins '$json_nightly' but"
    echo "            vendor/icu4x/ffi/capi/build.sh pins '$upstream_nightly'."
    echo "  The native-static and wasm builds would use different nightlies."
    echo "  Fix: set build.json nightlyToolchain to '$upstream_nightly'"
    echo "  (see the nightly-bump procedure in docs/UPDATING.md)."
    exit 1
  fi
  echo "  clean — both pin $json_nightly"
fi

NATIVE_FEATURES=$(json_get "['features']['native']")
LEAN_FEATURES=$(json_get "['features']['nativeLean']")

check_rust_warnings() {
  local features="$1"
  cd "$VENDOR"

  local branch base_tag
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ "$branch" == */*-patches ]]; then
    base_tag="icu@$(cut -d/ -f2 <<< "$branch" | sed 's/-patches$//')"
  else
    base_tag=$(json_get "['baseTag']")
  fi

  local diff_file warnings_json
  diff_file=$(mktemp)
  git diff --unified=0 "$base_tag..HEAD" -- ffi/capi/ > "$diff_file" 2>/dev/null || true

  warnings_json=$(mktemp)
  cargo check -p icu_capi --no-default-features --features "$features" \
    --message-format=json 2>/dev/null > "$warnings_json" || true

  python3 - "$diff_file" "$warnings_json" <<'PYEOF'
import json, re, sys

changed = set()
cur = None
with open(sys.argv[1]) as f:
    for line in f:
        if line.startswith('+++ b/'):
            cur = line[6:].strip()
        elif line.startswith('@@') and cur:
            m = re.search(r'\+(\d+)(?:,(\d+))?', line)
            if m:
                start = int(m.group(1))
                count = int(m.group(2) or 1)
                for i in range(start, start + count):
                    changed.add((cur, i))

warns = 0
with open(sys.argv[2]) as f:
    for line in f:
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        if d.get('reason') != 'compiler-message':
            continue
        msg = d.get('message', {})
        if msg.get('level') != 'warning':
            continue
        for sp in msg.get('spans', []):
            if not sp.get('is_primary'):
                continue
            # cargo reports paths relative to the crate dir; ours are
            # repo-relative in the diff. Normalize the ./ segment.
            fn = sp['file_name'].replace('/./', '/')
            if (fn, sp['line_start']) in changed:
                print(f"  {fn}:{sp['line_start']}: {msg.get('message','')}")
                warns += 1
if warns:
    print(f"\n{warns} warning(s) in our changed lines")
    sys.exit(1)
PYEOF
  local rc=$?
  rm -f "$diff_file" "$warnings_json"
  cd "$PKG_ROOT"
  return $rc
}

echo "=== Rust: check icu_capi warnings (native, bundled CLDR) ==="
check_rust_warnings "$NATIVE_FEATURES"

echo "=== Rust: check icu_capi warnings (native, lean) ==="
check_rust_warnings "$LEAN_FEATURES"

echo ""
echo "=== All analysis passed ==="
