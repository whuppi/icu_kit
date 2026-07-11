// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies UAX #9 bidirectional algorithm:
//   * LTR-only English → ltr direction
//   * RTL-only Arabic/Hebrew → rtl direction
//   * Mixed Arabic+English → mixed direction
//   * Per-character embedding levels (even = LTR, odd = RTL)
//   * Static helpers (rtlLevel, ltrLevel, levelIsRtl, levelIsLtr)

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  late final IcuBidi bidi;
  setUpAll(() {
    bidi = IcuBidi();
  });

  group('IcuBidi — static helpers', () {
    test('rtlLevel is odd', () {
      expect(IcuBidi.rtlLevel, 1);
    });

    test('ltrLevel is even', () {
      expect(IcuBidi.ltrLevel, 0);
    });

    test('levelIsRtl: 1 yes, 0 no', () {
      expect(IcuBidi.levelIsRtl(1), isTrue);
      expect(IcuBidi.levelIsRtl(0), isFalse);
    });

    test('levelIsLtr: 0 yes, 1 no', () {
      expect(IcuBidi.levelIsLtr(0), isTrue);
      expect(IcuBidi.levelIsLtr(1), isFalse);
    });
  });

  group('IcuBidi — pure LTR', () {
    test('"Hello world" is one paragraph, ltr direction', () {
      final analysis = bidi.analyze('Hello world');
      expect(analysis.paragraphCount, 1);
      final p = analysis.paragraph(0)!;
      expect(p.direction, IcuBidiDirection.ltr);
    });

    test('all character levels are 0 (LTR)', () {
      final analysis = bidi.analyze('Hello');
      for (var i = 0; i < analysis.size; i++) {
        expect(analysis.levelAt(i), 0);
      }
    });
  });

  group('IcuBidi — pure RTL (Arabic)', () {
    test('Arabic text has rtl direction', () {
      final analysis = bidi.analyze('مرحبا');
      expect(analysis.paragraphCount, 1);
      final p = analysis.paragraph(0)!;
      expect(p.direction, IcuBidiDirection.rtl);
    });

    test('Arabic character levels are odd (RTL)', () {
      final analysis = bidi.analyze('مرحبا');
      for (var i = 0; i < analysis.size; i++) {
        expect(
          IcuBidi.levelIsRtl(analysis.levelAt(i)),
          isTrue,
          reason: 'expected RTL level at pos $i',
        );
      }
    });
  });

  group('IcuBidi — mixed LTR+RTL', () {
    test('"Hello مرحبا" reports mixed direction', () {
      final analysis = bidi.analyze('Hello مرحبا');
      final p = analysis.paragraph(0)!;
      expect(p.direction, IcuBidiDirection.mixed);
    });

    test('Latin chars have even levels, Arabic chars have odd levels', () {
      final analysis = bidi.analyze('Hello مرحبا');
      // 'H' is at index 0 (LTR, even level)
      expect(IcuBidi.levelIsLtr(analysis.levelAt(0)), isTrue);
      // The Arabic chars are after "Hello " (6 UTF-16 units in)
      expect(IcuBidi.levelIsRtl(analysis.levelAt(6)), isTrue);
    });
  });

  group('IcuBidi — paragraph getters', () {
    test('rangeStart, rangeEnd, size cover the paragraph', () {
      final analysis = bidi.analyze('Hello world');
      final p = analysis.paragraph(0)!;
      expect(p.rangeStart, 0);
      expect(p.rangeEnd, 11);
      expect(p.size, 11);
    });

    test('paragraph(out_of_range) returns null', () {
      final analysis = bidi.analyze('Hello');
      expect(analysis.paragraph(5), isNull);
    });
  });

  group('IcuBidi — multi-paragraph text', () {
    test('two paragraphs separated by newline', () {
      final analysis = bidi.analyze('Hello\nمرحبا');
      expect(analysis.paragraphCount, 2);
      // Paragraph 0: English, ltr
      expect(analysis.paragraph(0)!.direction, IcuBidiDirection.ltr);
      // Paragraph 1: Arabic, rtl
      expect(analysis.paragraph(1)!.direction, IcuBidiDirection.rtl);
    });
  });
}
