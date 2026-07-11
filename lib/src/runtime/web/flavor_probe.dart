// Binary-flavor probe, web world — asks the loaded WASM whether it
// carries compiled CLDR data, by checking one compiled-data-gated
// export on the wasm exports object. Ground truth, same contract as
// the native probe (`../native/flavor_probe.dart`).
//
// The Diplomat runtime keeps the instantiated wasm's exports as the
// DEFAULT export of `diplomat-wasm.mjs` (`export default wasm`), a
// sibling of the `index.mjs` the app loads. A missing wasm export is
// plain `undefined` in JS — no exception machinery needed.
//
// Today `tool/build_wasm.dart` always builds with `compiled_data`, so
// this probe returns true for every shipped wasm; it becomes load-
// bearing the day the lean wasm variant ships (see the capability
// roadmap).

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Same gated symbol the native probe resolves — see
/// `../native/flavor_probe.dart` for why this symbol specifically.
const _probeSymbol = 'icu4x_PluralRules_create_cardinal_mv1';

bool? _cached;

/// True when the loaded wasm was built with the `compiled_data`
/// feature. [wasmModuleUrl] is the `diplomat-wasm.mjs` URL, derived
/// from `IcuKit.moduleUrl` by the caller (the sibling of `index.mjs`).
///
/// The sibling module is import-cached by the browser (the Diplomat
/// classes in `index.mjs` already imported it), so this adds no
/// network fetch. Result is cached; the wasm can't change mid-session.
Future<bool> wasmHasCompiledData(String wasmModuleUrl) async {
  return _cached ??= await _probe(wasmModuleUrl);
}

Future<bool> _probe(String wasmModuleUrl) async {
  final ns = await importModule(wasmModuleUrl.toJS).toDart;
  final wasm = ns.getProperty<JSObject?>('default'.toJS);
  if (wasm == null) {
    throw StateError(
      'icu_kit: $wasmModuleUrl has no default export — the installed '
      'web assets are not the shape `flutter pub run icu_kit:setup` '
      'produces. Re-run setup.',
    );
  }
  return !wasm.getProperty<JSAny?>(_probeSymbol.toJS).isUndefinedOrNull;
}
