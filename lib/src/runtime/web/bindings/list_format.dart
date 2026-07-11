// Mirror of the native `ListFormatter` binding plus the `ListLength`
// enum, over the Diplomat JS `ListFormatter` class.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../init.dart';

/// Web mirror of the FFI `ListFormatter`.
extension type ListFormatter._(JSObject _self) implements JSObject {
  /// Wrap a raw JS handle yielded by dispatch.
  factory ListFormatter.fromDispatch(JSObject o) = ListFormatter._;

  /// Join [items] with locale list patterns (e.g. "a, b, and c" in
  /// en-US).
  String format(List<String> items) {
    final jsArray = items.map((s) => s.toJS).toList().toJS;
    return _self.callMethod<JSString>('format'.toJS, jsArray).toDart;
  }
}

/// Web mirror of the FFI `ListLength` enum.
enum ListLength {
  /// Full conjunction (e.g. "a, b, and c" in en-US).
  wide,

  /// Abbreviated conjunction (e.g. "a, b, & c" in en-US).
  short,

  /// Separators only (e.g. "a, b, c").
  narrow;

  /// The JS enum value for this length.
  JSObject toJs() {
    final cls = IcuKit.module.getProperty<JSObject>('ListLength'.toJS);
    return cls.getProperty<JSObject>(switch (this) {
      ListLength.wide => 'Wide'.toJS,
      ListLength.short => 'Short'.toJS,
      ListLength.narrow => 'Narrow'.toJS,
    });
  }
}
