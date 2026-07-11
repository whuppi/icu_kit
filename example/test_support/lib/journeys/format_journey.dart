// CHARTER — this journey alone proves the Format tab END TO END through
// the example UI against the REAL engine (the build hook compiles the
// native library for the host VM), on every device shape: (a) the locale
// picker re-renders the number row in the picked culture — de grouping
// dots, hi lakh grouping; (b) the plural stepper drives real CLDR plural
// categories through the UI (1 → one, 2 → other for en); (c) the
// relative-time and list rows render CLDR words, not templates, and
// re-render under a new locale. The rows run past the fold on the
// smallest profile, so the robot scrolls each into view — a lazy
// ListView never hides a value from the assertion.

import 'package:flutter_test/flutter_test.dart';
import 'package:icu_kit_example/main.dart' show initExampleIcu;

import '../icu_kit_example_test_support.dart';

void main() {
  setUpAll(() async {
    await initExampleIcu();
  });

  testJourneyAcrossDevices('format: locale picker reshapes numbers', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();

    await surface.expectValue('1,234,567.89'); // en-US default

    await app.pickLocale('de');
    await surface.expectValue('1.234.567,89');

    await app.pickLocale('hi'); // Hindi lakh/crore grouping
    await surface.expectValue('12,34,567.89');
  });

  testJourneyAcrossDevices('format: plural stepper drives CLDR categories', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();

    await surface.expectValue('1 → one');

    await surface.tapKey('plural.plus');
    await surface.expectValue('2 → other');

    await surface.tapKey('plural.minus');
    await surface.tapKey('plural.minus');
    await surface.expectValue('0 → other');
  });

  testJourneyAcrossDevices('format: relative time and lists speak CLDR', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();

    await surface.expectValue('yesterday');
    await surface.expectValue('in 2 days');
    await surface.expectValue('Aria, Kael, and Mira');

    await app.pickLocale('de');
    await surface.expectValue('gestern');
    await surface.expectValue('Aria, Kael und Mira');
  });
}
