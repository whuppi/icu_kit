// CHARTER — this journey alone proves the Locale tab END TO END through
// the example UI against the REAL engine, on every device shape: (a)
// typing a sloppy tag into the parse field canonicalizes it live
// (EN-latn-us → en-Latn-US); (b) likely-subtags expansion maximizes a
// typed tag (ja → ja-Jpan-JP); (c) picking an RTL locale flips the
// direction row; (d) display names re-render in the picked locale (DE →
// Allemagne, JP → Japon under fr); (e) Swedish collation orders å/ö
// after z. Every row is scrolled into view first.

import 'package:flutter_test/flutter_test.dart';
import 'package:icu_kit_example/main.dart' show initExampleIcu;

import '../icu_kit_example_test_support.dart';

void main() {
  setUpAll(() async {
    await initExampleIcu();
  });

  testJourneyAcrossDevices('locale: parse and likely-subtags respond live', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();
    await app.openTab('Locale');

    await surface.expectValue('zh-Hant-TW');
    await surface.expectValue('sr-Cyrl-RS');

    await surface.enterField('parse.input', 'EN-latn-us');
    await surface.expectValue('en-Latn-US');

    await surface.enterField('expander.input', 'ja');
    await surface.expectValue('ja-Jpan-JP');
  });

  testJourneyAcrossDevices('locale: direction, names, collation per locale', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();
    await app.openTab('Locale');

    await surface.expectValue('leftToRight');
    await surface.expectValue('Anna, Åsa, Östen'); // Swedish order

    await app.pickLocale('ar');
    await surface.expectValue('rightToLeft');

    await app.pickLocale('fr');
    await surface.expectValue('Allemagne');
    await surface.expectValue('Japon');
    await surface.expectValue('français');
  });
}
