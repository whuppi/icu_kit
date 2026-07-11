// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): drives Unicode UTS #46's IdnaTestV2.txt corpus through IcuIdna.uts46()
// — the canonical UTS #46 conformance mode (STD3 + CheckHyphens +
// VerifyDNSLength). Mirrors the Rust idna crate's own conformance test
// at idna/tests/uts46.rs (per-row assert; no thresholds).
//
// Format per UTS #46 §6:
//   source; toUnicode; toUnicodeStatus; toAsciiN; toAsciiNStatus; toAsciiT; toAsciiTStatus
//
// Inheritance per UTS #46 §6:
//   blank toUnicode → use source
//   blank toAsciiN → use toUnicode
//   blank toAsciiNStatus → use toUnicodeStatus
//
// Status `[]` or empty = no errors expected.
//
// Conformance contract per row:
//   * If status is [] → idna.toAscii must succeed AND return the
//     expected ASCII string EXACTLY.
//   * If status contains errors → idna.toAscii MUST throw.
//
// Skipped error codes (matching upstream's own test):
//   * X4_2 — UTS46 deviation: empty-label X4_2 errors are reported in
//     toAscii contexts but not toUnicode in some implementations. The
//     Rust idna crate's own test skips these; we follow.
//
// Source: https://www.unicode.org/Public/idna/15.1.0/IdnaTestV2.txt
// (vendored under test/_corpus/ucd/idna/ — see PROVENANCE.md)

// Diet: foreign declared truth — upstream UCD/CLDR/ICU4X fixtures via the corpus loader (PROVENANCE.md); never this package's own output re-derived.
import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

import 'corpus_loader.dart';

String _unescape(String s) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < s.length) {
    if (i + 1 < s.length && s[i] == '\\' && s[i + 1] == 'u') {
      final hex = s.substring(i + 2, i + 6);
      buffer.writeCharCode(int.parse(hex, radix: 16));
      i += 6;
    } else if (i + 2 < s.length &&
        s[i] == '\\' &&
        s[i + 1] == 'x' &&
        s[i + 2] == '{') {
      final closeIdx = s.indexOf('}', i + 3);
      final hex = s.substring(i + 3, closeIdx);
      buffer.writeCharCode(int.parse(hex, radix: 16));
      i = closeIdx + 1;
    } else {
      buffer.write(s[i]);
      i++;
    }
  }
  return buffer.toString();
}

/// Parse `[E1, E2]` style status list. Returns the list of error codes
/// (without surrounding brackets) or empty list for `[]` / blank.
List<String> _parseStatus(String status) {
  final trimmed = status.trim();
  if (trimmed.isEmpty || trimmed == '[]') return const [];
  final stripped = trimmed.replaceAll('[', '').replaceAll(']', '');
  return stripped
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Should this row's expected error be ignored (per upstream's own
/// skip list)?
bool _shouldIgnoreError(List<String> errors) {
  // Upstream idna/tests/uts46.rs only ignores "X4_2".
  return errors.length == 1 && errors[0] == 'X4_2';
}

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuIdna.uts46 — UTS #46 IdnaTestV2.txt conformance corpus', () {
    late final List<List<String>> rows;
    late final IcuIdna uts46;

    setUpAll(() async {
      rows = await loadUcdFixture('idna/IdnaTestV2.txt');
      uts46 = IcuIdna.uts46();
    });

    test('every row matches UTS #46 expected behavior exactly', () {
      expect(rows, isNotEmpty);

      var verifiedSuccess = 0;
      var verifiedFailure = 0;
      var skipped = 0;
      final mismatches = <String>[];

      for (final row in rows) {
        if (row.length < 7) {
          skipped++;
          continue;
        }

        final source = _unescape(row[0]);
        final toUnicode = row[1].isEmpty ? source : _unescape(row[1]);
        final toUnicodeStatus = _parseStatus(row[2]);
        final toAsciiN = row[3].isEmpty ? toUnicode : _unescape(row[3]);
        final toAsciiNStatus = row[4].isEmpty
            ? toUnicodeStatus
            : _parseStatus(row[4]);

        // toAscii — STD3 + Check + Verify path
        if (toAsciiNStatus.isEmpty) {
          // Expected success.
          try {
            final actual = uts46.toAscii(source);
            if (actual != toAsciiN) {
              mismatches.add(
                'toAscii(${row[0]}): UTS46 expects $toAsciiN, '
                'got $actual',
              );
            } else {
              verifiedSuccess++;
            }
          } on IcuIdnaError catch (e) {
            mismatches.add(
              'toAscii(${row[0]}): UTS46 expects $toAsciiN, '
              'threw ${e.kind.name}',
            );
          }
        } else {
          // Expected failure.
          if (_shouldIgnoreError(toAsciiNStatus)) {
            skipped++;
            continue;
          }
          try {
            final actual = uts46.toAscii(source);
            mismatches.add(
              'toAscii(${row[0]}): UTS46 expects error '
              '${toAsciiNStatus.join(", ")}, got $actual',
            );
          } on IcuIdnaError {
            verifiedFailure++;
          }
        }

        // toUnicode — STD3 + Check
        if (toUnicodeStatus.isEmpty) {
          try {
            final actual = uts46.toUnicode(source);
            if (actual != toUnicode) {
              mismatches.add(
                'toUnicode(${row[0]}): UTS46 expects $toUnicode, '
                'got $actual',
              );
            } else {
              verifiedSuccess++;
            }
          } on IcuIdnaError catch (e) {
            mismatches.add(
              'toUnicode(${row[0]}): UTS46 expects $toUnicode, '
              'threw ${e.kind.name}',
            );
          }
        } else {
          if (_shouldIgnoreError(toUnicodeStatus)) {
            skipped++;
            continue;
          }
          try {
            final actual = uts46.toUnicode(source);
            mismatches.add(
              'toUnicode(${row[0]}): UTS46 expects error '
              '${toUnicodeStatus.join(", ")}, got $actual',
            );
          } on IcuIdnaError {
            verifiedFailure++;
          }
        }
      }

      print(
        '  UTS46 conformance: '
        'success=$verifiedSuccess '
        'failure=$verifiedFailure '
        'skipped(X4_2)=$skipped '
        'mismatches=${mismatches.length}',
      );

      if (mismatches.isNotEmpty) {
        for (final m in mismatches.take(20)) {
          print('    $m');
        }
        if (mismatches.length > 20) {
          print('    ... (${mismatches.length - 20} more)');
        }
      }

      expect(
        mismatches,
        isEmpty,
        reason: '${mismatches.length} UTS #46 conformance mismatches',
      );
    });
  });
}
