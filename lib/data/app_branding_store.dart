import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('Foto toko kosong atau tidak dapat dibaca.');
    }

    final preferences = await SharedPreferences.getInstance();

    // Selalu simpan data base64 ke SharedPreferences agar logo permanen dan tidak hilang saat sistem dimatikan/restart
    final base64String = base64Encode(bytes);
    await preferences.setString(_logoDataKey, base64String);

    if (!kIsWeb) {
      try {
        final supportDirectory = await getApplicationSupportDirectory();
        final brandingDirectory = Directory(
          '${supportDirectory.path}${Platform.pathSeparator}branding',
        );
        await brandingDirectory.create(recursive: true);

        final extension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';
        const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};
        final safeExtension = supportedExtensions.contains(extension)
            ? extension
            : 'jpg';
        final destination = File(
          '${brandingDirectory.path}${Platform.pathSeparator}logo.$safeExtension',
        );
        await File(image.path).copy(destination.path);
        await preferences.setString(_logoPathKey, destination.path);
        logoPath.value = destination.path;
      } catch (e) {
        debugPrint('Gagal menyimpan file logo fisik: $e');
      }
    }

    logoBytes.value = bytes;
  }
}
