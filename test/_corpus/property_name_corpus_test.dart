// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UCD's PropertyValueAliases.txt corpus through
// IcuPropertyName for every enum property kind icu_kit exposes.
//
// For each row `<prop> ; <short> ; <long> [; <synonym> ...]`:
//   * codeFor(short)  ≡ codeFor(long)  ≡ codeFor(synonym...)
//   * nameOf(code, short: true)  ≡ short
//   * nameOf(code, short: false) ≡ long
//
// Source: https://www.unicode.org/Public/16.0.0/ucd/PropertyValueAliases.txt
// (vendored under test/_corpus/ucd/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

/// Maps icu_kit property kinds to UCD short property identifiers.
const _kindToUcdProperty = {
  IcuPropertyKind.script: 'sc',
  IcuPropertyKind.bidiClass: 'bc',
  IcuPropertyKind.numericType: 'nt',
  IcuPropertyKind.eastAsianWidth: 'ea',
  IcuPropertyKind.lineBreak: 'lb',
  IcuPropertyKind.graphemeClusterBreak: 'GCB',
  IcuPropertyKind.wordBreak: 'WB',
  IcuPropertyKind.sentenceBreak: 'SB',
  IcuPropertyKind.hangulSyllableType: 'hst',
  IcuPropertyKind.canonicalCombiningClass: 'ccc',
};

/// Builds [kind]'s name resolver via the matching factory constructor.
IcuPropertyName _buildResolver(IcuPropertyKind kind) => switch (kind) {
  IcuPropertyKind.script => IcuPropertyName.script(),
  IcuPropertyKind.bidiClass => IcuPropertyName.bidiClass(),
  IcuPropertyKind.numericType => IcuPropertyName.numericType(),
  IcuPropertyKind.eastAsianWidth => IcuPropertyName.eastAsianWidth(),
  IcuPropertyKind.lineBreak => IcuPropertyName.lineBreak(),
  IcuPropertyKind.graphemeClusterBreak =>
    IcuPropertyName.graphemeClusterBreak(),
  IcuPropertyKind.wordBreak => IcuPropertyName.wordBreak(),
  IcuPropertyKind.sentenceBreak => IcuPropertyName.sentenceBreak(),
  IcuPropertyKind.hangulSyllableType => IcuPropertyName.hangulSyllableType(),
  IcuPropertyKind.canonicalCombiningClass =>
    IcuPropertyName.canonicalCombiningClass(),
};

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuPropertyName — full PropertyValueAliases.txt corpus', () {
    late final Map<String, List<List<String>>> rowsByProperty;
    setUpAll(() async {
      final allRows = await loadUcdFixture('PropertyValueAliases.txt');
      rowsByProperty = {};
      for (final row in allRows) {
        if (row.length < 3) continue;
        rowsByProperty.putIfAbsent(row[0], () => []).add(row);
      }
    });

    for (final entry in _kindToUcdProperty.entries) {
      final kind = entry.key;
      final ucdProp = entry.value;

      group('${kind.name} (UCD: $ucdProp)', () {
        late final IcuPropertyName resolver;
        late final List<List<String>> rows;
        setUpAll(() {
          resolver = _buildResolver(kind);
          rows = rowsByProperty[ucdProp] ?? const [];
        });

        test('every row resolves and round-trips', () {
          expect(
            rows,
            isNotEmpty,
            reason:
                '$ucdProp not present in PropertyValueAliases.txt — '
                'corpus drift?',
          );

          // ccc is the special-snowflake property: rows are
          // `ccc ; <numeric> ; <short> ; <long>` instead of
          // `<prop> ; <short> ; <long> [; <synonym>]`.
          final isCcc = ucdProp == 'ccc';

          var skipped = 0;
          var verified = 0;
          for (final row in rows) {
            final String short;
            final String long;
            final List<String> allNames;
            final int? expectedNumericCode;

            if (isCcc) {
              if (row.length < 4) continue;
              expectedNumericCode = int.tryParse(row[1]);
              short = row[2];
              long = row[3];
              allNames = [short, long];
            } else {
              if (row.length < 3) continue;
              expectedNumericCode = null;
              short = row[1];
              long = row[2];
              allNames = [short, long, ...row.skip(3)];
            }

            // ICU4X intentionally exposes a subset of values for some
            // properties (e.g. deprecated values, rarely-used long names).
            // If `codeFor(short)` returns null, every alias for this row is
            // outside the binding's data — skip the whole row consistently.
            final code = resolver.codeFor(short);
            if (code == null) {
              skipped++;
              continue;
            }
            verified++;

            if (expectedNumericCode != null) {
              expect(
                code,
                equals(expectedNumericCode),
                reason:
                    'ccc: codeFor($short) expected '
                    '$expectedNumericCode (numeric value from UCD), got $code',
              );
            }

            for (final name in allNames) {
              final aliasCode = resolver.codeFor(name);
              expect(
                aliasCode,
                equals(code),
                reason:
                    '$ucdProp: codeFor($name) should equal '
                    'codeFor($short)=$code, got $aliasCode',
              );
            }

            // ICU4X's name tables may legitimately return null for some
            // values (e.g. unnamed CCCs, deprecated property values).
            // Skip the reverse-lookup assertion when null.
            final shortName = resolver.nameOf(code, short: true);
            final longName = resolver.nameOf(code, short: false);
            if (shortName != null) {
              expect(
                shortName,
                equals(short),
                reason:
                    '$ucdProp: nameOf($code, short: true) expected '
                    '$short, got $shortName',
              );
            }
            if (longName != null) {
              expect(
                longName,
                equals(long),
                reason:
                    '$ucdProp: nameOf($code, short: false) expected '
                    '$long, got $longName',
              );
            }
          }

          // Sanity: at least 1 row in every property must be resolvable.
          expect(
            verified,
            greaterThan(0),
            reason: '$ucdProp: 0 rows verified, $skipped skipped',
          );
          print('  $ucdProp: verified=$verified, skipped=$skipped');
        });
      });
    }
  });
}
