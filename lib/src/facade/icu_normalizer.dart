import '../runtime/bindings.dart' as icu;
import '../errors/icu_error.dart';
import '../runtime/dispatch.dart' as dispatch;

/// Unicode normalization — STABLE.
///
/// Replaces Dart's missing `String.normalize(form)` (JavaScript has it,
/// Dart doesn't). Pick a form at construction; [normalize] applies it.
///
/// Example:
///
/// ```dart
/// final nfc = IcuNormalizer(IcuNormalizationForm.nfc);
/// nfc.normalize('e\u{0301}');  // "é" (precomposed)
///
/// final nfd = IcuNormalizer(IcuNormalizationForm.nfd);
/// nfd.normalize('é');           // "e\u{0301}" (decomposed)
///
/// final nfkc = IcuNormalizer(IcuNormalizationForm.nfkc);
/// nfkc.normalize('ﬁ');          // "fi" (ligature → letters)
/// ```
final class IcuNormalizer {
  IcuNormalizer._composing(this._composing, this._kind) : _decomposing = null;

  IcuNormalizer._decomposing(this._decomposing, this._kind) : _composing = null;

  /// Construct a normalizer for [form].
  factory IcuNormalizer(IcuNormalizationForm form) {
    try {
      return switch (form) {
        IcuNormalizationForm.nfc => IcuNormalizer._composing(
          dispatch.composingNormalizerNfc(),
          _NormalizerKind.nfc,
        ),
        IcuNormalizationForm.nfkc => IcuNormalizer._composing(
          dispatch.composingNormalizerNfkc(),
          _NormalizerKind.nfkc,
        ),
        IcuNormalizationForm.nfd => IcuNormalizer._decomposing(
          dispatch.decomposingNormalizerNfd(),
          _NormalizerKind.nfd,
        ),
        IcuNormalizationForm.nfkd => IcuNormalizer._decomposing(
          dispatch.decomposingNormalizerNfkd(),
          _NormalizerKind.nfkd,
        ),
      };
    } catch (e) {
      if (e is IcuUnsupportedError) rethrow; // engine gap, not missing data
      throw IcuDataError(
        'Normalizer unavailable for ${form.name}: $e',
        marker: 'Normalizer.${form.name}',
      );
    }
  }
  final _NormalizerKind _kind;
  final icu.ComposingNormalizer? _composing;
  final icu.DecomposingNormalizer? _decomposing;

  /// Normalize [s] under this form.
  ///
  /// Returns the normalized string. For input that is already normalized,
  /// the result equals the input (this is a no-op fast path inside
  /// ICU4X).
  String normalize(String s) {
    final composing = _composing;
    if (composing != null) return composing.normalize(s);
    return _decomposing!.normalize(s);
  }

  /// True if [s] is already in this form.
  bool isNormalized(String s) {
    final composing = _composing;
    if (composing != null) return composing.isNormalized(s);
    return _decomposing!.isNormalized(s);
  }

  /// Returns the index up to which [s] is already normalized. If the
  /// entire string is normalized, returns `s.length`. Otherwise returns
  /// the first index that needs work.
  int isNormalizedUpTo(String s) {
    final composing = _composing;
    if (composing != null) return composing.isNormalizedUpTo(s);
    return _decomposing!.isNormalizedUpTo(s);
  }

  /// Which form this normalizer applies.
  IcuNormalizationForm get form => switch (_kind) {
    _NormalizerKind.nfc => IcuNormalizationForm.nfc,
    _NormalizerKind.nfkc => IcuNormalizationForm.nfkc,
    _NormalizerKind.nfd => IcuNormalizationForm.nfd,
    _NormalizerKind.nfkd => IcuNormalizationForm.nfkd,
  };
}

/// Unicode normalization form (UAX #15).
///
///   * `nfc` — Canonical Composition (the most common form for storage)
///   * `nfd` — Canonical Decomposition
///   * `nfkc` — Compatibility Composition (also normalizes ligatures,
///              superscripts, etc.)
///   * `nfkd` — Compatibility Decomposition
enum IcuNormalizationForm {
  /// Canonical Composition — the most common form for storage.
  nfc,

  /// Canonical Decomposition.
  nfd,

  /// Compatibility Composition (also normalizes ligatures,
  /// superscripts, etc.).
  nfkc,

  /// Compatibility Decomposition.
  nfkd,
}

enum _NormalizerKind { nfc, nfd, nfkc, nfkd }
