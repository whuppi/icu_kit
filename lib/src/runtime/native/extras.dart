// Uniform accessors over the generated native bindings, mirrored by the
// same-named members on the web mirrors. Facades use these instead of
// Object members (extension types can't declare toString and friends).
import 'bindings/lib.g.dart';

/// String rendering for the FFI `Locale` (extension types can't
/// declare `toString` and friends).
extension LocaleBcp47 on Locale {
  /// The normalized BCP-47 tag (the binding's own string rendering).
  String get asBcp47 => toString();
}
