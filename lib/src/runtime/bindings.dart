// The single platform seam for the ICU4X binding surface. Facades import
// ONLY this selector — never runtime/native or runtime/web directly. On
// native it resolves to the Diplomat-generated Dart FFI bindings (plus tiny
// hand-written extras); on web to the typed js_interop mirrors, which copy
// the native surface's Dart-visible signatures exactly. A facade that
// compiles against both resolutions is proof the shapes match.
export 'native/bindings.dart' if (dart.library.js_interop) 'web/bindings.dart';
