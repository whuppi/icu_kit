// CHARTER — this suite alone proves what the header below declares,
// on BOTH worlds (the VM and Chrome — the -p flag is the runner;
// lib's conditional exports pick the world): icuDataProvider takes a postcard blob produced by `dart run
// icu_kit:datagen`. Generating real test fixtures requires running
// icu4x-datagen (a Rust build), so the test focuses on the API contract
// rather than functional decoding.

// Diet: the public facade + literals declared in this file.
import 'dart:typed_data';

import 'package:icu_kit/icu_kit.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    IcuKit.moduleUrl = '../../web_assets/lib/index.mjs';
    await IcuKit.init();
  });

  group('IcuDataProvider — invalid blob fails loud', () {
    test('empty buffer throws IcuDataError', () {
      // ICU4X validates the blob's magic bytes; empty input fails.
      final empty = Uint8List(0).buffer;
      expect(
        () => IcuDataProvider.fromBytes(empty),
        throwsA(isA<IcuDataError>()),
      );
    });

    test('garbage bytes throw IcuDataError', () {
      final garbage = Uint8List.fromList(List.filled(64, 0xFF)).buffer;
      expect(
        () => IcuDataProvider.fromBytes(garbage),
        throwsA(isA<IcuDataError>()),
      );
    });
  });
}
