// Corpus-driven test helpers — load JSON / UCD fixtures vendored from upstream
// ICU4X + Unicode. See PROVENANCE.md for source.
//
// Cross-platform: native uses dart:io; web uses HTTP fetch via XMLHttpRequest
// since `dart test -p chrome` serves the package root statically. The
// conditional import keeps web builds dart:io-free.

import 'corpus_loader_io.dart'
    if (dart.library.js_interop) 'corpus_loader_web.dart';

/// Loads a JSON fixture from `test/_corpus/{component}/{name}.json`.
/// Returns parsed JSON (`List<dynamic>` or `Map<String, dynamic>`).
Future<dynamic> loadJsonFixture(String component, String name) =>
    loadCorpusJson(component, name);

/// Loads a UCD `.txt` fixture (semicolon-separated, `#` comments).
/// Returns rows-of-fields.
Future<List<List<String>>> loadUcdFixture(String name) async {
  final raw = await loadCorpusText('ucd', name);
  return _parseUcd(raw);
}

/// Loads a UCD `.txt` fixture without parsing — returns the raw text.
/// Use for non-`;`-separated formats (e.g. UCD auxiliary break tests).
Future<String> loadUcdRawText(String name) => loadCorpusText('ucd', name);

/// Loads ANY corpus file as raw text. Use for non-UCD formats
/// (collator UCA tables, etc.).
Future<String> loadRawText(String component, String fileName) =>
    loadCorpusText(component, fileName);

List<List<String>> _parseUcd(String raw) {
  final rows = <List<String>>[];
  for (final line in raw.split('\n')) {
    final hashIdx = line.indexOf('#');
    final clean = (hashIdx >= 0 ? line.substring(0, hashIdx) : line).trim();
    if (clean.isEmpty) continue;
    rows.add(clean.split(';').map((s) => s.trim()).toList(growable: false));
  }
  return rows;
}
