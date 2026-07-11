// CHARTER — this suite alone proves the binary-flavor probe's two
// mechanisms on the REAL binary: (a) the compiled-data-gated probe
// symbol resolves on the fat test binary, so `IcuKit.hasCompiledData`
// reports true; (b) resolving a genuinely missing @Native symbol throws
// a CATCHABLE ArgumentError — the exact mechanism the probe uses to
// detect a lean binary. (The true-lean half — probe returning false on
// a real lean binary — is proven in test_fixtures/lean_smoke/, which builds one.)
//
// VM-ONLY: the probe is dart:ffi; the web world has its own probe
// (wasm-export check) exercised by the chrome init path.

// Diet: dart:ffi + the public IcuKit surface.
@TestOn('vm')
library;

import 'dart:ffi' as ffi;

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

// A symbol that exists in NO icu_capi build — proves the miss path of
// the probe's mechanism is a catchable ArgumentError, not a crash.
@ffi.Native<ffi.Pointer<ffi.Void> Function()>(
  symbol: 'icu4x_definitely_not_a_real_symbol_probe_test',
  assetId: 'package:icu_kit/src/runtime/native/bindings/lib.g.dart',
)
external ffi.Pointer<ffi.Void> _missingSymbol();

void main() {
  test('fat test binary is detected as carrying compiled data', () {
    expect(IcuKit.hasCompiledData, isTrue);
  });

  test('detection is stable across reads (cached, no re-probe cost)', () {
    expect(IcuKit.hasCompiledData, IcuKit.hasCompiledData);
  });

  test('missing @Native symbol resolution throws catchable ArgumentError', () {
    expect(
      () =>
          ffi.Native.addressOf<
            ffi.NativeFunction<ffi.Pointer<ffi.Void> Function()>
          >(_missingSymbol),
      throwsArgumentError,
    );
  });
}
