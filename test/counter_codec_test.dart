import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zenoh_counter_dart/counter_codec.dart';

void main() {
  group('encodeCounter', () {
    test('produces 8-byte little-endian int64 for value 42', () {
      final bytes = encodeCounter(42);
      expect(bytes.length, equals(8));
      // 42 in little-endian int64: 0x2A, 0, 0, 0, 0, 0, 0, 0
      expect(bytes, equals(Uint8List.fromList([42, 0, 0, 0, 0, 0, 0, 0])));
    });

    test('with zero returns 8 bytes of all zeros', () {
      final bytes = encodeCounter(0);
      expect(bytes.length, equals(8));
      expect(bytes, equals(Uint8List(8)));
    });

    test('with max int64 (0x7FFFFFFFFFFFFFFF) returns correct 8-byte LE', () {
      final bytes = encodeCounter(0x7FFFFFFFFFFFFFFF);
      expect(bytes.length, equals(8));
      expect(
        bytes,
        equals(
          Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F]),
        ),
      );
    });

    test('with negative value (-1) returns 8 bytes of 0xFF', () {
      final bytes = encodeCounter(-1);
      expect(bytes.length, equals(8));
      expect(
        bytes,
        equals(
          Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
        ),
      );
    });
  });

  group('decodeCounter', () {
    test('parses 8-byte little-endian int64 for value 42', () {
      final bytes = Uint8List.fromList([42, 0, 0, 0, 0, 0, 0, 0]);
      expect(decodeCounter(bytes), equals(42));
    });

    test('with wrong byte length (4 bytes) throws ArgumentError', () {
      final bytes = Uint8List(4);
      expect(() => decodeCounter(bytes), throwsArgumentError);
    });

    test('with empty bytes throws ArgumentError', () {
      final bytes = Uint8List(0);
      expect(() => decodeCounter(bytes), throwsArgumentError);
    });
  });

  group('round-trip', () {
    test('encode/decode preserves value 12345', () {
      expect(decodeCounter(encodeCounter(12345)), equals(12345));
    });
  });
}
