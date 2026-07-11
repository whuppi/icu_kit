// Web loader — fetches over HTTP. `dart test -p chrome` serves the package
// root statically under a per-run secret prefix; corpus test pages live at
// `/<secret>/test/_corpus/<file>.html`, so a relative URL is just
// `<component>/<file>`.

import 'dart:convert';
import 'dart:js_interop';

@JS('fetch')
external JSPromise<JSResponse> _fetch(JSString url);

extension type JSResponse._(JSObject _) implements JSObject {
  external JSPromise<JSString> text();
  external bool get ok;
  external int get status;
  external JSString get statusText;
}

Future<dynamic> loadCorpusJson(String component, String name) async {
  final raw = await loadCorpusText(component, '$name.json');
  return jsonDecode(raw);
}

Future<String> loadCorpusText(String component, String fileName) async {
  // Relative URL from /<secret>/test/_corpus/<file>.html → same dir.
  final url = '$component/$fileName';
  final response = await _fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError(
      'Corpus fixture fetch failed: $url '
      '(${response.status} ${response.statusText.toDart}). '
      'See test/_corpus/PROVENANCE.md.',
    );
  }
  final text = await response.text().toDart;
  return text.toDart;
}
