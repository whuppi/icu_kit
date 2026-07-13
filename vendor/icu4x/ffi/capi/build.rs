// This file is part of ICU4X. For terms of use, please see the file
// called LICENSE at the top level of the ICU4X source tree
// (online at: https://github.com/unicode-org/icu4x/blob/main/LICENSE ).

use std::env;
use std::path::PathBuf;

/// Inform cargo of the include directories as metadata key value pairs
///
/// Cargo will make the values available to consumers via `DEP_ICU_CAPI_<KEY>`.
/// See <https://doc.rust-lang.org/cargo/reference/build-scripts.html#the-links-manifest-key>
/// for more information.
fn add_bindings_to_cargo_metadata() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let bindings_dir = PathBuf::from(manifest_dir).join("bindings");
    let c_bindings_dir = bindings_dir.join("c");
    let cpp_bindings_dir = bindings_dir.join("cpp");
    let dart_bindings_dir = bindings_dir.join("dart");
    let js_bindings_dir = bindings_dir.join("js");

    println!("cargo::metadata=c_include_dir={}", c_bindings_dir.display());
    println!(
        "cargo::metadata=cpp_include_dir={}",
        cpp_bindings_dir.display()
    );
    println!(
        "cargo::metadata=dart_include_dir={}",
        dart_bindings_dir.display()
    );
    println!(
        "cargo::metadata=js_include_dir={}",
        js_bindings_dir.display()
    );
}

fn main() {
    add_bindings_to_cargo_metadata();

    // ── icu_kit patch ── Android 16 KB page-size alignment (Google Play
    // API 35+). Cargo doesn't inherit the NDK's 16 KB default — emit
    // explicitly, or Play rejects APKs carrying this cdylib.
    let target = env::var("TARGET").unwrap_or_default();
    if target.contains("android") {
        println!("cargo:rustc-link-arg=-Wl,-z,max-page-size=16384");
        println!("cargo:rustc-link-arg=-Wl,-z,common-page-size=16384");
    }
    // ── end icu_kit patch ──
}
