import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KitchenReceiptSettingsStore {
  KitchenReceiptSettingsStore._();

  static const _key = 'kitchen_receipt_settings';

  static const defaults = <String, bool>{
    'enabled': true,
    'orderNumber': true,
    'customerName': true,
    'orderType': true,
    'orderTime': true,
    'itemNotes': true,
    'itemQuantity': true,
  };

  static final ValueNotifier<Map<String, bool>> options =
      ValueNotifier<Map<String, bool>>(Map<String, bool>.from(defaults));

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_key);
    if (saved == null) return;

    try {
      final decoded = jsonDecode(saved);
      if (decoded is! Map) return;

      final restored = Map<String, bool>.from(defaults);
      for (final entry in decoded.entries) {
        if (entry.key is String && entry.value is bool) {
          if (restored.containsKey(entry.key)) {
            restored[entry.key as String] = entry.value as bool;
          }
        }
      }
      options.value = restored;
    } catch (_) {
      options.value = Map<String, bool>.from(defaults);
    }
  }

  static Future<void> setOption(String key, bool value) async {
    if (!defaults.containsKey(key)) {
      throw ArgumentError.value(key, 'key', 'Opsi struk dapur tidak dikenal.');
    }

    final updated = Map<String, bool>.from(options.value)..[key] = value;
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_key, jsonEncode(updated));
    if (!saved) throw StateError('Gagal menyimpan pengaturan struk dapur.');
    options.value = updated;
  }

  static Future<void> saveAll(Map<String, bool> newOptions) async {
    final updated = Map<String, bool>.from(defaults)..addAll(newOptions);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(updated));
    options.value = updated;
  }
}
