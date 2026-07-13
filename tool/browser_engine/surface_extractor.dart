// VM-only. Derives the set of MODULE CLASSES the browser-engine shim must
// register — every class the web bindings + dispatch reach via
// `IcuKit.module.getProperty('X')`. That is the guard's whole job: every such
// lookup must resolve to a registered class (implemented or a throwing stub).
// Finer-grained correctness (which statics/options/instance methods behave)
// is verified by the family behavior suites, not by parsing source — a
// slot present as a throw-all passes a presence check yet is still
// behaviorally wrong, so slot-presence never proved anything. See the
// advisor rationale recorded in docs/PLAN_BROWSER_INTL.md §4e.
//
// Source is flattened (wrapped lines joined) before matching, because
// dart-format wraps `getProperty(\n  'X'.toJS)` across lines.
//
// The chrome twin never imports this (dart:io); it reads the committed
// snapshot instead. Lives in tool/ (not test/) so the dart:io guard doesn't
// flag it — it's derivation tooling, run by the VM guard + the generator.
library;

import 'dart:io';

const _bindingsDir = 'lib/src/runtime/web/bindings';
const _dispatchFile = 'lib/src/runtime/web/dispatch.g.dart';

// `IcuKit.module.getProperty<T>('X'.toJS)` — the class name X. (`_self`/other
// receivers are instance reads, deliberately excluded.)
final _moduleClass = RegExp(
  r"IcuKit\.module\.getProperty<[^>]+>\(\s*'(\w+)'\.toJS",
);

// Computed indirections: a helper takes the module-class name as a literal
// first arg and resolves it internally via `IcuKit.module.getProperty(arg)`.
// Capture those literals so the resolved class is not missed.
//   * `_fromIntegerValue('X', …)` — property_name.dart (property-value enums).
//   * `_jsEnum('X', …)`           — datetime.dart (DateTimeLength, YearStyle,
//                                   TimePrecision, DateTimeAlignment).
final _helperClassArg = RegExp(r"_(?:fromIntegerValue|jsEnum)\(\s*'(\w+)'");

String _flatten(String src) => src.replaceAll(RegExp(r'\n\s*'), ' ');

/// The module-class name set derived from source under [root] (default: the
/// package root, i.e. `dart test`'s CWD).
Set<String> deriveModuleClasses({String root = '.'}) {
  final names = <String>{};

  void scan(String src) {
    final flat = _flatten(src);
    for (final m in _moduleClass.allMatches(flat)) {
      names.add(m.group(1)!);
    }
    for (final m in _helperClassArg.allMatches(flat)) {
      names.add(m.group(1)!);
    }
  }

  final dir = Directory('$root/$_bindingsDir');
  for (final f in dir.listSync().whereType<File>()) {
    scan(f.readAsStringSync());
  }
  scan(File('$root/$_dispatchFile').readAsStringSync());

  return names;
}
