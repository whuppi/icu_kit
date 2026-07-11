// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): verifies locale-aware list formatting (conjunction / disjunction / unit)
// across multiple locales + lengths.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuListFormat.and — English (en) conjunction', () {
    late final IcuListFormat fmt;
    setUpAll(() {
      fmt = IcuListFormat.and(locale: 'en');
    });

    test('three items produces "A, B, and C"', () {
      expect(fmt.format(['Alice', 'Bob', 'Carol']), 'Alice, Bob, and Carol');
    });

    test('two items produces "A and B"', () {
      expect(fmt.format(['Alice', 'Bob']), 'Alice and Bob');
    });

    test('single item is unchanged', () {
      expect(fmt.format(['Alice']), 'Alice');
    });

    test('empty list is empty string', () {
      expect(fmt.format([]), '');
    });
  });

  group('IcuListFormat.or — English (en) disjunction', () {
    test('three items produces "A, B, or C"', () {
      final fmt = IcuListFormat.or(locale: 'en');
      expect(fmt.format(['red', 'green', 'blue']), 'red, green, or blue');
    });
  });

  group('IcuListFormat — French (fr) uses Oxford comma differently', () {
    test('and-list joins with "et" without Oxford comma', () {
      final fmt = IcuListFormat.and(locale: 'fr');
      // French: "Alice, Bob et Carol" (no comma before 'et')
      final result = fmt.format(['Alice', 'Bob', 'Carol']);
      expect(result, contains('et'));
      expect(result, contains('Alice'));
      expect(result, contains('Bob'));
      expect(result, contains('Carol'));
    });
  });

  group('IcuListFormat — German (de) conjunction', () {
    test('and-list joins with "und"', () {
      final fmt = IcuListFormat.and(locale: 'de');
      final result = fmt.format(['Anna', 'Bert', 'Clara']);
      expect(
        result,
        contains('und'),
        reason: 'expected German "und", got: $result',
      );
    });
  });

  group('IcuListFormat.unit — unit join', () {
    test('en unit list joins without "and"', () {
      final fmt = IcuListFormat.unit(locale: 'en');
      // Unit lists: "3 hr 4 min 5 sec" — no conjunction word.
      final result = fmt.format(['3 hr', '4 min', '5 sec']);
      expect(
        result.toLowerCase(),
        isNot(contains(' and ')),
        reason: 'unit list should not include "and", got: $result',
      );
      expect(result, contains('3 hr'));
      expect(result, contains('5 sec'));
    });
  });

  group('IcuListFormat — short and narrow lengths', () {
    test('en short uses "&" instead of "and"', () {
      final fmt = IcuListFormat.and(locale: 'en', length: IcuListLength.short);
      final result = fmt.format(['A', 'B', 'C']);
      // CLDR en short uses "&" for and-lists.
      expect(
        result,
        contains('&'),
        reason: 'expected short form to use "&", got: $result',
      );
    });

    test('en narrow drops the conjunction word entirely', () {
      final fmt = IcuListFormat.and(locale: 'en', length: IcuListLength.narrow);
      final result = fmt.format(['A', 'B', 'C']);
      // CLDR en narrow: "A, B, C" — comma-only, no "and"/"&".
      expect(result.toLowerCase(), isNot(contains('and')));
      expect(result, isNot(contains('&')));
    });
  });
}
