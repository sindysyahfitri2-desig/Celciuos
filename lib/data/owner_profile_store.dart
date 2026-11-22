import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OwnerPinResolution {
  const OwnerPinResolution({
    required this.allowed,
    this.primarySecretToTry,
    this.fallbackBackendSecret,
    this.errorMessage,
  });

  final bool allowed;
  final String? primarySecretToTry;
  final String? fallbackBackendSecret;
  final String? errorMessage;
}

class OwnerProfileStore {
  OwnerProfileStore._();

  static const _nameKey = 'owner_profile_name';
  static const _photoDataKey = 'owner_profile_photo_base64';
  static const _photoPathKey = 'owner_profile_photo_path';
  static const _localPasswordKey = 'owner_profile_password_override';
  static const _currentSecretKey = 'owner_profile_current_secret';
  static const _backendFallbackSecretKey = 'owner_profile_backend_fallback_secret';

  static final ValueNotifier<String> ownerName = ValueNotifier<String>('Owner');
  static final ValueNotifier<String> ownerUsername = ValueNotifier<String>('');
  static final ValueNotifier<Uint8List?> photoBytes = ValueNotifier<Uint8List?>(
    null,
  );
  static final ValueNotifier<String?> photoUrl = ValueNotifier<String?>(null);
  static final ValueNotifier<bool> requiresTextPasswordLogin =
      ValueNotifier<bool>(false);

  static Future<void> initialize({String? fallbackName}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = await ApiService.getUser();

    final savedName = prefs.getString(_nameKey)?.trim();
    final userName = user?['nama']?.toString().trim();
    final username = user?['username']?.toString().trim();
    final remotePhoto = user?['foto_url']?.toString().trim();

    if (savedName != null && savedName.isNotEmpty) {
      ownerName.value = savedName;
    } else if (userName != null && userName.isNotEmpty) {
      ownerName.value = userName;
    } else if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      ownerName.value = fallbackName.trim();
    }

    if (username != null && username.isNotEmpty) {
      ownerUsername.value = username;
    }

    if (remotePhoto != null && remotePhoto.isNotEmpty) {
      photoUrl.value = remotePhoto;
    }

    final overridePw = prefs.getString(_localPasswordKey);
    requiresTextPasswordLogin.value =
        overridePw != null &&
        overridePw.isNotEmpty &&
        !RegExp(r'^\d{6}$').hasMatch(overridePw);

    final savedPhoto = prefs.getString(_photoDataKey);
    if (savedPhoto != null && savedPhoto.isNotEmpty) {
      try {
        photoBytes.value = base64Decode(savedPhoto);
        return;
      } on FormatException {
        await prefs.remove(_photoDataKey);
      }
    }

    if (!kIsWeb) {
      final savedPath = prefs.getString(_photoPathKey);
      if (savedPath != null && savedPath.isNotEmpty) {
        try {
          final file = File(savedPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) {
              photoBytes.value = bytes;
            }
          }
        } catch (e) {
          debugPrint('Gagal membaca file foto owner lokal: $e');
        }
      }
    }
  }

  /// Kompresi aman menggunakan engine Flutter (`dart:ui`) agar foto ukuran besar
  /// tetap muat di localStorage Web (batas 5MB) dan batas upload Laravel.
  static Future<({Uint8List bytes, bool reencodedPng})> preparePhotoBytes(
    Uint8List rawBytes, {
    int maxDimension = 256,
  }) async {
    if (rawBytes.length <= 120 * 1024) {
      return (bytes: rawBytes, reencodedPng: false);
    }

    try {
      var codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: maxDimension,
      );
      var frame = await codec.getNextFrame();
      var image = frame.image;

      if (image.height > maxDimension) {
        image.dispose();
        codec.dispose();
        codec = await ui.instantiateImageCodec(
          rawBytes,
          targetHeight: maxDimension,
        );
        frame = await codec.getNextFrame();
        image = frame.image;
      }

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      codec.dispose();

      if (byteData != null) {
        final resized = byteData.buffer.asUint8List();
        if (resized.isNotEmpty && resized.length < rawBytes.length) {
          return (bytes: resized, reencodedPng: true);
        }
      }
    } catch (e) {
      debugPrint('Kompresi foto owner dilewati: $e');
    }

    return (bytes: rawBytes, reencodedPng: false);
  }

  static Future<void> _persistPhotoLocally(
    SharedPreferences prefs,
    Uint8List photo,
  ) async {
    // Simpan ke file fisik pada Android/iOS/Desktop sebagai cadangan permanen.
    if (!kIsWeb) {
      try {
        final supportDir = await getApplicationSupportDirectory();
        final profileDir = Directory(
          '${supportDir.path}${Platform.pathSeparator}profile',
        );
        await profileDir.create(recursive: true);
        final file = File(
          '${profileDir.path}${Platform.pathSeparator}owner_avatar.png',
        );
        await file.writeAsBytes(photo, flush: true);
        await prefs.setString(_photoPathKey, file.path);
      } catch (e) {
        debugPrint('Gagal menyimpan file fisik foto owner: $e');
      }
    }

    // Simpan ke SharedPreferences / localStorage dengan fallback kompresi ekstra
    // agar tidak gagal karena QuotaExceededError di browser.
    try {
      await prefs.setString(_photoDataKey, base64Encode(photo));
      return;
    } catch (e) {
      debugPrint('Simpan base64 foto owner percobaan 1 gagal: $e');
    }

    try {
      final smaller = await preparePhotoBytes(photo, maxDimension: 144);
      await prefs.setString(_photoDataKey, base64Encode(smaller.bytes));
      photoBytes.value = smaller.bytes;
    } catch (e) {
      debugPrint('Simpan base64 foto owner percobaan 2 gagal: $e');
    }
  }

  static Future<String> updateProfile({
    required String name,
    Uint8List? newPhotoBytes,
    String photoFileName = 'owner_profile.jpg',
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const FormatException('Nama owner tidak boleh kosong.');
    }

    final prefs = await SharedPreferences.getInstance();
    final user = await ApiService.getUser();
    final token = await ApiService.getToken();
    final userId = user?['id_pengguna'] ?? user?['id'];

    Uint8List? finalPhotoBytes;
    var uploadFileName = photoFileName;

    if (newPhotoBytes != null && newPhotoBytes.isNotEmpty) {
      final prepared = await preparePhotoBytes(newPhotoBytes);
      finalPhotoBytes = prepared.bytes;
      if (prepared.reencodedPng) {
        uploadFileName = 'owner_profile.png';
      }
    }

    var syncedToServer = false;
    String? updatedRemotePhoto = photoUrl.value;

    if (token != null && token.isNotEmpty && userId != null) {
      try {
        final Map<String, dynamic> res;
        if (finalPhotoBytes != null) {
          res = await ApiService.postMultipart(
            'pengguna/$userId',
            {'_method': 'PUT', 'nama': cleanName},
            fileBytes: finalPhotoBytes,
            fileField: 'foto',
            fileName: uploadFileName,
          );
        } else {
          res = await ApiService.put('pengguna/$userId', {'nama': cleanName});
        }
        syncedToServer = true;
        final data = res['data'] ?? res['pengguna'];
        if (data is Map) {
          final remoteFoto = data['foto_url']?.toString().trim();
          if (remoteFoto != null && remoteFoto.isNotEmpty) {
            updatedRemotePhoto = remoteFoto;
          }
        }
      } catch (e) {
        debugPrint('Sinkron profil owner ke backend dilewati: $e');
      }
    }

    // Perbarui state UI langsung agar foto & nama langsung tampil
    ownerName.value = cleanName;
    if (finalPhotoBytes != null) {
      photoBytes.value = finalPhotoBytes;
    }
    photoUrl.value = updatedRemotePhoto;

    // Simpan ke penyimpanan lokal permanen
    await prefs.setString(_nameKey, cleanName);
    if (finalPhotoBytes != null) {
      await _persistPhotoLocally(prefs, finalPhotoBytes);
    }

    if (user != null && token != null) {
      final updatedUser = Map<String, dynamic>.from(user);
      updatedUser['nama'] = cleanName;
      if (updatedRemotePhoto != null) {
        updatedUser['foto_url'] = updatedRemotePhoto;
      }
      await ApiService.saveAuth(token: token, user: updatedUser);
    }

    return syncedToServer
        ? 'Profil owner berhasil diperbarui.'
        : 'Profil owner berhasil disimpan.';
  }

  /// Mencatat PIN/password owner yang berhasil login untuk verifikasi ganti password.
  static Future<void> recordAuthenticatedSecret(
    String secret, {
    bool isBackendSecret = true,
  }) async {
    final clean = secret.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSecretKey, clean);
    if (isBackendSecret) {
      await prefs.setString(_backendFallbackSecretKey, clean);
    }
  }

  /// Memvalidasi PIN/password saat Owner login di `OwnerPinPage` atau `LoginController`.
  static Future<OwnerPinResolution> resolveOwnerSecretForLogin(
    String enteredSecret,
  ) async {
    final clean = enteredSecret.trim();
    final prefs = await SharedPreferences.getInstance();
    final localOverride = prefs.getString(_localPasswordKey)?.trim();
    final backendFallback = prefs.getString(_backendFallbackSecretKey)?.trim();

    if (localOverride != null && localOverride.isNotEmpty) {
      if (clean != localOverride) {
        return const OwnerPinResolution(
          allowed: false,
          errorMessage: 'Password / PIN salah, silakan coba lagi.',
        );
      }
      return OwnerPinResolution(
        allowed: true,
        primarySecretToTry: clean,
        fallbackBackendSecret:
            (backendFallback != null && backendFallback.isNotEmpty)
                ? backendFallback
                : null,
      );
    }

    return OwnerPinResolution(allowed: true, primarySecretToTry: clean);
  }

  /// Hapus override lokal bila backend sudah menerima password/PIN baru secara langsung.
  static Future<void> clearLocalPasswordOverride(String verifiedSecret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localPasswordKey);
    await prefs.setString(_currentSecretKey, verifiedSecret);
    await prefs.setString(_backendFallbackSecretKey, verifiedSecret);
    requiresTextPasswordLogin.value = false;
  }

  static Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final oldTrim = oldPassword.trim();
    final newTrim = newPassword.trim();
    final confirmTrim = confirmPassword.trim();

    if (oldTrim.isEmpty) {
      throw const FormatException('Password lama wajib diisi.');
    }
    if (newTrim.length < 6) {
      throw const FormatException('Password baru minimal 6 karakter.');
    }
    if (newTrim != confirmTrim) {
      throw const FormatException(
        'Konfirmasi password tidak cocok dengan password baru.',
      );
    }
    if (oldTrim == newTrim) {
      throw const FormatException(
        'Password baru tidak boleh sama dengan password lama.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final storedCurrent = prefs.getString(_currentSecretKey)?.trim();
    final storedOverride = prefs.getString(_localPasswordKey)?.trim();
    final expectedOld = (storedOverride != null && storedOverride.isNotEmpty)
        ? storedOverride
        : storedCurrent;

    // Validasi password lama terhadap password aktif yang tercatat
    if (expectedOld != null && expectedOld.isNotEmpty && oldTrim != expectedOld) {
      throw const FormatException('Password lama tidak sesuai.');
    }

    final user = await ApiService.getUser();
    final token = await ApiService.getToken();
    final userId = user?['id_pengguna'] ?? user?['id'];
    final currentName = ownerName.value.trim().isNotEmpty
        ? ownerName.value.trim()
        : (user?['nama']?.toString().trim() ?? 'Owner');

    var backendConfirmedChanged = false;

    if (token != null && token.isNotEmpty && userId != null) {
      var putSucceeded = false;

      // Percobaan 1: kirim lengkap beserta nama & password_lama
      try {
        await ApiService.put('pengguna/$userId', {
          'nama': currentName,
          'password_lama': oldTrim,
          'password': newTrim,
          'password_confirmation': confirmTrim,
        });
        putSucceeded = true;
      } catch (e) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        final lower = msg.toLowerCase();
        if (lower.contains('password lama') &&
            (lower.contains('salah') ||
                lower.contains('tidak sesuai') ||
                lower.contains('invalid'))) {
          throw Exception(msg);
        }
        debugPrint('PUT password percobaan 1 gagal: $e');
      }

      // Percobaan 2: beberapa controller Laravel hanya menerima nama + password
      if (!putSucceeded) {
        try {
          await ApiService.put('pengguna/$userId', {
            'nama': currentName,
            'password': newTrim,
          });
          putSucceeded = true;
        } catch (e) {
          debugPrint('PUT password percobaan 2 gagal: $e');
        }
      }

      // Verifikasi apakah backend benar-benar mengganti PIN/password
      if (putSucceeded && RegExp(r'^\d{6}$').hasMatch(newTrim)) {
        try {
          final verifyRes = await ApiService.post('login-owner-pin', {
            'pin': newTrim,
          });
          if (verifyRes['token'] != null && verifyRes['pengguna'] is Map) {
            await ApiService.saveAuth(
              token: verifyRes['token'].toString(),
              user: Map<String, dynamic>.from(verifyRes['pengguna'] as Map),
            );
            backendConfirmedChanged = true;
          }
        } catch (e) {
          debugPrint('Verifikasi PIN baru ke backend belum cocok: $e');
        }
      }
    }

    // Perbarui juga penyimpanan akun lokal bila ada.
    final accountsRaw = prefs.getString('celcious_accounts');
    if (accountsRaw != null && accountsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(accountsRaw);
        if (decoded is List) {
          var changed = false;
          for (final item in decoded) {
            if (item is Map &&
                item['role']?.toString().toLowerCase() == 'owner') {
              item['password'] = newTrim;
              changed = true;
            }
          }
          if (changed) {
            await prefs.setString('celcious_accounts', jsonEncode(decoded));
          }
        }
      } catch (_) {}
    }

    if (backendConfirmedChanged) {
      await clearLocalPasswordOverride(newTrim);
      return 'Password berhasil diganti dan aktif untuk login berikutnya.';
    }

    // Aktifkan override lokal sambil menyimpan PIN backend terakhir agar
    // saat login ulang dengan password baru tetap bisa mendapat token API.
    final existingBackendFallback = prefs
        .getString(_backendFallbackSecretKey)
        ?.trim();
    if (existingBackendFallback == null || existingBackendFallback.isEmpty) {
      await prefs.setString(_backendFallbackSecretKey, oldTrim);
    }
    await prefs.setString(_localPasswordKey, newTrim);
    await prefs.setString(_currentSecretKey, newTrim);
    requiresTextPasswordLogin.value = !RegExp(r'^\d{6}$').hasMatch(newTrim);

    return 'Password berhasil diganti dan aktif untuk login berikutnya.';
  }
}
