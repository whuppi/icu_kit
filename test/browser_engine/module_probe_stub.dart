// VM stub for module_probe. These functions never run on the VM — the guards
// that call them are @TestOn('chrome') — but the symbols must exist so the
// guards COMPILE on the VM (dart test enumerates + compiles every suite). The
// real implementations are in module_probe_web.dart.
library;

Never _chromeOnly() =>
    throw UnsupportedError('module_probe runs on chrome only');

/// Whether the installed browser-engine module resolves [name].
bool moduleResolves(String name) => _chromeOnly();

/// Whether constructing module class [name] raises IcuUnsupportedError.
bool constructingThrowsUnsupported(String name) => _chromeOnly();

/// Whether calling static [staticName] on module class [cls] raises
/// IcuUnsupportedError.
bool staticThrowsUnsupported(String cls, String staticName) => _chromeOnly();

/// Whether the `ctorClass` primitive is new-able AND carries statics.
bool ctorClassRoundTrips() => _chromeOnly();

/// Whether the `staticClass` primitive answers callMethod on closures.
bool staticClassRoundTrips() => _chromeOnly();
