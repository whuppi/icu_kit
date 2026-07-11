// Native loader — reads from disk via dart:io.

import 'dart:convert';
import 'dart:io';

Future<dynamic> loadCorpusJson(String component, String name) async {
  final raw = await loadCorpusText(component, '$name.json');
  return jsonDecode(raw);
}

Future<String> loadCorpusText(String component, String fileName) async {
  // Resolve relative to the package root. `dart test` runs with cwd set to
  // the package root, so `test/_corpus/...` is the canonical path.
  final path = 'test/_corpus/$component/$fileName';
  final file = File(path);
  if (!await file.exists()) {
    throw StateError(
      'Corpus fixture not found: $path '
      '(cwd: ${Directory.current.path}). '
      'See test/_corpus/PROVENANCE.md.',
    );
  }
  return file.readAsString();
}
