// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): loads the icu_capi native library via the build hook, exercises the Dart
// facade, and verifies CLDR-correct categorization for cardinal + ordinal
// rules across multiple locales.
//
// If this test fails on a platform where the build hook can't run (e.g.
// missing Rust toolchain), the test is SKIPPED rather than reported as a
// false failure. The fail-loud surface is the hook itself, not this test.

// Diet: the public facade + literals declared in this file.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  // On web, point at web_assets/ at the package root. `dart test -p chrome`
  // serves the package root statically but nests every URL under a
  // randomly-generated secret prefix for cross-tenant safety (see
  // package:test platform.dart `PathHandler.nestedIn(_secret)`). The test
  // page itself lives at `/<secret>/test/<file>.html`, so we need a
  // relative path that climbs one level out of `/test/` to reach
  // `/web_assets/` while staying under the secret prefix.
  //
  // On native, IcuKit.moduleUrl is a no-op setter.
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuPluralRules — English cardinals (CLDR)', () {
    late final IcuPluralRules en;
    setUpAll(() {
      en = IcuPluralRules.cardinal('en');
    });

    test('1 → one', () => expect(en.category(1), IcuPluralCategory.one));
    test('0 → other', () => expect(en.category(0), IcuPluralCategory.other));
    test('2 → other', () => expect(en.category(2), IcuPluralCategory.other));
    test(
      '100 → other',
      () => expect(en.category(100), IcuPluralCategory.other),
    );

    test('supportedCategories = {one, other}', () {
      expect(en.supportedCategories, {
        IcuPluralCategory.one,
        IcuPluralCategory.other,
      });
    });
  });

  group('IcuPluralRules — English ordinals (CLDR)', () {
    late final IcuPluralRules en;
    setUpAll(() {
      en = IcuPluralRules.ordinal('en');
    });

    test('1 → one (1st)', () => expect(en.category(1), IcuPluralCategory.one));
    test('2 → two (2nd)', () => expect(en.category(2), IcuPluralCategory.two));
    test('3 → few (3rd)', () => expect(en.category(3), IcuPluralCategory.few));
    test(
      '4 → other (4th)',
      () => expect(en.category(4), IcuPluralCategory.other),
    );
    test(
      '11 → other (11th)',
      () => expect(en.category(11), IcuPluralCategory.other),
    );
    test(
      '21 → one (21st)',
      () => expect(en.category(21), IcuPluralCategory.one),
    );
    test(
      '22 → two (22nd)',
      () => expect(en.category(22), IcuPluralCategory.two),
    );
    test(
      '23 → few (23rd)',
      () => expect(en.category(23), IcuPluralCategory.few),
    );

    test('supportedCategories = {one, two, few, other}', () {
      expect(en.supportedCategories, {
        IcuPluralCategory.one,
        IcuPluralCategory.two,
        IcuPluralCategory.few,
        IcuPluralCategory.other,
      });
    });
  });

  group('IcuPluralRules — Polish cardinals (rich plural language)', () {
    // Polish has zero (kind of), one, few, many, other in cardinal forms.
    // CLDR rule: one for n=1; few for 2-4 (excluding teens); many for the
    // rest with various conditions.
    late final IcuPluralRules pl;
    setUpAll(() {
      pl = IcuPluralRules.cardinal('pl');
    });

    test('1 → one', () => expect(pl.category(1), IcuPluralCategory.one));
    test('2 → few', () => expect(pl.category(2), IcuPluralCategory.few));
    test('3 → few', () => expect(pl.category(3), IcuPluralCategory.few));
    test('4 → few', () => expect(pl.category(4), IcuPluralCategory.few));
    test('5 → many', () => expect(pl.category(5), IcuPluralCategory.many));
    test('22 → few', () => expect(pl.category(22), IcuPluralCategory.few));
  });

  group('IcuPluralRules — Arabic cardinals (six-category language)', () {
    // Arabic uses ALL six categories (zero, one, two, few, many, other).
    late final IcuPluralRules ar;
    setUpAll(() {
      ar = IcuPluralRules.cardinal('ar');
    });

    test('0 → zero', () => expect(ar.category(0), IcuPluralCategory.zero));
    test('1 → one', () => expect(ar.category(1), IcuPluralCategory.one));
    test('2 → two', () => expect(ar.category(2), IcuPluralCategory.two));
    test('3 → few', () => expect(ar.category(3), IcuPluralCategory.few));
    test('11 → many', () => expect(ar.category(11), IcuPluralCategory.many));
    test(
      '100 → other',
      () => expect(ar.category(100), IcuPluralCategory.other),
    );

    test('supportedCategories = all six', () {
      expect(ar.supportedCategories, {
        IcuPluralCategory.zero,
        IcuPluralCategory.one,
        IcuPluralCategory.two,
        IcuPluralCategory.few,
        IcuPluralCategory.many,
        IcuPluralCategory.other,
      });
    });
  });

  group('IcuPluralRules — Japanese (only "other" category)', () {
    // Languages without grammatical number have only `other`.
    late final IcuPluralRules ja;
    setUpAll(() {
      ja = IcuPluralRules.cardinal('ja');
    });

    test('1 → other', () => expect(ja.category(1), IcuPluralCategory.other));
    test('2 → other', () => expect(ja.category(2), IcuPluralCategory.other));
    test(
      '100 → other',
      () => expect(ja.category(100), IcuPluralCategory.other),
    );

    test('supportedCategories = {other} only', () {
      expect(ja.supportedCategories, {IcuPluralCategory.other});
    });
  });

  group('IcuPluralCategory.tryParse', () {
    test('round-trips every name', () {
      for (final c in IcuPluralCategory.values) {
        expect(IcuPluralCategory.tryParse(c.name), c);
      }
    });

    test('returns null on unknown', () {
      expect(IcuPluralCategory.tryParse('quintuple'), isNull);
    });
  });
}
