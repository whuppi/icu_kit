import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';

/// UTS #46 + RFC 3492 IDNA processor — STABLE.
///
/// Converts internationalized domain names between their Unicode form
/// (e.g. `"日本.jp"`) and their ASCII Punycode form (e.g.
/// `"xn--wgv71a.jp"`). Stateless — construct once, reuse across calls.
///
/// Three modes match the three real-world IDNA use cases:
///
///   * [IcuIdna.url] — WhatWG URL-style permissive defaults (browser
///     behavior). Lenient with edge-case input. **Use for URL parsing.**
///   * [IcuIdna.strict] — strict via `idna::domain_to_ascii_strict`.
///     Rejects empty labels, oversized labels, and hyphen-positional
///     violations. **Use for DNS validation / registrar tooling that
///     prefers a conservative reject-on-any-issue stance.** Note: this
///     mode is MORE conservative than full UTS #46 — it rejects some
///     inputs UTS #46 §4.1 accepts (e.g. trailing root dot `foo.`).
///   * [IcuIdna.uts46] — canonical UTS #46 conformance. Verified
///     against Unicode IdnaTestV2.txt with **zero mismatches at corpus
///     scale** (~12k rows). Uses `Uts46::process(MarkErrors)` so
///     processing always completes per UTS #46 §4.1. **Use for IETF /
///     Unicode conformance contexts.** Like [IcuIdna.strict], this rejects
///     many real-world domains (YouTube CDN nodes, some GitHub user
///     pages) because of _CheckHyphens=true_.
///
/// `toUnicode` matches its construction mode: `url`/`strict` use the
/// lenient `idna::domain_to_unicode`; `uts46` uses
/// `Uts46::to_unicode(STD3, Check)`.
///
/// Example:
///
/// ```dart
/// final url = IcuIdna.url();
/// url.toAscii('日本.jp');                  // "xn--wgv71a.jp"
/// url.toAscii('foo..bar');                  // "foo..bar" (lenient)
///
/// final strict = IcuIdna.strict();
/// strict.toAscii('foo..bar');               // throws IcuIdnaError
///
/// final uts46 = IcuIdna.uts46();
/// uts46.toAscii('日本.jp');                 // "xn--wgv71a.jp"
/// uts46.toAscii('-leadinghyphen.com');      // throws (CheckHyphens)
/// ```
final class IcuIdna {
  IcuIdna._(this._ffi, this._mode);

  /// WhatWG URL-style IDNA (lenient — browser/URL parsing semantics).
  factory IcuIdna.url() => _build(_IdnaMode.url);

  /// Strict IDNA via `idna::domain_to_ascii_strict` (more conservative
  /// than UTS #46; useful as a DNS validator).
  factory IcuIdna.strict() => _build(_IdnaMode.strict);

  /// Canonical UTS #46 / IdnaTestV2 conformance — STD3 + CheckHyphens
  /// + VerifyDNSLength.
  factory IcuIdna.uts46() => _build(_IdnaMode.uts46);
  final icu.IdnaProcessor _ffi;
  final _IdnaMode _mode;

  static IcuIdna _build(_IdnaMode mode) {
    try {
      return IcuIdna._(icu.IdnaProcessor(), mode);
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'IDNA processor unavailable: $e',
        marker: 'IdnaProcessor',
      );
    }
  }

  /// Convert [domain] to its ASCII Punycode form.
  ///
  /// Throws [IcuIdnaError] on UTS #46 / RFC 5891 validation failure or
  /// invalid UTF-8 input.
  String toAscii(String domain) {
    try {
      return switch (_mode) {
        _IdnaMode.url => _ffi.toAscii(domain),
        _IdnaMode.strict => _ffi.toAsciiStrict(domain),
        _IdnaMode.uts46 => _ffi.toAsciiUts46(domain),
      };
    } on icu.IdnaError catch (e) {
      throw IcuIdnaError(_kindFromFfi(e), domain, 'toAscii');
    }
  }

  /// Convert [domain] from its ASCII Punycode form to Unicode.
  ///
  /// Throws [IcuIdnaError] on UTS #46 decoding errors or invalid UTF-8
  /// input.
  String toUnicode(String domain) {
    try {
      return switch (_mode) {
        _IdnaMode.url || _IdnaMode.strict => _ffi.toUnicode(domain),
        _IdnaMode.uts46 => _ffi.toUnicodeUts46(domain),
      };
    } on icu.IdnaError catch (e) {
      throw IcuIdnaError(_kindFromFfi(e), domain, 'toUnicode');
    }
  }
}

enum _IdnaMode { url, strict, uts46 }

IcuIdnaErrorKind _kindFromFfi(icu.IdnaError e) => switch (e) {
  icu.IdnaError.unknown => IcuIdnaErrorKind.unknown,
  icu.IdnaError.invalidUtf8 => IcuIdnaErrorKind.invalidUtf8,
  icu.IdnaError.invalid => IcuIdnaErrorKind.invalid,
};
