// Chrome half of module_probe — the ONLY browser-only file the guards reach
// (registered in the Makefile test-guards allowlist alongside
// corpus_loader_web.dart). Keeping every js_interop call here lets the guard
// test files stay VM-compilable. Behavior of the resolved classes is the
// family suites' job; this only introspects the module's shape.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:icu_kit/icu_kit.dart';
// IcuKit.module is web-only; the barrel's IcuKit resolves to native under
// analysis. This chrome-only helper reaches the web class directly (the same
// class at chrome runtime) for module introspection.
import 'package:icu_kit/src/runtime/web/init.dart' as web;
import 'package:icu_kit/src/runtime/web_intl/_util.dart';

bool moduleResolves(String name) =>
    web.IcuKit.module.getProperty<JSAny?>(name.toJS) != null;

bool constructingThrowsUnsupported(String name) {
  final fn = web.IcuKit.module.getProperty<JSFunction>(name.toJS);
  try {
    fn.callAsConstructor<JSObject>();
    return false;
  } on IcuUnsupportedError {
    return true;
  }
}

bool staticThrowsUnsupported(String cls, String staticName) {
  final obj = web.IcuKit.module.getProperty<JSObject>(cls.toJS);
  final fn = obj.getProperty<JSFunction>(staticName.toJS);
  try {
    fn.callAsFunction();
    return false;
  } on IcuUnsupportedError {
    return true;
  }
}

bool ctorClassRoundTrips() {
  final module = JSObject();
  final cls = ctorClass(
    (() {
      final o = JSObject();
      o.setProperty('kind'.toJS, 'instance'.toJS);
      return o;
    }).toJS,
    statics: {'make': (() => 'static-ok'.toJS).toJS},
  );
  put(module, 'X', cls);

  // Dispatch's providerless `new X()` path: getProperty<JSFunction> + ctor.
  final fn = module.getProperty<JSFunction>('X'.toJS);
  final inst = fn.callAsConstructor<JSObject>();
  final kind = inst.getProperty<JSString>('kind'.toJS).toDart;
  if (kind != 'instance') return false;

  // Dispatch's static-factory path on the SAME slot: getProperty + callMethod.
  final obj = module.getProperty<JSObject>('X'.toJS);
  return obj.callMethod<JSString>('make'.toJS).toDart == 'static-ok';
}

bool staticClassRoundTrips() {
  final cls = staticClass({
    'greet': ((JSString who) => 'hi ${who.toDart}'.toJS).toJS,
  });
  return cls.callMethod<JSString>('greet'.toJS, 'de'.toJS).toDart == 'hi de';
}
