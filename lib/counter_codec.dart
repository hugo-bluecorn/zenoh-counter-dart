import 'dart:typed_data';

/// Encodes an integer counter value as an 8-byte little-endian int64.
Uint8List encodeCounter(int value) {
  final data = ByteData(8)..setInt64(0, value, Endian.little);
  return data.buffer.asUint8List();
}

/// Decodes an 8-byte little-endian int64 from [bytes].
///
/// Throws [ArgumentError] if [bytes] length is not 8.
int decodeCounter(Uint8List bytes) {
  if (bytes.length != 8) {
    throw ArgumentError('Expected 8 bytes, got ${bytes.length}');
  }
  return ByteData.sublistView(bytes).getInt64(0, Endian.little);
}
