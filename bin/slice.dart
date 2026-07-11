// Slice CLDR data into postcards loadable by IcuKit at runtime.
//
// This is a thin wrapper around `icu4x-datagen` that adds three things
// over the raw CLI:
//
//   1. `--markers` presets that map icu_kit's facade families to markers,
//      so you write `--markers=format-core` instead of naming 14 markers.
//      Presets (see lib/src/hook/marker_presets.dart for the exact sets):
//        format-core      numbers, plurals, Gregorian dates/times, IDNA
//        format-extended  + currency, percent, units, relative-time, lists
//        text             segmentation, case, normalization, bidi, properties
//        locale           collation, display names, fallback, direction
//        kit              the union of the above (everything the example uses)
//        all              every marker (default; heavy — 7 MB+ per locale)
//      Or pass a comma-separated list of exact marker names.
//
//   2. --per-locale mode: emit one .postcard per locale (rather than a
//      single multi-locale blob). Pair with `IcuKit.init(data:
//      IcuData.lazy(IcuDataSource.assets(...)))` to load on demand.
//
//   3. Default --out path of `assets/icu/` matching IcuDataSource.assets's
//      default prefix.
//
// Usage from the consuming Flutter app's directory:
//
//   # per-locale postcards, trimmed to the formatting facades (~100 KB each)
//   dart run icu_kit:slice --locales=en,fr,ja --markers=format-core --per-locale
//   # → assets/icu/en.postcard, assets/icu/fr.postcard, assets/icu/ja.postcard
//
//   # one blob covering 3 locales (load via IcuDataSource.bytes once at startup)
//   dart run icu_kit:slice --locales=en,fr,ja --markers=format-core
//   # → assets/icu/app_data.postcard
//
//   # exact markers, when you know precisely what you need
//   dart run icu_kit:slice --locales=en --markers=DecimalSymbolsV1,PluralsCardinalV1
//
// Then in your Flutter app:
//
//   import 'package:flutter/services.dart' show rootBundle;
//   import 'package:icu_kit/icu_kit.dart';
//
//   await IcuKit.init(data: IcuData.lazy(
//     IcuDataSource.assets(load: rootBundle.load),
//   ));
//
// And add `assets/icu/` to your pubspec.yaml's flutter assets entry.
//
// Requires the vendored icu4x submodule (datagen runs from it); a pub.dev
// consumer without the submodule cannot slice — use a git checkout.

import 'dart:io';

import 'package:icu_kit/src/hook/marker_presets.dart';
import 'package:package_config/package_config.dart';

const _datagenBin = 'icu4x-datagen';

/// Default marker set. `all` is complete but heavy (7 MB+ per locale);
/// most apps want a preset — see `--markers` in the usage.
const _defaultMarkers = 'all';

void main(List<String> args) async {
  final parsed = _parseArgs(args);
  if (parsed == null) {
    _printUsage();
    exit(2);
  }

  final pkgRoot = await _resolveIcuKitPackageRoot();
  final submodule = Directory.fromUri(pkgRoot.resolve('vendor/icu4x/'));
  if (!File('${submodule.path}/Cargo.lock').existsSync()) {
    stderr.writeln('Missing vendor/icu4x submodule at ${submodule.path}.');
    stderr.writeln('From the icu_kit package directory:');
    stderr.writeln('  git submodule update --init');
    exit(1);
  }

  final perLocale = parsed['per-locale'] == 'true';
  final outDir = Directory(parsed['out']!);
  outDir.createSync(recursive: true);
  final locales = parsed['locales']!.split(',');

  // Resolve the marker spec (preset name / 'all' / exact comma list) to
  // concrete datagen marker names, once. A bad preset name fails here,
  // before any (slow) datagen run.
  final List<String> markers;
  try {
    markers = resolveMarkerSpec(parsed['markers']!, submodule);
  } on StateError catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('Valid presets: ${markerPresetNames.join(', ')}');
    stderr.writeln('(or a comma-separated list of exact marker names)');
    exit(2);
  }

  if (perLocale) {
    print('Building $_datagenBin (cached after first run)...');
    for (final locale in locales) {
      final outFile = File('${outDir.path}/$locale.postcard');
      print('  → $locale');
      await _runDatagen(
        submodule: submodule,
        locales: [locale],
        markers: markers,
        out: outFile.absolute.path,
      );
    }
    print('');
    print('Wrote ${locales.length} per-locale postcards under ${outDir.path}');
    print('');
    print('Load at runtime:');
    print("  import 'package:flutter/services.dart' show rootBundle;");
    print("  import 'package:icu_kit/icu_kit.dart';");
    print('');
    print('  await IcuKit.init(data: IcuData.lazy(');
    print('    IcuDataSource.assets(load: rootBundle.load),');
    print('  ));');
    print('');
    print("Add to pubspec.yaml's flutter.assets:");
    print('  - ${outDir.path}/');
  } else {
    final outFile = File('${outDir.path}/app_data.postcard');
    print('Building $_datagenBin (cached after first run)...');
    await _runDatagen(
      submodule: submodule,
      locales: locales,
      markers: markers,
      out: outFile.absolute.path,
    );
    final size = outFile.statSync().size;
    final kb = (size / 1024).toStringAsFixed(1);
    print('');
    print('Wrote ${outFile.path} ($kb KB)');
    print('');
    print('Load at runtime:');
    print("  import 'package:flutter/services.dart' show rootBundle;");
    print("  import 'package:icu_kit/icu_kit.dart';");
    print('');
    print("  final bytes = await rootBundle.load('${outFile.path}');");
    print('  await IcuKit.init(data: IcuData.lazy(');
    print('    IcuDataSource.bytes(bytes.buffer),');
    print('  ));');
  }
}

Future<void> _runDatagen({
  required Directory submodule,
  required List<String> locales,
  required List<String> markers,
  required String out,
}) async {
  // Datagen refuses to overwrite an existing file; delete stale output
  // first (same shape as tool/regen_test_postcards.dart, the proven
  // invocation).
  final stale = File(out);
  if (stale.existsSync()) stale.deleteSync();

  // Locales and markers MUST be separate argv entries — datagen does NOT
  // parse comma-joined values (a single `--markers A,B` arg makes it panic).
  // `--features=unstable` registers the icu_experimental markers
  // (currency / percent / unit / relative-time) icu_kit exposes.
  final cargo = await Process.start('cargo', [
    'run',
    '--release',
    '--features=unstable',
    '--manifest-path',
    '${submodule.path}/provider/icu4x-datagen/Cargo.toml',
    '--',
    '--locales',
    ...locales,
    '--markers',
    ...markers,
    '--format',
    'blob',
    '--out',
    out,
  ], mode: ProcessStartMode.inheritStdio);
  final code = await cargo.exitCode;
  if (code != 0) {
    stderr.writeln('icu4x-datagen failed with exit code $code.');
    exit(code);
  }
}

Map<String, String>? _parseArgs(List<String> args) {
  String? locales;
  String markers = _defaultMarkers;
  String out = 'assets/icu';
  bool perLocale = false;
  for (final arg in args) {
    if (arg.startsWith('--locales=')) {
      locales = arg.substring('--locales='.length);
    } else if (arg.startsWith('--markers=')) {
      markers = arg.substring('--markers='.length);
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
    } else if (arg == '--per-locale') {
      perLocale = true;
    } else if (arg == '--help' || arg == '-h') {
      return null;
    } else {
      stderr.writeln('Unknown argument: $arg');
      return null;
    }
  }
  if (locales == null) {
    stderr.writeln('Missing required --locales=<list>');
    return null;
  }
  return {
    'locales': locales,
    'markers': markers,
    'out': out,
    'per-locale': perLocale ? 'true' : 'false',
  };
}

void _printUsage() {
  stderr.writeln('Usage: dart run icu_kit:slice [options]');
  stderr.writeln('');
  stderr.writeln('Required:');
  stderr.writeln('  --locales=<locale>[,<locale>...]   Locales to include');
  stderr.writeln('');
  stderr.writeln('Optional:');
  stderr.writeln(
    '  --markers=<preset|names>    Preset name, "all" (default), or a',
  );
  stderr.writeln(
    '                              comma-separated list of exact markers.',
  );
  stderr.writeln(
    '                              Presets: '
    '${markerPresetNames.join(', ')}',
  );
  stderr.writeln(
    '  --out=<dir>                 Output directory (default: assets/icu)',
  );
  stderr.writeln('  --per-locale                Emit one .postcard per locale');
  stderr.writeln('');
  stderr.writeln('Examples:');
  stderr.writeln(
    '  dart run icu_kit:slice --locales=en,fr,ja --markers=format-core --per-locale',
  );
  stderr.writeln(
    '  dart run icu_kit:slice --locales=en --markers=DecimalSymbolsV1,PluralsCardinalV1',
  );
  stderr.writeln('');
  stderr.writeln('Presets map facade families to markers; see');
  stderr.writeln('lib/src/hook/marker_presets.dart for the exact sets.');
}

Future<Uri> _resolveIcuKitPackageRoot() async {
  final config = await findPackageConfig(Directory.current);
  if (config == null) {
    throw StateError(
      'No .dart_tool/package_config.json found. Run `dart pub get` or '
      '`flutter pub get` first.',
    );
  }
  for (final pkg in config.packages) {
    if (pkg.name == 'icu_kit') return pkg.root;
  }
  throw StateError(
    'icu_kit not found in package_config.json. Add it to pubspec.yaml '
    'and run `flutter pub get`.',
  );
}
