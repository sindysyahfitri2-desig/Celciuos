import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StickerSettingsStore {
  StickerSettingsStore._();

  static const _key = 'sticker_settings';

  static const defaults = <String, bool>{
    'orderNumber': true,
    'customerName': true,
    'orderType': true,
    'productName': true,
    'productVariant': true,
    'orderTime': true,
    'cashierCode': true,
    'itemProgress': true,
    'caption': true, 
    'enabled': true,
  };

  static final ValueNotifier<Map<String, bool>> options =
      ValueNotifier<Map<String, bool>>(Map<String, bool>.from(defaults));

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_key);
    if (saved == null) return;

    final decoded = jsonDecode(saved);
    if (decoded is! Map) {
      throw const FormatException('Pengaturan stiker tersimpan tidak valid.');
    }

    final restored = Map<String, bool>.from(defaults);
    for (final entry in decoded.entries) {
      if (entry.key is String && entry.value is bool) {
        if (restored.containsKey(entry.key)) {
          restored[entry.key as String] = entry.value as bool;
        }
      }
    }
    options.value = restored;
  }

  static Future<void> setOption(String key, bool value) async {
    if (!defaults.containsKey(key)) {
      throw ArgumentError.value(key, 'key', 'Opsi stiker tidak dikenal.');
    }

    final updated = Map<String, bool>.from(options.value)..[key] = value;
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_key, jsonEncode(updated));
    if (!saved) throw StateError('Gagal menyimpan pengaturan stiker.');
    options.value = updated;
  }

  static Future<void> saveAll(Map<String, bool> newOptions) async {
    final updated = Map<String, bool>.from(defaults)..addAll(newOptions);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(updated));
    options.value = updated;
  }
}
