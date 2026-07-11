// Thin runner — the suite body lives in the shared test_support package
// so the lean shell (example_lean/) runs the IDENTICAL smoke against
// the lean binary. Keep this file logic-free.

import 'package:icu_kit_example_test_support/smoke/icu_kit_smoke.dart' as smoke;

void main() => smoke.main();
