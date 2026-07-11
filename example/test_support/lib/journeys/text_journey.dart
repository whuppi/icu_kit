// CHARTER — this journey alone proves the Text tab END TO END through the
// example UI against the REAL engine, on every device shape: (a) Thai word
// segmentation splits the spaceless greeting via the CLDR dictionary,
// visible as separator-joined words; (b) the locale-aware case rows show
// the Turkish dotted İ and the German ß → SS expansions; (c) NFC
// composition equals the precomposed é; (d) mixed-direction text analyzes
// as `mixed`; (e) typing a Unicode domain into the IDNA field punycodes it
// live. Every row is scrolled into view first, so the bottom-of-tab IDNA
// section is proven even on the smallest profile.

import 'package:flutter_test/flutter_test.dart';
import 'package:icu_kit_example/main.dart' show initExampleIcu;

import '../icu_kit_example_test_support.dart';

void main() {
  setUpAll(() async {
    await initExampleIcu();
  });

  testJourneyAcrossDevices('text: segmentation, case, NFC, bidi showcases', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();
    await app.openTab('Text');

    await surface.expectValue('สวัส · ดี · ครับ');
    await surface.expectValue('İSTANBUL'); // showcase + live tr row
    await surface.expectValue('STRASSE');
    await surface.expectValue('é  (== é: true)');
    await surface.expectValue('mixed');
  });

  testJourneyAcrossDevices('text: IDNA field punycodes typed domains live', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();
    await app.openTab('Text');

    await surface.expectValue('xn--wgv71a.jp');
    await surface.expectValue('münchen.de');

    await surface.enterField('idna.ascii.input', 'bücher.de');
    await surface.expectValue('xn--bcher-kva.de');
  });
}
