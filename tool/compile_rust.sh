#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────
# compile_rust.sh — Compile icu_capi for any target.
#
# Usage:
#   ./tool/compile_rust.sh macos        macOS arm64 + x64
#   ./tool/compile_rust.sh ios          iOS device + simulators (static)
#   ./tool/compile_rust.sh linux        Linux x64 + arm64 (cross-compile)
#   ./tool/compile_rust.sh android      Android arm64 + arm + x64 + x86
#   ./tool/compile_rust.sh windows      Windows x64 (+ arm64 on MSVC)
#   ./tool/compile_rust.sh wasm         WASM via tool/build_wasm.dart
#   ./tool/compile_rust.sh native       Auto-detect what this host can build
#   ./tool/compile_rust.sh all          native + wasm
#   ./tool/compile_rust.sh --features   Print feature flags (from build.json)
#
# Every native target is built TWICE — bundled (compiled_data baked in)
# and lean (no CLDR statics; consumers use IcuData.lazy) — into
# per-config output subdirectories whose names ARE the release asset
# keys the build hook downloads by:
#
#   {targetKey}/lib{crate}.{ext}         bundled
#   {targetKey}-lean/lib{crate}.{ext}    lean
#
# The cargo invocation MIRRORS hook/build.dart's compile exactly
# (cargo rustc, panic=abort, codegen-units=1, simple_logger added,
# nightly + -Zbuild-std for static targets) so a downloaded binary and
# a source-compiled one are the same artifact.
#
# CI calls the specific target command. Local dev calls native or all.
#
# Prerequisites:
#   Rust toolchain (rustup manages targets + the pinned nightly itself)
#   WASM: nightly toolchain (build_wasm.dart provisions via upstream build.sh)
#   Android: ANDROID_NDK_HOME set (or the default SDK location)
#   Linux arm64 cross: apt install gcc-aarch64-linux-gnu
#
# Called by:  Makefile (compile-* targets), CI release compile jobs
# Run from:   package root
# ────────────────────────────────────────────────────────────────────
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# Paths + build.json constants (single source of truth)
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(dirname "$SCRIPT_DIR")"
VENDOR="$PKG_ROOT/vendor/icu4x"
MANIFEST="$VENDOR/ffi/capi/Cargo.toml"

json_get() {  # jq path, e.g. '.features.native' — fails loud on a missing key
  command -v jq >/dev/null 2>&1 || { echo "Error: jq not found (needed to read build.json)" >&2; exit 2; }
  jq -er "$1" "$PKG_ROOT/build.json" 2>/dev/null || {
    echo "Error: '$1' not found in $PKG_ROOT/build.json" >&2
    exit 2
  }
}

# shellcheck source=/dev/null  # runtime path; not followed at lint time
source "$SCRIPT_DIR/versions.env"

# Materialize the PINNED binaryen (wasm-opt) into a version-keyed cache and
# print the wasm-opt path. The pinned release is the ONLY wasm-opt source
# (no Flutter-SDK copy, no PATH fallback) so every build optimizes with the
# same hash-verified binary. The cache dir is keyed by BINARYEN_VERSION, so
# a pin bump structurally invalidates the old binary.
# Print a path Dart's Process.run can exec. Git Bash's /c/... form is not a
# real Windows path — CreateProcess can't resolve it — so emit mixed C:/...
# there (bash executes that form fine too).
_native_path() {
  if command -v cygpath &>/dev/null; then cygpath -m "$1"; else printf '%s\n' "$1"; fi
}

_install_binaryen() {
  local exe="" asset sha url tmp
  case "$(uname -s)" in
    MINGW*|MSYS*) exe=".exe" ;;
  esac
  local dest_dir="${ICU_KIT_TOOL_CACHE:-$HOME/.cache/icu_kit}/binaryen/$BINARYEN_VERSION"
  local wasm_opt="$dest_dir/bin/wasm-opt$exe"
  if [ -x "$wasm_opt" ]; then _native_path "$wasm_opt"; return 0; fi

  case "$(uname -s)" in
    Linux*)  asset="binaryen-$BINARYEN_VERSION-x86_64-linux.tar.gz";   sha="$BINARYEN_SHA256_LINUX_X64" ;;
    Darwin*) asset="binaryen-$BINARYEN_VERSION-arm64-macos.tar.gz";    sha="$BINARYEN_SHA256_MACOS_ARM64" ;;
    MINGW*|MSYS*) asset="binaryen-$BINARYEN_VERSION-x86_64-windows.tar.gz"; sha="$BINARYEN_SHA256_WINDOWS_X64" ;;
    *) echo "install binaryen: unsupported host $(uname -s)" >&2; return 1 ;;
  esac
  url="https://github.com/WebAssembly/binaryen/releases/download/$BINARYEN_VERSION/$asset"

  echo "=== WASM: installing binaryen (wasm-opt) $BINARYEN_VERSION ===" >&2
  tmp="${RUNNER_TEMP:-/tmp}"
  # Convert a Windows temp path (D:\...) to Unix (/d/...) so tar doesn't read
  # the colon as a remote host.
  command -v cygpath &>/dev/null && tmp=$(cygpath -u "$tmp")
  bash "$SCRIPT_DIR/fetch_verified.sh" "$url" "$sha" "$tmp/binaryen.tar.gz" >&2 \
    || { echo "install binaryen: failed to fetch/verify $BINARYEN_VERSION" >&2; return 1; }
  tar xzf "$tmp/binaryen.tar.gz" -C "$tmp"
  mkdir -p "$dest_dir/bin" "$dest_dir/lib"
  cp "$tmp/binaryen-$BINARYEN_VERSION/bin/wasm-opt"* "$dest_dir/bin/" \
    || { echo "install binaryen: could not copy wasm-opt to $dest_dir/bin" >&2; return 1; }
  # macOS/Linux builds link libbinaryen from ../lib relative to bin/.
  cp "$tmp/binaryen-$BINARYEN_VERSION/lib/"* "$dest_dir/lib/" 2>/dev/null || true
  rm -rf "$tmp/binaryen.tar.gz" "$tmp/binaryen-$BINARYEN_VERSION"
  [ -x "$wasm_opt" ] || { echo "install binaryen: $wasm_opt missing after extract" >&2; return 1; }
  _native_path "$wasm_opt"
}

CRATE=$(json_get '.crate')
NIGHTLY=$(json_get '.nightlyToolchain')
NATIVE_FEATURES="$(json_get '.features.native'),simple_logger"
LEAN_FEATURES="$(json_get '.features.nativeLean'),simple_logger"

if [ "${1:-}" = "--wasm-opt" ]; then
  _install_binaryen
  exit $?
fi

if [ "${1:-}" = "--features" ]; then
  case "${2:-native}" in
    native)    echo "$NATIVE_FEATURES" ;;
    lean)      echo "$LEAN_FEATURES" ;;
    wasm)      json_get '.features.wasm' ;;
    wasm-lean) json_get '.features.wasmLean' ;;
    *) echo "Usage: $0 --features [native|lean|wasm|wasm-lean]" >&2; exit 1 ;;
  esac
  exit 0
fi

MODE="${1:-}"

# ═══════════════════════════════════════════════════════════════════
# Rust check — hard error if not installed
# ═══════════════════════════════════════════════════════════════════

command -v cargo >/dev/null || {
  echo "ERROR: Rust not installed. https://rustup.rs" >&2
  exit 1
}
[ -f "$MANIFEST" ] || {
  echo "ERROR: vendored ICU4X missing at $VENDOR. Run:" >&2
  echo "  git submodule update --init --recursive" >&2
  exit 1
}

# Keep cargo's scratch inside the vendor tree (gitignored), matching
# the layout `make clean`'s note points at.
export CARGO_TARGET_DIR="$VENDOR/target"

# Ensure a Rust target is installed. Adds it if missing.
# $1 = triple, $2 = optional toolchain
ensure_target() {
  local triple="$1" toolchain="${2:-}"
  local args=(target add "$triple")
  [ -n "$toolchain" ] && args+=(--toolchain "$toolchain")
  # Add the target to the toolchain cargo will actually use. The cdylib
  # build runs inside $VENDOR, where vendor/icu4x/rust-toolchain.toml pins
  # the channel — so add the target there too (rustup honours that file),
  # or the target lands on the default toolchain and cargo builds on the
  # pinned one → "can't find crate for core". The staticlib path passes an
  # explicit --toolchain, which overrides the file regardless of cwd.
  ( cd "$VENDOR" && rustup "${args[@]}" >/dev/null )
}

ensure_nightly() {
  rustup toolchain install --no-self-update "$NIGHTLY" --component rust-src >/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# Native — shared helpers
# ═══════════════════════════════════════════════════════════════════

# Compile one (target, variant) pair and place the library at the
# release-asset layout. Mirrors hook/build.dart's cargo rustc call.
#   $1 = Rust target triple
#   $2 = output subdirectory name (the release asset key)
#   $3 = library filename
#   $4 = crate type: cdylib | staticlib
#   $5 = features
compile_one() {
  local target="$1" outdir="$2" libname="$3" cratetype="$4" features="$5"
  local out="${COMPILE_OUTPUT_DIR:-$PKG_ROOT/build_output}"
  local dest="$out/$outdir/$libname"
  local cargo_cmd=(cargo)

  echo "=== Native: $target → $outdir ==="

  if [ "$cratetype" = "staticlib" ]; then
    ensure_nightly
    ensure_target "$target" "$NIGHTLY"
    cargo_cmd+=("+$NIGHTLY")
  else
    ensure_target "$target"
  fi

  local args=(
    rustc
    --manifest-path ffi/capi/Cargo.toml
    "--crate-type=$cratetype"
    --release
    '--config=profile.release.panic="abort"'
    --config=profile.release.codegen-units=1
    --no-default-features
    "--features=$features"
  )
  if [ "$cratetype" = "staticlib" ]; then
    args+=("-Zbuild-std=std,panic_abort")
  fi
  args+=("--target=$target" -- --emit "link=$dest")

  mkdir -p "$out/$outdir"
  ( cd "$VENDOR" && "${cargo_cmd[@]}" "${args[@]}" )
  echo "  → $dest ($(du -h "$dest" | cut -f1))"
}

# Both variants for one target.
#   $1 = triple, $2 = target key, $3 = libname, $4 = crate type
compile_variants() {
  local target="$1" key="$2" libname="$3" cratetype="$4"
  compile_one "$target" "$key"      "$libname" "$cratetype" "$NATIVE_FEATURES"
  compile_one "$target" "$key-lean" "$libname" "$cratetype" "$LEAN_FEATURES"
}

# Compile one Android target (both variants) using the NDK toolchain.
# The vendored build.rs adds the 16 KB page-size link args itself.
#   $1 = Rust target triple
#   $2 = target key
#   $3 = NDK clang prefix (e.g. "aarch64-linux-android")
compile_android_target() {
  local target="$1" key="$2" ndk_prefix="$3"
  local ndk="${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk}"

  # Resolve the newest NDK when ANDROID_NDK_HOME points at the parent dir.
  # Numeric per-component sort on the "MAJOR.MINOR.BUILD" dir names —
  # version-sort would be simpler but is GNU-only (BSD sort lacks it).
  if [ ! -d "$ndk/toolchains" ]; then
    ndk=$(find "$ndk" -maxdepth 1 -type d -name '[0-9]*' 2>/dev/null \
      | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
  fi
  if [ -z "$ndk" ] || [ ! -d "$ndk" ]; then
    echo "ERROR: Android NDK not found. Set ANDROID_NDK_HOME." >&2
    exit 1
  fi

  local host_tag
  case "$(uname -s)-$(uname -m)" in
    Darwin-*) host_tag="darwin-x86_64" ;;
    Linux-*)  host_tag="linux-x86_64" ;;
    MINGW*|MSYS*) host_tag="windows-x86_64" ;;
    *) echo "ERROR: unsupported NDK host $(uname -s)" >&2; exit 1 ;;
  esac
  local bin="$ndk/toolchains/llvm/prebuilt/$host_tag/bin"
  local clang_ext=""
  case "$(uname -s)" in MINGW*|MSYS*) clang_ext=".cmd" ;; esac

  local env_key
  env_key="CARGO_TARGET_$(echo "$target" | tr '[:lower:]-' '[:upper:]_')"
  export "${env_key}_LINKER=$bin/${ndk_prefix}21-clang$clang_ext"
  export "${env_key}_AR=$bin/llvm-ar"

  compile_variants "$target" "$key" "lib$CRATE.so" "cdylib"

  unset "${env_key}_LINKER" "${env_key}_AR"
}

native_summary() {
  local out="${COMPILE_OUTPUT_DIR:-$PKG_ROOT/build_output}"
  echo ""
  echo "=== Native summary ==="
  find "$out" -type f | sort | while read -r f; do
    echo "  $f ($(du -h "$f" | cut -f1))"
  done
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# Target commands — CI calls these directly
# ═══════════════════════════════════════════════════════════════════

do_macos() {
  compile_variants "aarch64-apple-darwin" "macos-arm64" "lib$CRATE.dylib" "cdylib"
  compile_variants "x86_64-apple-darwin"  "macos-x64"   "lib$CRATE.dylib" "cdylib"
  native_summary
}

do_ios() {
  # iOS's link-mode preference is static; the hook builds staticlibs on
  # the pinned nightly with -Zbuild-std — the release assets must match.
  compile_variants "aarch64-apple-ios"     "ios-arm64"     "lib$CRATE.a" "staticlib"
  compile_variants "aarch64-apple-ios-sim" "ios-sim-arm64" "lib$CRATE.a" "staticlib"
  compile_variants "x86_64-apple-ios"      "ios-sim-x64"   "lib$CRATE.a" "staticlib"

  local out="${COMPILE_OUTPUT_DIR:-$PKG_ROOT/build_output}"
  find "$out" -name "lib$CRATE.a" -exec strip -S {} \; 2>/dev/null || true
  native_summary
}

do_linux() {
  compile_variants "x86_64-unknown-linux-gnu" "linux-x64" "lib$CRATE.so" "cdylib"

  # Cross-compiler for arm64
  if ! command -v aarch64-linux-gnu-gcc >/dev/null; then
    if [ -n "${CI:-}" ]; then
      sudo apt-get update -qq && sudo apt-get install -y -qq gcc-aarch64-linux-gnu
    else
      echo "ERROR: aarch64 cross-compiler missing." >&2
      echo "  Linux: sudo apt-get install -y gcc-aarch64-linux-gnu" >&2
      exit 1
    fi
  fi

  export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="aarch64-linux-gnu-gcc"
  compile_variants "aarch64-unknown-linux-gnu" "linux-arm64" "lib$CRATE.so" "cdylib"
  unset CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER

  native_summary
}

do_android() {
  compile_android_target "aarch64-linux-android"   "android-arm64" "aarch64-linux-android"
  compile_android_target "armv7-linux-androideabi" "android-arm"   "armv7a-linux-androideabi"
  compile_android_target "x86_64-linux-android"    "android-x64"   "x86_64-linux-android"
  compile_android_target "i686-linux-android"      "android-x86"   "i686-linux-android"
  native_summary
}

do_windows() {
  if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
    # MSVC (native Windows) — builds both x64 and arm64
    compile_variants "x86_64-pc-windows-msvc"  "windows-x64"   "$CRATE.dll" "cdylib"
    compile_variants "aarch64-pc-windows-msvc" "windows-arm64" "$CRATE.dll" "cdylib"
  elif command -v x86_64-w64-mingw32-gcc >/dev/null; then
    # MinGW cross-compile from Linux (x64 only)
    compile_variants "x86_64-pc-windows-gnu" "windows-x64" "$CRATE.dll" "cdylib"
  else
    echo "⚠ Windows cross-compile not available on this host"
    return
  fi
  native_summary
}

# ═══════════════════════════════════════════════════════════════════
# Auto-detect — local dev convenience
# ═══════════════════════════════════════════════════════════════════
#
# Builds whatever this host supports. CI never calls this — it uses
# the explicit target commands above.

do_native() {
  if [[ "$(uname)" == "Darwin" ]]; then
    do_macos
    do_ios
  fi

  if [[ "$(uname)" == "Linux" ]]; then
    compile_variants "x86_64-unknown-linux-gnu" "linux-x64" "lib$CRATE.so" "cdylib"
    if command -v aarch64-linux-gnu-gcc >/dev/null; then
      export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="aarch64-linux-gnu-gcc"
      compile_variants "aarch64-unknown-linux-gnu" "linux-arm64" "lib$CRATE.so" "cdylib"
      unset CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER
    fi
  fi

  if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
    do_windows
  fi

  if [ -d "${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk}" ]; then
    do_android
  fi

  native_summary
}

# ═══════════════════════════════════════════════════════════════════
# WASM — delegate to tool/build_wasm.dart (nightly self-provisioning)
# ═══════════════════════════════════════════════════════════════════

do_wasm() {
  # DART is set by the caller (Makefile: `DART = fvm dart`); CI has no bare
  # `dart` on PATH. Require it, no silent fallback — same as the other
  # scripts (analyze.sh, platforms_gate.sh).
  : "${DART:?compile_rust.sh wasm: DART must be set by the caller (e.g. fvm dart)}"

  # Resolve COMPILE_OUTPUT_DIR before anything else — the release
  # pipeline reads it; local builds land in web_assets/ only.
  local release_out="${COMPILE_OUTPUT_DIR:+$(cd "$PKG_ROOT" && mkdir -p "$COMPILE_OUTPUT_DIR/wasm" && cd "$COMPILE_OUTPUT_DIR/wasm" && pwd)}"

  echo "=== WASM (bundled CLDR): tool/build_wasm.dart ==="
  ( cd "$PKG_ROOT" && $DART run tool/build_wasm.dart )

  echo ""
  echo "=== WASM (lean): tool/build_wasm.dart --lean ==="
  ( cd "$PKG_ROOT" && $DART run tool/build_wasm.dart --lean )

  echo ""
  echo "=== WASM summary ==="
  ls -lh "$PKG_ROOT/web_assets/icu4x.wasm" "$PKG_ROOT/web_assets/icu4x-lean.wasm"

  if [ -n "${release_out:-}" ]; then
    cp "$PKG_ROOT/web_assets/icu4x.wasm" "$release_out/"
    cp "$PKG_ROOT/web_assets/icu4x-lean.wasm" "$release_out/"
    echo "Copied to $release_out/"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# Dispatch
# ═══════════════════════════════════════════════════════════════════

case "$MODE" in
  macos)    do_macos ;;
  ios)      do_ios ;;
  linux)    do_linux ;;
  android)  do_android ;;
  windows)  do_windows ;;
  wasm)     do_wasm ;;
  native)   do_native ;;
  all)      do_native; do_wasm ;;
  *)
    echo "Usage: $0 {macos|ios|linux|android|windows|wasm|native|all|--features [native|lean|wasm|wasm-lean]|--wasm-opt}"
    exit 1
    ;;
esac
