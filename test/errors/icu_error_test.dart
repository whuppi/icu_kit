import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  group('IcuError sealed hierarchy', () {
    test('IcuLocaleParseError carries the offending input', () {
      const e = IcuLocaleParseError('not-a-locale');
      expect(e.input, 'not-a-locale');
      expect(e.message, contains('not-a-locale'));
      expect(e, isA<IcuError>());
    });

    test('IcuDataError carries optional locale + marker', () {
      const e = IcuDataError(
        'Missing data',
        locale: 'fr',
        marker: 'PluralRules',
      );
      expect(e.locale, 'fr');
      expect(e.marker, 'PluralRules');
      expect(e.message, 'Missing data');
    });

    test('IcuOptionError carries option name and bad value', () {
      final e = IcuOptionError('currencyDisplay', 'banana');
      expect(e.optionName, 'currencyDisplay');
      expect(e.badValue, 'banana');
      expect(e.message, contains('currencyDisplay'));
      expect(e.message, contains('banana'));
    });

    test('IcuLoadError carries platform + cause', () {
      final cause = StateError('library not loaded');
      final e = IcuLoadError('macos-arm64', cause);
      expect(e.platform, 'macos-arm64');
      expect(e.cause, cause);
      expect(e.message, contains('macos-arm64'));
    });

    test('exhaustive switch compiles', () {
      // This test exists to lock in the sealed contract: every IcuError
      // subtype MUST be handled. If a new subtype is added without updating
      // this switch, the compiler will fail this test. That is the entire
      // point of `sealed` + `final`.
      String describe(IcuError err) => switch (err) {
        IcuLocaleParseError() => 'parse',
        IcuDataError() => 'data',
        IcuMissingDataError() => 'missingData',
        IcuOptionError() => 'option',
        IcuLoadError() => 'platform',
        IcuIdnaError() => 'idna',
      };

      expect(describe(const IcuLocaleParseError('x')), 'parse');
      expect(describe(const IcuDataError('m')), 'data');
      expect(
        describe(const IcuMissingDataError('m', locale: 'fr')),
        'missingData',
      );
      expect(describe(IcuOptionError('o', 1)), 'option');
      expect(describe(IcuLoadError('p', null)), 'platform');
      expect(
        describe(IcuIdnaError(IcuIdnaErrorKind.invalid, 'bad', 'toAscii')),
        'idna',
      );
    });

    test('IcuError implements Exception (catchable as Exception)', () {
      try {
        throw const IcuLocaleParseError('bad');
      } on Exception catch (e) {
        expect(e, isA<IcuError>());
      }
    });
  });
}
