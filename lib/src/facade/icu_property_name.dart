import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// Property-value name ↔ code resolver — STABLE.
///
/// Most common use: resolve a script name like `"Latin"` or `"Cyrillic"`
/// to the numeric code that `IcuScriptMap.get` returns, OR resolve a
/// numeric code back to its name.
///
/// Example:
///
/// ```dart
/// final scripts = IcuPropertyName.script();
/// final latin = scripts.codeFor('Latin');           // some int (e.g. 0)
/// final cyrillic = scripts.codeFor('Cyrillic');     // some int
///
/// final map = IcuScriptMap();
/// map.get(0x41) == latin;       // true (A is Latin)
/// map.get(0x0410) == cyrillic;  // true (А is Cyrillic)
///
/// // Reverse: numeric code → name
/// scripts.nameOf(latin);        // "Latin" (long), or "Latn" via shortName
/// ```
final class IcuPropertyName {
  IcuPropertyName._(this._ffi, this.kind);

  factory IcuPropertyName._build(
    IcuPropertyKind kind,
    icu.PropertyValueNameToEnumMapper Function() build,
  ) {
    try {
      return IcuPropertyName._(build(), kind);
    } catch (e) {
      throw IcuDataError(
        'Property name resolver unavailable for ${kind.name}: $e',
        marker: 'PropertyValueNameToEnumMapper.${kind.name}',
      );
    }
  }

  /// Resolver for the `Script` property's values.
  factory IcuPropertyName.script() => IcuPropertyName._build(
    IcuPropertyKind.script,
    () => dispatch.propertyValueNameToEnumMapperScript(),
  );

  /// Resolver for the `Bidi_Class` property's values.
  factory IcuPropertyName.bidiClass() => IcuPropertyName._build(
    IcuPropertyKind.bidiClass,
    () => dispatch.propertyValueNameToEnumMapperBidiClass(),
  );

  /// Resolver for the `Numeric_Type` property's values.
  factory IcuPropertyName.numericType() => IcuPropertyName._build(
    IcuPropertyKind.numericType,
    () => dispatch.propertyValueNameToEnumMapperNumericType(),
  );

  /// Resolver for the `East_Asian_Width` property's values.
  factory IcuPropertyName.eastAsianWidth() => IcuPropertyName._build(
    IcuPropertyKind.eastAsianWidth,
    () => dispatch.propertyValueNameToEnumMapperEastAsianWidth(),
  );

  /// Resolver for the `Line_Break` property's values.
  factory IcuPropertyName.lineBreak() => IcuPropertyName._build(
    IcuPropertyKind.lineBreak,
    () => dispatch.propertyValueNameToEnumMapperLineBreak(),
  );

  /// Resolver for the `Grapheme_Cluster_Break` property's values.
  factory IcuPropertyName.graphemeClusterBreak() => IcuPropertyName._build(
    IcuPropertyKind.graphemeClusterBreak,
    () => dispatch.propertyValueNameToEnumMapperGraphemeClusterBreak(),
  );

  /// Resolver for the `Word_Break` property's values.
  factory IcuPropertyName.wordBreak() => IcuPropertyName._build(
    IcuPropertyKind.wordBreak,
    () => dispatch.propertyValueNameToEnumMapperWordBreak(),
  );

  /// Resolver for the `Sentence_Break` property's values.
  factory IcuPropertyName.sentenceBreak() => IcuPropertyName._build(
    IcuPropertyKind.sentenceBreak,
    () => dispatch.propertyValueNameToEnumMapperSentenceBreak(),
  );

  /// Resolver for the `Hangul_Syllable_Type` property's values.
  factory IcuPropertyName.hangulSyllableType() => IcuPropertyName._build(
    IcuPropertyKind.hangulSyllableType,
    () => dispatch.propertyValueNameToEnumMapperHangulSyllableType(),
  );

  /// Resolver for the `Canonical_Combining_Class` property's values.
  factory IcuPropertyName.canonicalCombiningClass() => IcuPropertyName._build(
    IcuPropertyKind.canonicalCombiningClass,
    () => dispatch.propertyValueNameToEnumMapperCanonicalCombiningClass(),
  );
  final icu.PropertyValueNameToEnumMapper _ffi;

  /// Which property's value space this resolver covers.
  final IcuPropertyKind kind;

  /// Resolve [name] (case-sensitive long or short form) to a numeric
  /// code. Returns null if the name isn't recognized.
  int? codeFor(String name) {
    final result = _ffi.getStrict(name);
    return result < 0 ? null : result;
  }

  /// Resolve [name] (case-insensitive, ignore underscores/spaces) to a
  /// numeric code. Returns null if the name isn't recognized.
  int? codeForLoose(String name) {
    final result = _ffi.getLoose(name);
    return result < 0 ? null : result;
  }

  /// Resolve a numeric [code] back to its name.
  ///
  /// Returns `null` if [code] doesn't correspond to a defined property
  /// value, OR if CLDR's name tables for this property don't include
  /// the value in the current data set. With [short] = true, returns
  /// the abbreviated form (e.g. `"Latn"` for Script Latin); otherwise
  /// returns the long form (e.g. `"Latin"`).
  String? nameOf(int code, {bool short = false}) {
    switch (kind) {
      case IcuPropertyKind.script:
        final v = icu.Script.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.bidiClass:
        final v = icu.BidiClass.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.numericType:
        final v = icu.NumericType.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.eastAsianWidth:
        final v = icu.EastAsianWidth.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.lineBreak:
        final v = icu.LineBreak.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.graphemeClusterBreak:
        final v = icu.GraphemeClusterBreak.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.wordBreak:
        final v = icu.WordBreak.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.sentenceBreak:
        final v = icu.SentenceBreak.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.hangulSyllableType:
        final v = icu.HangulSyllableType.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
      case IcuPropertyKind.canonicalCombiningClass:
        final v = icu.CanonicalCombiningClass.fromIntegerValue(code);
        return v == null ? null : (short ? v.shortName() : v.longName());
    }
  }
}

/// Which property's value space this resolver covers.
enum IcuPropertyKind {
  /// UCD `Script`.
  script,

  /// UCD `Bidi_Class`.
  bidiClass,

  /// UCD `Numeric_Type`.
  numericType,

  /// UCD `East_Asian_Width`.
  eastAsianWidth,

  /// UCD `Line_Break`.
  lineBreak,

  /// UCD `Grapheme_Cluster_Break`.
  graphemeClusterBreak,

  /// UCD `Word_Break`.
  wordBreak,

  /// UCD `Sentence_Break`.
  sentenceBreak,

  /// UCD `Hangul_Syllable_Type`.
  hangulSyllableType,

  /// UCD `Canonical_Combining_Class`.
  canonicalCombiningClass,
}
