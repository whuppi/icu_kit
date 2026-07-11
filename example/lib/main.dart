// icu_kit example app — every facade family behind a live locale picker.
//
// Pick a locale in the app bar and watch numbers, dates, plurals, lists,
// and display names re-render in that culture's shape. The Text tab covers
// the Unicode machinery (segmentation, case mapping, normalization, bidi,
// IDNA), the Locale tab the locale algebra (parse, expand, fallback,
// direction, collation), and the Data tab the binary-size dial (bundled
// subsets, rejection of uncovered locales, restore).
//
// The whole app lives in this one file because pub.dev renders it on the
// package's Example tab — splitting it would hide everything else from
// that page. The journey tests drive this exact UI through the real
// engine (suites shared via ../test_support/); the integration smoke
// exercises the same surfaces programmatically on real targets.
//
// ONE app, BOTH binary flavors. The code never declares a flavor — it
// asks `IcuKit.hasCompiledData` (the runtime probe) and adapts: on the
// bundled binary the compiled CLDR serves everything; on the lean binary
// (see ../../example_lean/, which runs THIS app under the lean pubspec
// switch) locale data loads from asset postcards on demand, so locale
// switching preloads asynchronously with a progress state.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:icu_kit/icu_kit.dart';

/// The locale strip's choices — also the set the lean shell slices
/// postcards for (see example_lean/README.md).
const exampleLocales = [
  'en-US',
  'de',
  'fr',
  'hi',
  'ja',
  'ar',
  'th',
  'sv',
  'tr',
  'zh-Hant',
];

/// Locales whose data the app shows in FIXED showcase rows, independent of
/// the picked locale: Thai word segmentation, Turkish (İ) and German (ß)
/// casing, Swedish (å/ö-after-z) collation. On the lean binary these must
/// be loaded up front — the locale strip then demonstrates on-demand
/// loading for every OTHER locale (hi, ja, ar, …) with a per-chip spinner.
const _showcaseLocales = ['th', 'tr', 'de', 'sv'];

/// One bootstrap for BOTH binary flavors — the app's `main()` and the
/// shared journey suites call this same function.
///
/// The composite reads naturally on each flavor: on the bundled binary
/// the bundled tier serves every locale and the lazy tier stays cold
/// (never preloaded, never fetched); on the lean binary the bundled tier
/// is empty and postcards serve. `und` carries the locale-independent
/// data (case mapping, normalization, bidi, properties, segmenter
/// dictionaries) that every locale-free facade dispatches through.
Future<void> initExampleIcu() async {
  await IcuKit.init(
    data: IcuData.composite([
      const BundledIcuData(),
      IcuData.lazy(IcuDataSource.assets(load: rootBundle.load)),
    ]),
  );
  if (!IcuKit.hasCompiledData) {
    // Load the always-on data: und + the initial strip locale + the fixed
    // showcase locales. The rest load lazily as the user picks them.
    for (final l in ['und', exampleLocales.first, ..._showcaseLocales]) {
      await IcuKit.preloadLocale(l);
    }
  }
}

Future<void> main() async {
  // One bootstrap step; every facade below is then a cheap locale-pinned
  // factory.
  await initExampleIcu();
  runApp(const IcuKitExampleApp());
}

class IcuKitExampleApp extends StatelessWidget {
  const IcuKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'icu_kit example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// Runs [body] and renders errors as text instead of crashing the demo —
/// uncovered locales surface as `IcuDataError: …` rows, which is itself
/// part of the tour (see the Data tab).
String demo(String Function() body) {
  try {
    return body();
  } on IcuError catch (e) {
    return '${e.runtimeType}';
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const locales = exampleLocales;

  String locale = 'en-US';

  // Lean binary only: the locale whose postcard is currently loading.
  String? localeLoading;

  // Plurals section — interactive count.
  int pluralCount = 1;

  // Text tab — live inputs.
  String segmentInput = 'สวัสดีครับ';
  String caseInput = 'istanbul';
  String bidiInput = 'Hello مرحبا world';
  String idnaAsciiInput = '日本.jp';
  String idnaUnicodeInput = 'xn--mnchen-3ya.de';

  // Locale tab — live inputs.
  String parseInput = 'zh-hant-tw';
  String expandInput = 'sr';

  // Data tab — current configuration + async re-init state.
  String dataStatus = 'Full bundled CLDR data (every locale).';
  bool dataBusy = false;

  static const _sample = 1234567.89;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('icu_kit'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Format'),
              Tab(text: 'Text'),
              Tab(text: 'Locale'),
              Tab(text: 'Data'),
            ],
          ),
        ),
        body: Column(
          children: [
            _localeStrip(),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [_formatTab(), _textTab(), _localeTab(), _dataTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A pinned, horizontally-scrolling strip of locale chips. Every surface
  /// below reacts to the selection. A plain scrollable strip (no overlay
  /// menu) so it stays visible and tappable on the smallest device.
  Widget _localeStrip() {
    return SizedBox(
      height: 48,
      child: ListView(
        key: const Key('locale-strip'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final l in locales)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                key: Key('locale:$l'),
                avatar: localeLoading == l
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                label: Text(l),
                selected: locale == l,
                onSelected: (_) => _pickLocale(l),
              ),
            ),
        ],
      ),
    );
  }

  /// The honest lean-consumer pattern: on the bundled binary a locale
  /// switch is a plain setState; on the lean binary the postcard loads
  /// first (async — the chip shows a spinner), THEN the surfaces
  /// re-render. An uncovered postcard is not a crash: the switch still
  /// happens and every row shows the typed IcuDataError via demo().
  Future<void> _pickLocale(String l) async {
    if (IcuKit.hasCompiledData || l == locale) {
      setState(() => locale = l);
      return;
    }
    setState(() => localeLoading = l);
    try {
      await IcuKit.preloadLocale(l);
    } on IcuError {
      // Missing postcard — the rows render the error, which is the demo.
    }
    if (!mounted) return;
    setState(() {
      localeLoading = null;
      locale = l;
    });
  }

  // ── Format — numbers, plurals, dates, relative time, lists ──────────

  Widget _formatTab() {
    final now = DateTime.now();
    final plural = demo(
      () => IcuPluralRules.cardinal(locale).category(pluralCount).name,
    );
    return ListView(
      key: const ValueKey('surface-list'),
      padding: const EdgeInsets.all(12),
      children: [
        _Section(
          title: 'Numbers',
          children: [
            _DemoRow(
              'decimal — $_sample',
              demo(
                () => IcuNumberFormat.decimal(locale: locale).format(_sample),
              ),
            ),
            _DemoRow(
              'currency — 1999.5 EUR (experimental)',
              demo(
                () => IcuCurrencyFormat.symbol(
                  locale: locale,
                ).format(1999.5, currencyCode: 'EUR'),
              ),
            ),
            _DemoRow(
              'percent — 73.4 (experimental)',
              demo(() => IcuPercentFormat(locale: locale).format(73.4)),
            ),
            _DemoRow(
              'unit — 42 meters (experimental)',
              demo(
                () => IcuUnitFormat(locale: locale, unit: 'meter').format(42),
              ),
            ),
          ],
        ),
        _Section(
          title: 'Plural rules',
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('plural.minus'),
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(
                    () => pluralCount = pluralCount > 0 ? pluralCount - 1 : 0,
                  ),
                ),
                Expanded(
                  child: Text(
                    '$pluralCount → $plural',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  key: const Key('plural.plus'),
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => pluralCount++),
                ),
              ],
            ),
          ],
        ),
        _Section(
          title: 'Dates and times',
          children: [
            _DemoRow(
              'date — ymd',
              demo(() => IcuDateFormat.ymd(locale: locale).format(now)),
            ),
            _DemoRow(
              'time',
              demo(() => IcuTimeFormat(locale: locale).format(now)),
            ),
            _DemoRow(
              'date + time — ymdt',
              demo(() => IcuDateTimeFormat.ymdt(locale: locale).format(now)),
            ),
          ],
        ),
        _Section(
          title: 'Relative time',
          children: [
            for (final (value, label) in const [
              (-1, 'yesterday'),
              (0, 'today'),
              (2, 'in 2 days'),
            ])
              _DemoRow(
                '$value days ($label)',
                demo(
                  () => IcuRelativeTimeFormat(
                    locale: locale,
                    unit: IcuRelativeTimeUnit.day,
                    numeric: IcuRelativeTimeNumeric.auto,
                  ).format(value),
                ),
              ),
          ],
        ),
        _Section(
          title: 'Lists',
          children: [
            _DemoRow(
              'and',
              demo(
                () => IcuListFormat.and(
                  locale: locale,
                ).format(const ['Aria', 'Kael', 'Mira']),
              ),
            ),
            _DemoRow(
              'or',
              demo(
                () => IcuListFormat.or(
                  locale: locale,
                ).format(const ['red', 'green', 'blue']),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Text — segmentation, case, normalization, bidi, IDNA ────────────

  Widget _textTab() {
    final segments = demo(
      () => IcuSegmenter.word(locale: 'th')
          .segments(segmentInput)
          .where((s) => s.text.trim().isNotEmpty)
          .map((s) => s.text)
          .join(' · '),
    );
    final composed = demo(
      () => IcuNormalizer(IcuNormalizationForm.nfc).normalize('e\u{0301}'),
    );
    final direction = demo(
      () => IcuBidi().analyze(bidiInput).paragraph(0)?.direction.name ?? '—',
    );
    return ListView(
      key: const ValueKey('surface-list'),
      padding: const EdgeInsets.all(12),
      children: [
        _Section(
          title: 'Word segmentation (Thai — no spaces)',
          children: [
            _InputRow(
              fieldKey: const Key('segmenter.input'),
              initial: segmentInput,
              onChanged: (v) => setState(() => segmentInput = v),
            ),
            _DemoRow('words', segments),
          ],
        ),
        _Section(
          title: 'Case mapping (locale-aware)',
          children: [
            _InputRow(
              fieldKey: const Key('case.input'),
              initial: caseInput,
              onChanged: (v) => setState(() => caseInput = v),
            ),
            _DemoRow(
              'uppercase — $locale',
              demo(() => IcuCaseMapper().uppercase(caseInput, locale: locale)),
            ),
            _DemoRow(
              "uppercase('istanbul', tr) — dotted İ",
              demo(() => IcuCaseMapper().uppercase('istanbul', locale: 'tr')),
            ),
            _DemoRow(
              "uppercase('straße', de) — ß → SS",
              demo(() => IcuCaseMapper().uppercase('straße', locale: 'de')),
            ),
          ],
        ),
        _Section(
          title: 'Normalization',
          children: [
            _DemoRow(
              'NFC of e + U+0301',
              '$composed  (== é: ${composed == 'é'})',
            ),
          ],
        ),
        _Section(
          title: 'Bidi',
          children: [
            _InputRow(
              fieldKey: const Key('bidi.input'),
              initial: bidiInput,
              onChanged: (v) => setState(() => bidiInput = v),
            ),
            _DemoRow('paragraph direction', direction),
          ],
        ),
        _Section(
          title: 'IDNA — internationalized domains',
          children: [
            _InputRow(
              fieldKey: const Key('idna.ascii.input'),
              initial: idnaAsciiInput,
              onChanged: (v) => setState(() => idnaAsciiInput = v),
            ),
            _DemoRow(
              'toAscii',
              demo(() => IcuIdna.url().toAscii(idnaAsciiInput)),
            ),
            _InputRow(
              fieldKey: const Key('idna.unicode.input'),
              initial: idnaUnicodeInput,
              onChanged: (v) => setState(() => idnaUnicodeInput = v),
            ),
            _DemoRow(
              'toUnicode',
              demo(() => IcuIdna.url().toUnicode(idnaUnicodeInput)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Locale — parse, expand, fallback, direction, names, collation ───

  Widget _localeTab() {
    const names = ['Östen', 'Anna', 'Åsa'];
    final sortedSv = demo(
      () => ([...names]..sort(IcuCollator(locale: 'sv').compare)).join(', '),
    );
    final sortedPicked = demo(
      () => ([...names]..sort(IcuCollator(locale: locale).compare)).join(', '),
    );
    return ListView(
      key: const ValueKey('surface-list'),
      padding: const EdgeInsets.all(12),
      children: [
        _Section(
          title: 'Parse and canonicalize',
          children: [
            _InputRow(
              fieldKey: const Key('parse.input'),
              initial: parseInput,
              onChanged: (v) => setState(() => parseInput = v),
            ),
            _DemoRow(
              'canonical',
              demo(() => IcuLocale.parse(parseInput).toString()),
            ),
          ],
        ),
        _Section(
          title: 'Likely subtags',
          children: [
            _InputRow(
              fieldKey: const Key('expander.input'),
              initial: expandInput,
              onChanged: (v) => setState(() => expandInput = v),
            ),
            _DemoRow(
              'maximize',
              demo(() => IcuLocaleExpander().maximize(expandInput)),
            ),
            _DemoRow(
              'minimize of maximized',
              demo(
                () => IcuLocaleExpander().minimize(
                  IcuLocaleExpander().maximize(expandInput),
                ),
              ),
            ),
          ],
        ),
        _Section(
          title: 'Direction and fallback — $locale',
          children: [
            _DemoRow(
              'direction',
              demo(() => IcuLocaleDirectionality().directionOf(locale).name),
            ),
            _DemoRow(
              'fallback chain',
              demo(
                () => IcuLocaleFallbacker()
                    .chain('$locale-u-ca-buddhist')
                    .take(4)
                    .join(' → '),
              ),
            ),
          ],
        ),
        _Section(
          title: 'Display names — in $locale',
          children: [
            _DemoRow(
              'region DE',
              demo(() => IcuRegionDisplayNames(locale: locale).of('DE')),
            ),
            _DemoRow(
              'region JP',
              demo(() => IcuRegionDisplayNames(locale: locale).of('JP')),
            ),
            _DemoRow(
              'locale fr',
              demo(() => IcuLocaleDisplayNames(locale: locale).of('fr')),
            ),
          ],
        ),
        _Section(
          title: 'Collation',
          children: [
            _DemoRow('Swedish sort (å ö after z)', sortedSv),
            _DemoRow('$locale sort', sortedPicked),
          ],
        ),
      ],
    );
  }

  // ── Data — the binary-size dial ──────────────────────────────────────

  Widget _dataTab() {
    // Probe an uncovered locale. When ja isn't available the row reads
    // 'unavailable' — a stable label whatever the underlying IcuError
    // (IcuDataError when a bundled subset gates it, IcuMissingDataError
    // when a lean binary hasn't loaded its postcard). The point is the
    // same on both: the miss is loud, not a garbled number.
    String probe;
    try {
      probe = IcuNumberFormat.decimal(locale: 'ja').format(_sample);
    } on IcuError {
      probe = 'unavailable';
    }
    return ListView(
      key: const ValueKey('surface-list'),
      padding: const EdgeInsets.all(12),
      children: [
        _Section(
          title: 'Data configuration',
          children: [
            _DemoRow('active', dataStatus),
            _DemoRow('probe — format $_sample as ja', probe),
            const SizedBox(height: 4),
            Text(
              'Loading a two-locale subset re-initializes the WHOLE engine — '
              'every tab then rejects uncovered locales with an IcuError. '
              'That rejection is the feature: ship only the locales you '
              'support, and the miss is loud, not garbled. (On the bundled '
              'binary the subset gates the compiled data; on the lean one '
              'it loads only those postcards.)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  key: const Key('data.subset'),
                  onPressed: dataBusy ? null : () => _reinit(subset: true),
                  child: const Text('Load en + fr subset'),
                ),
                FilledButton.tonal(
                  key: const Key('data.restore'),
                  onPressed: dataBusy ? null : () => _reinit(subset: false),
                  child: const Text('Restore full data'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Same two buttons, both flavors — the STORY is identical (subset
  /// rejects uncovered locales; restore heals), only the mechanism
  /// differs: gate the compiled data on the bundled binary, load only
  /// some postcards on the lean one.
  Future<void> _reinit({required bool subset}) async {
    setState(() => dataBusy = true);
    if (IcuKit.hasCompiledData) {
      await IcuKit.init(
        data: subset
            ? IcuData.bundled(locales: const ['en', 'fr'])
            : const BundledIcuData(),
      );
    } else {
      await IcuKit.init(
        data: IcuData.lazy(IcuDataSource.assets(load: rootBundle.load)),
      );
      for (final l
          in subset ? const ['und', 'en', 'fr'] : ['und', ...exampleLocales]) {
        await IcuKit.preloadLocale(l);
      }
    }
    if (!mounted) return;
    setState(() {
      dataBusy = false;
      dataStatus = switch ((IcuKit.hasCompiledData, subset)) {
        (true, true) => 'Bundled subset: en, fr — every other locale throws.',
        (true, false) => 'Full bundled CLDR data (every locale).',
        (false, true) =>
          'Postcards loaded: en, fr — every other locale '
              'throws.',
        (false, false) => 'Postcards loaded for every example locale.',
      };
    });
  }
}

// ── Layout helpers ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A label above its live value — vertical so no locale's output can
/// overflow the phone-small profile horizontally.
class _DemoRow extends StatelessWidget {
  const _DemoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.fieldKey,
    required this.initial,
    required this.onChanged,
  });

  final Key fieldKey;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: fieldKey,
        initialValue: initial,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
