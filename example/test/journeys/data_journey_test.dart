// Thin runner — the suite body lives in the shared test_support package
// so the lean shell (example_lean/) runs the IDENTICAL journey against
// the lean binary. Keep this file logic-free.

import 'package:icu_kit_example_test_support/journeys/data_journey.dart'
    as journey;

void main() => journey.main();
