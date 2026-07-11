import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuLocaleDirectionality — RTL languages', () {
    late final IcuLocaleDirectionality dir;
    setUpAll(() {
      dir = IcuLocaleDirectionality();
    });

    test('Arabic is RTL', () {
      expect(dir.isRtl('ar'), isTrue);
      expect(dir.isLtr('ar'), isFalse);
      expect(dir.directionOf('ar'), IcuLocaleDirection.rightToLeft);
    });

    test('Hebrew is RTL', () {
      expect(dir.isRtl('he'), isTrue);
      expect(dir.directionOf('he'), IcuLocaleDirection.rightToLeft);
    });

    test('Persian (fa) is RTL', () {
      expect(dir.isRtl('fa'), isTrue);
    });

    test('Urdu (ur) is RTL', () {
      expect(dir.isRtl('ur'), isTrue);
    });
  });

  group('IcuLocaleDirectionality — LTR languages', () {
    late final IcuLocaleDirectionality dir;
    setUpAll(() {
      dir = IcuLocaleDirectionality();
    });

    test('English is LTR', () {
      expect(dir.isLtr('en'), isTrue);
      expect(dir.isRtl('en'), isFalse);
      expect(dir.directionOf('en'), IcuLocaleDirection.leftToRight);
    });

    test('German is LTR', () {
      expect(dir.isLtr('de'), isTrue);
    });

    test('Japanese is LTR', () {
      // Japanese is written top-to-bottom traditionally but ICU4X
      // classifies it as LTR for layout direction.
      expect(dir.isLtr('ja'), isTrue);
    });

    test('Chinese is LTR', () {
      expect(dir.isLtr('zh'), isTrue);
    });
  });
}
