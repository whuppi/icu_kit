// Conditional-import loader for the browser-engine module introspection the
// two chrome guards need. All js_interop lives in module_probe_web.dart (the
// web half, registered in the Makefile test-guards allowlist alongside
// corpus_loader_web.dart); the VM stub lets the guards COMPILE on the VM (they
// only RUN on chrome, via @TestOn('chrome')). Guard tests import this, never
// dart:js_interop, so every test still compiles on the VM.
library;

export 'module_probe_stub.dart'
    if (dart.library.js_interop) 'module_probe_web.dart';
