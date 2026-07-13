// One-time initialization for icu_kit. Conditional import:
//
//   - On native targets — no-op (the build hook bundles libicu_capi
//     and Dart's runtime loads it automatically on first FFI call).
//
//   - On web — async-loads the JavaScript module shipped under
//     `web/icu_kit/lib/index.mjs`. Must be awaited before any
//     IcuLocale / IcuPluralRules / etc. is used.
//
// Call once before any icu_kit API is touched:
//
// ```dart
// import 'package:icu_kit/icu_kit.dart';
//
// Future<void> main() async {
//   await IcuKit.init();
//   runApp(MyApp());
// }
// ```

export 'runtime/native/init.dart'
    if (dart.library.js_interop) 'runtime/web/init.dart';

// The web-engine selector for `IcuKit.init(webEngine: ...)`.
export 'runtime/web_engine.dart';
