// The locale-error law, as ONE spec instead of a rule re-proven ad-hoc
// in every facade charter: any public entry point that accepts a BCP-47
// tag throws IcuLocaleParseError — never IcuDataError, never a crash —
// when the tag cannot parse. Register-only, no main; the runner
// (facades_grammar_test.dart) plugs every locale-taking entry point in.

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

/// Tags no BCP-47 parser accepts. Every plugged case must throw on each.
const badLocaleTags = ['!!not-a-locale!!', ''];

/// One locale-taking entry point plugged into the law.
final class LocaleLawCase {
  /// [act] invokes the entry point with the bad tag; [tags] are test
  /// tags (declared in dart_test.yaml) for experimental facades.
  const LocaleLawCase(this.name, this.act, {this.tags});

  /// Display name — the entry point as a caller writes it.
  final String name;

  /// Invokes the entry point with the given locale; must throw for a
  /// bad tag.
  final void Function(String locale) act;

  /// Test tags applied to this case's group, if any.
  final List<String>? tags;
}

/// Every public entry point that accepts a BCP-47 tag, as law cases. Shared
/// by the wasm runner (facades_grammar_test.dart) and the browser-engine
/// runner (browser_engine/grammar_chrome_test.dart) so the 27-entry table has
/// ONE source. The full fleet table + footnotes live in
/// facades_grammar_test.dart.
///
/// These cases exercise only the BAD-tag path: parsing rejects the tag BEFORE
/// dispatch, so a facade that is otherwise unsupported on an engine (e.g.
/// IcuExemplarCharacters on the browser-Intl engine) still throws
/// IcuLocaleParseError here and passes on both runners. If a valid-tag
/// construction law is ever added, tag any browser-unsupported case (a new
/// dart_test.yaml tag such as 'experimental_exemplar') so the browser-engine
/// runner skips the ones that engine cannot build.
List<LocaleLawCase> allLocaleLawCases() => [
  LocaleLawCase('IcuLocale.parse', (l) => IcuLocale.parse(l)),
  LocaleLawCase('IcuCollator', (l) => IcuCollator(locale: l)),
  LocaleLawCase(
    'IcuNumberFormat.decimal',
    (l) => IcuNumberFormat.decimal(locale: l),
  ),
  LocaleLawCase(
    'IcuCurrencyFormat.symbol',
    (l) => IcuCurrencyFormat.symbol(locale: l),
    tags: ['experimental_currency'],
  ),
  LocaleLawCase(
    'IcuCurrencyFormat.long',
    (l) => IcuCurrencyFormat.long(locale: l, currencyCode: 'USD'),
    tags: ['experimental_currency'],
  ),
  LocaleLawCase(
    'IcuPercentFormat',
    (l) => IcuPercentFormat(locale: l),
    tags: ['experimental_percent'],
  ),
  LocaleLawCase(
    'IcuUnitFormat',
    (l) => IcuUnitFormat(locale: l, unit: 'hour'),
    tags: ['experimental_unit'],
  ),
  LocaleLawCase('IcuDateFormat.ymd', (l) => IcuDateFormat.ymd(locale: l)),
  LocaleLawCase('IcuTimeFormat', (l) => IcuTimeFormat(locale: l)),
  LocaleLawCase(
    'IcuDateTimeFormat.ymdt',
    (l) => IcuDateTimeFormat.ymdt(locale: l),
  ),
  LocaleLawCase(
    'IcuZonedDateTimeFormat.ymdt',
    (l) => IcuZonedDateTimeFormat.ymdt(locale: l),
  ),
  LocaleLawCase('IcuTimeZoneFormat', (l) => IcuTimeZoneFormat(locale: l)),
  LocaleLawCase('IcuListFormat.and', (l) => IcuListFormat.and(locale: l)),
  LocaleLawCase('IcuPluralRules.cardinal', (l) => IcuPluralRules.cardinal(l)),
  LocaleLawCase(
    'IcuRelativeTimeFormat',
    (l) => IcuRelativeTimeFormat(locale: l, unit: IcuRelativeTimeUnit.day),
  ),
  LocaleLawCase(
    'IcuRegionDisplayNames',
    (l) => IcuRegionDisplayNames(locale: l),
  ),
  LocaleLawCase(
    'IcuLocaleDisplayNames',
    (l) => IcuLocaleDisplayNames(locale: l),
  ),
  LocaleLawCase(
    'IcuExemplarCharacters',
    (l) => IcuExemplarCharacters(locale: l, set: IcuExemplarSet.main),
  ),
  LocaleLawCase('IcuSegmenter.word', (l) => IcuSegmenter.word(locale: l)),
  LocaleLawCase(
    'IcuSegmenter.sentence',
    (l) => IcuSegmenter.sentence(locale: l),
  ),
  LocaleLawCase(
    'IcuLocaleCanonicalizer.canonicalize',
    (l) => IcuLocaleCanonicalizer().canonicalize(l),
  ),
  LocaleLawCase(
    'IcuLocaleExpander.maximize',
    (l) => IcuLocaleExpander().maximize(l),
  ),
  LocaleLawCase(
    'IcuLocaleExpander.minimize',
    (l) => IcuLocaleExpander().minimize(l),
  ),
  LocaleLawCase(
    'IcuLocaleExpander.minimizeFavorScript',
    (l) => IcuLocaleExpander().minimizeFavorScript(l),
  ),
  LocaleLawCase(
    'IcuLocaleDirectionality.directionOf',
    (l) => IcuLocaleDirectionality().directionOf(l),
  ),
  LocaleLawCase(
    'IcuLocaleFallbacker.chain',
    (l) => IcuLocaleFallbacker().chain(l).first,
  ),
  LocaleLawCase(
    'IcuCaseMapper.uppercase',
    (l) => IcuCaseMapper().uppercase('x', locale: l),
  ),
];

/// Registers one group per case: each bad tag must throw
/// [IcuLocaleParseError].
void registerLocaleGrammarBattery(List<LocaleLawCase> cases) {
  for (final c in cases) {
    group(c.name, () {
      for (final bad in badLocaleTags) {
        test("'$bad' throws IcuLocaleParseError", () {
          expect(() => c.act(bad), throwsA(isA<IcuLocaleParseError>()));
        });
      }
    }, tags: c.tags);
  }
}
