// Mirror of the native `DataProvider` binding's `fromByteSlice` factory
// over the Diplomat JS `DataProvider` class.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import '../init.dart';

/// Web mirror of the FFI `DataProvider`.
extension type DataProvider._(JSObject _self) implements JSObject {
  /// Construct from a postcard blob's bytes.
  factory DataProvider.fromByteSlice(ByteBuffer blob) {
    final cls = IcuKit.module.getProperty<JSObject>('DataProvider'.toJS);
    return DataProvider._(
      cls.callMethod<JSObject>('fromByteSlice'.toJS, blob.asUint8List().toJS),
    );
  }
}
