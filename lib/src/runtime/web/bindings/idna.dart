// Mirror of the native `IdnaProcessor` + `IdnaError` bindings over the
// Diplomat JS `IdnaProcessor` class. The native binding throws a plain
// `IdnaError` enum value on failure; Diplomat-JS instead throws a JS
// `Error` whose `.cause.value` string names the Rust variant. This mirror
// decodes that JS shape internally and re-throws the SAME `IdnaError`
// enum defined here (matching the native enum's value names exactly),
// so the shared facade's `on IdnaError catch (e)` + switch works
// unchanged on both platforms.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `IdnaProcessor`.
extension type IdnaProcessor._(JSObject _self) implements JSObject {
  /// Construct via the JS bare constructor (no data-provider variant).
  factory IdnaProcessor() {
    final cls = IcuKit.module.getProperty<JSFunction>('IdnaProcessor'.toJS);
    return IdnaProcessor._(cls.callAsConstructor<JSObject>());
  }

  /// Punycode-encode [domain] (UTS #46 ToASCII, lenient).
  String toAscii(String domain) => _call('toAscii', domain);

  /// Punycode-encode [domain] enforcing STD3 ASCII rules.
  String toAsciiStrict(String domain) => _call('toAsciiStrict', domain);

  /// Punycode-encode [domain] with full UTS #46 transitional checks.
  String toAsciiUts46(String domain) => _call('toAsciiUts46', domain);

  /// Decode a Punycode [domain] back to Unicode (lenient).
  String toUnicode(String domain) => _call('toUnicode', domain);

  /// Decode a Punycode [domain] with full UTS #46 checks.
  String toUnicodeUts46(String domain) => _call('toUnicodeUts46', domain);

  String _call(String operation, String domain) {
    try {
      return _self.callMethod<JSString>(operation.toJS, domain.toJS).toDart;
    } catch (raw) {
      throw _decodeError(raw);
    }
  }
}

/// Web mirror of the FFI `IdnaError` enum — same value names as the
/// native binding so `on IdnaError catch (e)` works verbatim on both
/// platforms.
enum IdnaError {
  /// Failure that maps to no specific variant.
  unknown,

  /// Input is not valid UTF-8.
  invalidUtf8,

  /// Input violates IDNA validity rules.
  invalid,
}

IdnaError _decodeError(Object raw) {
  try {
    final jsErr = raw as JSObject;
    final cause = jsErr.getProperty<JSObject?>('cause'.toJS);
    if (cause == null) return IdnaError.unknown;
    final value = cause.getProperty<JSString?>('value'.toJS);
    if (value == null) return IdnaError.unknown;
    return switch (value.toDart) {
      'InvalidUtf8' => IdnaError.invalidUtf8,
      'Invalid' => IdnaError.invalid,
      _ => IdnaError.unknown,
    };
  } catch (_) {
    return IdnaError.unknown;
  }
}
