// Pure (no dart:io) canonical form for the module-class name set, shared by
// the VM extractor (which derives it from source) and the chrome twin (which
// asserts the built module registers every name). See the guard rationale in
// surface_extractor.dart / docs/PLAN_BROWSER_INTL.md §4e.
library;

/// Deterministic one-name-per-line canonical form, sorted, for snapshotting.
String serializeClasses(Set<String> names) =>
    (names.toList()..sort()).join('\n');

/// Parse the canonical form back into a set.
Set<String> parseClasses(String text) =>
    text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toSet();
