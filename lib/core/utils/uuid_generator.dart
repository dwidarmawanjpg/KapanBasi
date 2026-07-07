import 'dart:math';

/// Helper utility untuk men-generate UUID v4 secara mandiri di sisi client
/// tanpa bergantung pada package external.
class UuidGenerator {
  UuidGenerator._();

  /// Menghasilkan string UUID v4 acak (contoh: "f47ac10b-58cc-4372-a567-0e02b2c3d479").
  static String generate() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Set format bit untuk UUID version 4
    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 10
    
    final hexBuffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        hexBuffer.write('-');
      }
      hexBuffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    
    return hexBuffer.toString();
  }
}
