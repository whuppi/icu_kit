// The lean shell's ENTIRE app code: run the real example app. Being
// launched from THIS package root is what makes it lean — the pubspec's
// user_define switches the build hook to the no-CLDR binary, and the
// app detects that at runtime (IcuKit.hasCompiledData) and loads the
// asset postcards instead. See ../pubspec.yaml and example/lib/main.dart.

import 'package:icu_kit_example/main.dart' as app;

Future<void> main() => app.main();
