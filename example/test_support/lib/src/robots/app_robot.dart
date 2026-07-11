import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icu_kit_example/main.dart';

import '../harness/robot.dart';

/// Drives the example app's top-level chrome: launch, tab switching, and
/// the app-bar locale picker that every surface reacts to.
class AppRobot extends Robot {
  AppRobot(super.tester);

  /// Boots the real app and waits for the first stable frame. The caller
  /// runs `IcuKit.init()` in setUpAll — the app's own `main()` is bypassed
  /// so a journey can pump straight into the widget under a device
  /// profile.
  Future<void> launch() async {
    await tester.pumpWidget(const IcuKitExampleApp());
    await settle();
  }

  /// Switches to the named tab. The bar holds four fixed tabs — always
  /// visible, no scrolling — so a plain tap plus settle is the whole move.
  Future<void> openTab(String label) async {
    await tester.tap(find.widgetWithText(Tab, label));
    await settle();
  }

  /// Picks [locale] from the pinned locale strip, re-rendering every
  /// surface. The strip scrolls horizontally; on a narrow device a chip
  /// sits off either edge and may not be built. A hand-rolled loop homes
  /// the strip to the left, then scrolls right until the chip builds — no
  /// overlay menu to leave a modal barrier over the content, and no
  /// `scrollUntilVisible` (whose internal `element(finder).single` throws
  /// while the chip is still unbuilt).
  Future<void> pickLocale(String locale) async {
    final strip = find
        .descendant(
          of: find.byKey(const ValueKey('locale-strip')),
          matching: find.byType(Scrollable),
        )
        .first;
    final chip = find.byKey(ValueKey('locale:$locale'));

    await tester.drag(strip, const Offset(10000, 0)); // home to the left
    await settle();
    for (var i = 0; i < 40 && chip.evaluate().isEmpty; i++) {
      await tester.drag(strip, const Offset(-200, 0)); // scroll right
      await settle();
    }
    await Scrollable.ensureVisible(
      tester.element(chip),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(chip);
    await settle();
  }
}
