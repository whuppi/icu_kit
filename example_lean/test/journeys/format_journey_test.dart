// Thin runner — the suite body lives in the shared test_support package
// so this lean shell runs the IDENTICAL journey against
// the lean binary. Keep this file logic-free.

import 'package:icu_kit_example_test_support/journeys/format_journey.dart'
    as journey;

void main() => journey.main();
