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
