import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan foto QRIS agar pilihan dari Pengaturan dipakai di Checkout.
class QrisStore {
  static const String _key = 'celcious_qris_image_base64';

  static Future<void> saveImageBytes(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, base64Encode(bytes));
  }

  static Future<Uint8List?> loadImageBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
