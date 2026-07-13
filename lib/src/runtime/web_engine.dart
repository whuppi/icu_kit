/// Which engine icu_kit runs ON WEB. Passed to `IcuKit.init(webEngine: ...)`.
///
/// Native platforms have exactly one engine (`dart:ffi` + ICU4X), so this
/// argument is IGNORED there — a cross-platform app writes one `IcuKit.init`
/// call and native does the right thing regardless of the value.
library;

/// The web engine selector for `IcuKit.init`.
enum WebEngine {
  /// icu_kit's own ICU4X engine, compiled to WebAssembly (the default). Full
  /// coverage, and byte-identical output to native and to every browser.
  /// Requires the one-time `flutter pub run icu_kit:setup` asset install.
  icu4x,

  /// The browser's own built-in `Intl` (its ECMA-402 implementation). Zero
  /// download — the browser supplies the CLDR. Covers the ECMA-402 core; the
  /// surface `Intl` doesn't expose (bidi, IDNA, Unicode properties, exemplar
  /// characters, line segmentation, titlecasing, case folding, calendar
  /// arithmetic) throws `IcuUnsupportedError`. Output varies across browsers
  /// and versions.
  browserIntl,
}
