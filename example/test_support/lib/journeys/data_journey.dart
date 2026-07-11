// CHARTER — this journey alone proves the Data tab's binary-size dial END
// TO END through the example UI against the REAL engine, on every device
// shape: loading the en+fr subset re-initializes the engine so the ja probe
// row flips from a formatted number to an 'unavailable' row, and restoring
// full data flips it back. The transition is identical on both binary
// flavors (the fat binary gates its compiled data; the lean one loads only
// the en/fr postcards) — the probe row reads 'unavailable' either way. This
// file owns the only journeys that mutate global engine state — `flutter
// test` isolates suites per file, so the other journeys never see the subset.

import 'package:flutter_test/flutter_test.dart';
import 'package:icu_kit_example/main.dart' show initExampleIcu;

import '../icu_kit_example_test_support.dart';

void main() {
  setUpAll(() async {
    await initExampleIcu();
  });

  testJourneyAcrossDevices('data: subset rejects ja; restore heals it', (
    tester,
    device,
  ) async {
    final app = AppRobot(tester);
    final surface = SurfaceRobot(tester);
    await app.launch();
    await app.openTab('Data');

    // Establish the full state on BOTH flavors. On the bundled binary this
    // re-inits to all compiled data; on the lean binary it loads every
    // postcard (so ja — not preloaded at startup — becomes available). The
    // waits are `Eventually` because the lean restore reads postcards async.
    await surface.tapKey('data.restore');
    await surface.expectValueEventually('1,234,567.89');

    // Two-locale subset — ja drops out; its probe row reads 'unavailable'.
    await surface.tapKey('data.subset');
    await surface.expectValueEventually('unavailable');
    surface.expectAbsent('1,234,567.89');

    // Restore — ja heals.
    await surface.tapKey('data.restore');
    await surface.expectValueEventually('1,234,567.89');
  });
}
