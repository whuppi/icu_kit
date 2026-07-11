import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../harness/pump_strategies.dart';
import '../harness/robot.dart';

/// Drives a demo surface: reads a formatted value off screen, types into
/// a live input field, or taps a control — each scrolled into view first.
///
/// A tab's rows run past the fold on the smallest device profile, and a
/// lazy `ListView` doesn't build off-screen children. Every read/enter/tap
/// therefore homes the list to the top (scrollUntilVisible only searches
/// downward), scrolls the target into view (building it), and centres it —
/// so an assertion never fails merely because a row sat below the fold.
class SurfaceRobot extends Robot {
  SurfaceRobot(super.tester);

  /// The ACTIVE tab's scrollable. Every tab keys its list 'surface-list';
  /// with adjacent tabs kept alive by the PageView, only the on-stage
  /// one is hit-testable.
  Finder get _list => find
      .descendant(
        of: find.byKey(const ValueKey('surface-list')),
        matching: find.byType(Scrollable),
      )
      .hitTestable()
      .first;

  Future<void> _homeTop() async {
    await tester.drag(_list, const Offset(0, 10000));
    await settle();
  }

  /// Homes to the top, scrolls [finder] into view (building it if the lazy
  /// list hasn't), and centres it.
  ///
  /// A hand-rolled loop rather than `scrollUntilVisible`, for two reasons
  /// the built-in can't satisfy at once: the target may be ABSENT while
  /// scrolling (poll the base finder, whose `evaluate()` returns empty
  /// cleanly — a `.first` finder throws "No element" there), and once found
  /// it may match MORE THAN ONE row (two locales collate the same names
  /// identically), so the centring step takes `.first` — `scrollUntilVisible`
  /// calls `element(finder).single` internally and would throw "Too many".
  Future<void> scrollTo(Finder finder) async {
    await _homeTop();
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      await tester.drag(_list, const Offset(0, -120));
      await settle();
    }
    await Scrollable.ensureVisible(
      tester.element(finder.first),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await settle();
  }

  /// Scrolls to and asserts a `Text` reading [value] is on screen. Uses
  /// `findsWidgets` so a value shown twice on one tab (a showcase row and
  /// a live row) still passes — the point is that it rendered.
  Future<void> expectValue(String value) async {
    await scrollTo(find.text(value));
    expect(
      find.text(value),
      findsWidgets,
      reason: 'expected "$value" on screen',
    );
  }

  /// Pumps until a `Text` reading [value] is built, then asserts it — for
  /// use after an action that reconfigures data ASYNCHRONOUSLY (a lean
  /// binary loads postcards on demand, so a data-subset switch or a
  /// "restore" that loads every locale takes real time that `settle`'s
  /// fixed frame budget won't wait out). [timeout] is generous because a
  /// full restore can read tens of MB of postcards.
  Future<void> expectValueEventually(
    String value, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await pumpUntil(
      tester,
      () => find.text(value).evaluate().isNotEmpty,
      timeout: timeout,
      describe: 'text "$value"',
    );
    expect(
      find.text(value),
      findsWidgets,
      reason: 'expected "$value" on screen',
    );
  }

  /// Asserts no `Text` on the current surface reads [value] — used after a
  /// data-subset switch flips a covered locale's output to an error row.
  void expectAbsent(String value) {
    expect(
      find.text(value),
      findsNothing,
      reason: '"$value" should not be on screen',
    );
  }

  /// Types [text] into the field keyed [key], scrolling it into view first
  /// (`enterText` needs the field built).
  Future<void> enterField(String key, String text) async {
    await scrollTo(find.byKey(ValueKey(key)));
    await tester.enterText(find.byKey(ValueKey(key)), text);
    await settle();
  }

  /// Scrolls the control keyed [key] to centre and taps it.
  Future<void> tapKey(String key) =>
      scrollToAndTap(find.byKey(ValueKey(key)), list: _list);
}
