import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBrandingStore {
  AppBrandingStore._();

  static const _logoPathKey = 'app_branding_logo_path';
  static const _logoDataKey = 'app_branding_logo_data';
  static final ValueNotifier<String?> logoPath = ValueNotifier(null);
  static final ValueNotifier<Uint8List?> logoBytes = ValueNotifier(null);

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedData = preferences.getString(_logoDataKey);
    if (savedData != null && savedData.isNotEmpty) {
      try {
        logoBytes.value = base64Decode(savedData);
        return;
      } on FormatException {
        await preferences.remove(_logoDataKey);
      }
    }

    final savedPath = preferences.getString(_logoPathKey);
    if (savedPath != null) {
      if (!kIsWeb && await File(savedPath).exists()) {
        logoPath.value = savedPath;
        try {
          logoBytes.value = await File(savedPath).readAsBytes();
        } catch (_) {}
      }
    }
  }

  static Future<void> saveLogo(XFile image) async {
    final rawBytes = await image.readAsBytes();
    if (rawBytes.isEmpty) {
      throw StateError('Foto toko kosong atau tidak dapat dibaca.');
    }

    final prepared = await OwnerProfileStore.preparePhotoBytes(rawBytes);
    final bytes = prepared.bytes;
    final preferences = await SharedPreferences.getInstance();

    // Perbarui UI segera
    logoBytes.value = bytes;

    // Simpan data base64 ke SharedPreferences dengan fallback kompresi agar aman di Web
    try {
      await preferences.setString(_logoDataKey, base64Encode(bytes));
    } catch (e) {
      debugPrint('Simpan logo percobaan 1 gagal: $e');
      try {
        final smaller = await OwnerProfileStore.preparePhotoBytes(
          bytes,
          maxDimension: 144,
        );
        await preferences.setString(_logoDataKey, base64Encode(smaller.bytes));
        logoBytes.value = smaller.bytes;
      } catch (e2) {
        debugPrint('Simpan logo percobaan 2 gagal: $e2');
      }
    }

    if (!kIsWeb) {
      try {
        final supportDirectory = await getApplicationSupportDirectory();
        final brandingDirectory = Directory(
          '${supportDirectory.path}${Platform.pathSeparator}branding',
        );
        await brandingDirectory.create(recursive: true);

        final extension = prepared.reencodedPng
            ? 'png'
            : (image.name.contains('.')
                ? image.name.split('.').last.toLowerCase()
                : 'jpg');
        const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};
        final safeExtension = supportedExtensions.contains(extension)
            ? extension
            : 'jpg';
        final destination = File(
          '${brandingDirectory.path}${Platform.pathSeparator}logo.$safeExtension',
        );
        await destination.writeAsBytes(bytes, flush: true);
        await preferences.setString(_logoPathKey, destination.path);
        logoPath.value = destination.path;
      } catch (e) {
        debugPrint('Gagal menyimpan file logo fisik: $e');
      }
    }
  }
}
