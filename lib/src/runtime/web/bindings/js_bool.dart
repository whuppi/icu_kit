// Shared bool decoder for the mirrors. Diplomat-JS returns booleans as
// real JS booleans on some paths and as numbers (0/1) on others — accept
// both. Deliberately NOT exported by the barrel: this is mirror plumbing,
// not part of the binding surface.
import 'dart:js_interop';

/// Decode a Diplomat-JS boolean, accepting both JS booleans and 0/1
/// numbers; null reads as false.
bool readJsBool(JSAny? raw) {
  if (raw == null) return false;
  if (raw.isA<JSBoolean>()) return (raw as JSBoolean).toDart;
  if (raw.isA<JSNumber>()) return (raw as JSNumber).toDartInt != 0;
  return false;
}
