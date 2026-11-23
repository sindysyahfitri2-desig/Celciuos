import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodsStore {
  PaymentMethodsStore._();

  static const _storageKey = 'celcious_payment_methods';
  static const List<String> defaults = ['QRIS', 'Cash'];

  static final ValueNotifier<List<String>> methods =
      ValueNotifier<List<String>>(List<String>.from(defaults));

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      methods.value = List<String>.from(defaults);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final rawLoaded = decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final loaded = rawLoaded
            .where((e) => !e.toLowerCase().contains('transfer'))
            .toList();
        if (loaded.isNotEmpty) {
          methods.value = loaded;
          if (loaded.length != rawLoaded.length) {
            await _persist(loaded);
          }
          return;
        }
      }
    } catch (_) {}

    methods.value = List<String>.from(defaults);
    await _persist(methods.value);
  }

  static Future<bool> addMethod(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return false;

    final exists = methods.value.any(
      (item) => item.toLowerCase() == name.toLowerCase(),
    );
    if (exists) return false;

    final updated = [...methods.value, name];
    methods.value = updated;
    await _persist(updated);
    return true;
  }

  static Future<bool> removeMethod(String name) async {
    if (methods.value.length <= 1) return false;
    final updated = methods.value
        .where((item) => item.toLowerCase() != name.toLowerCase())
        .toList();
    if (updated.length == methods.value.length) return false;

    methods.value = updated;
    await _persist(updated);
    return true;
  }

  static Future<void> _persist(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(list));
  }
}
