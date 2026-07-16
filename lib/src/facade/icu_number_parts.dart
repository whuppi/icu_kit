import '../runtime/bindings.dart' as icu;

/// One typed piece of a formatted number, mirroring an element of ECMA-402
/// `Intl.NumberFormat.prototype.formatToParts`.
///
/// Concatenating every part's [value] in order reproduces the plain formatted
/// string exactly (the reconstruction invariant).
final class IcuNumberPart {
  /// Creates a part with its typed [type], raw wire [rawType], and [value].
  const IcuNumberPart({
    required this.type,
    required this.rawType,
    required this.value,
  });

  /// The typed part kind. [IcuNumberPartType.other] when the engine reported a
  /// name this version doesn't model — the wire name is then in [rawType].
  final IcuNumberPartType type;

  /// The wire type string exactly as the engine reported it (`"integer"`,
  /// `"group"`, …). Always populated; for a recognized [type] it is that
  /// type's canonical name, and for [IcuNumberPartType.other] it carries the
  /// unrecognized name so nothing is lost.
  final String rawType;

  /// The substring of the formatted output this part covers.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is IcuNumberPart &&
      other.type == type &&
      other.rawType == rawType &&
      other.value == value;

  @override
  int get hashCode => Object.hash(type, rawType, value);

  @override
  String toString() => 'IcuNumberPart($rawType: "$value")';
}

/// The kind of an [IcuNumberPart], mirroring ECMA-402's `formatToParts` part
/// types. [other] is the escape hatch for a future engine/spec type this
/// version doesn't know — its wire name is preserved in [IcuNumberPart.rawType].
enum IcuNumberPartType {
  /// A run of integer digits (between grouping separators).
  integer,

  /// A grouping separator (thousands separator).
  group,

  /// The decimal separator.
  decimal,

  /// The fractional digits after the decimal separator.
  fraction,

  /// The minus sign of a negative value.
  minusSign,

  /// The plus sign of a positive value (explicit-sign display).
  plusSign,

  /// The percent sign of a percent-formatted value.
  percentSign,

  /// The approximately sign (`~`) of an approximate percent display.
  approximatelySign,

  /// The currency symbol or name.
  currency,

  /// The unit name or symbol.
  unit,

  /// The compact-notation abbreviation ("M", "million").
  compact,

  /// Literal text between typed parts (spaces, punctuation).
  literal,

  /// A part type this version doesn't recognize. See [IcuNumberPart.rawType].
  other;

  /// Map a wire type string to its enum value; unknown names become [other].
  static IcuNumberPartType fromRawType(String raw) => switch (raw) {
    'integer' => integer,
    'group' => group,
    'decimal' => decimal,
    'fraction' => fraction,
    'minusSign' => minusSign,
    'plusSign' => plusSign,
    'percentSign' => percentSign,
    'approximatelySign' => approximatelySign,
    'currency' => currency,
    'unit' => unit,
    'compact' => compact,
    'literal' => literal,
    _ => other,
  };
}

/// Convert an FFI [icu.FormattedNumberParts] into the public part list.
/// Shared by every number facade's `formatToParts`. Internal — the FFI type is
/// the bindings seam, not public API.
List<IcuNumberPart> partsToList(icu.FormattedNumberParts ffi) {
  final count = ffi.partCount;
  final parts = <IcuNumberPart>[];
  for (var i = 0; i < count; i++) {
    // In-bounds by construction, so the accessors never return null.
    final rawType = ffi.partTypeAt(i)!;
    final value = ffi.partValueAt(i)!;
    parts.add(
      IcuNumberPart(
        type: IcuNumberPartType.fromRawType(rawType),
        rawType: rawType,
        value: value,
      ),
    );
  }
  return parts;
}
