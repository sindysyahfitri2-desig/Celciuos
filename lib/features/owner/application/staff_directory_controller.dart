
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

class Staff {
  final int? id;
  String name;
  final String? username;
  final String? photoPath;
  final Uint8List? photoBytes;
  final String? photoUrl;
  final bool aktif;

  Staff({
    this.id,
    required this.name,
    this.username,
    this.photoPath,
    this.photoBytes,
    this.photoUrl,
    this.aktif = true,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id_pengguna'] as int?,
      name: json['nama']?.toString() ?? '',
      username: json['username']?.toString(),
      photoUrl: json['foto_url']?.toString(),
      aktif: json['aktif'] == true ||
          json['aktif'] == 1 ||
          json['aktif']?.toString() == '1',
    );
  }
}

class StaffDirectoryController extends ChangeNotifier {
  List<Staff> staff = [];

  String searchQuery = '';
  bool isLoading = false;
  String? errorMessage;
  String? infoMessage;
  bool showInactive = false;

  List<Staff> get filteredStaff {
    final query = searchQuery.toLowerCase().trim();

    return staff.where((member) {
      return member.name.toLowerCase().contains(query) ||
          (member.username?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setShowInactive(bool value) {
    if (showInactive == value) return;

    showInactive = value;
    staff = [];
    notifyListeners();
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    final requestedInactive = showInactive;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(
        'pengguna',
        query: {
          'role': 'kasir',
          'status': requestedInactive ? 'nonaktif' : 'aktif',
        },
      );

      if (requestedInactive != showInactive) return;

      if (res['data'] is List) {
        staff = (res['data'] as List)
            .map(
              (item) => Staff.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal fetch staf: $e');
    } finally {
      if (requestedInactive == showInactive) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addStaff(Staff member, {required String pin}) {
    return add(
      name: member.name,
      username: member.username,
      password: pin,
      photoPath: member.photoPath,
      photoBytes: member.photoBytes,
    );
  }

  Future<bool> add({
    required String name,
    String? username,
    String? password,
    String? photoPath,
    Uint8List? photoBytes,
  }) async {
    errorMessage = null;

    try {
      var cleanUsername = (username != null && username.trim().isNotEmpty)
          ? username.trim().toLowerCase()
          : name.trim().toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '',
              );

      if (cleanUsername.length < 4) {
        cleanUsername = '${cleanUsername}1234';
      }

      final cleanPassword =
          (password != null && password.trim().isNotEmpty)
              ? password.trim()
              : '123456';

      await ApiService.postMultipart(
        'pengguna',
        {
          'nama': name.trim(),
          'username': cleanUsername,
          'password': cleanPassword,
          'role': 'kasir',
        },
        fileBytes: photoBytes,
      );

      await fetchStaff();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal tambah staf: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rename(int index, String newName) async {
    if (index < 0 ||
        index >= staff.length ||
        newName.trim().isEmpty) {
      return false;
    }

    final target = staff[index];

    if (target.id == null) return false;

    errorMessage = null;

    try {
      await ApiService.put(
        'pengguna/${target.id}',
        {'nama': newName.trim()},
      );

      target.name = newName.trim();
      infoMessage = 'Nama staf berhasil diperbarui.';
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal edit staf: $e');
      notifyListeners();
      return false;
    }
  }

  // Memperbarui nama dan foto staf.
  // Foto dikirim menggunakan multipart dengan method spoofing PUT Laravel.
  Future<bool> updateStaff(
    int index, {
    required String newName,
    Uint8List? photoBytes,
    String photoFileName = 'foto.jpg',
  }) async {
    if (index < 0 ||
        index >= staff.length ||
        newName.trim().isEmpty) {
      return false;
    }

    final target = staff[index];

    if (target.id == null) return false;

    errorMessage = null;
    infoMessage = null;

    try {
      if (photoBytes != null) {
        await ApiService.postMultipart(
          'pengguna/${target.id}',
          {
            '_method': 'PUT',
            'nama': newName.trim(),
          },
          fileBytes: photoBytes,
          fileName: photoFileName,
          fileField: 'foto',
        );
      } else {
        await ApiService.put(
          'pengguna/${target.id}',
          {'nama': newName.trim()},
        );
      }

      target.name = newName.trim();

      infoMessage = 'Data staf berhasil diperbarui.';
      await fetchStaff();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal memperbarui staf: $e');
      notifyListeners();
      return false;
    }
  }

  // Menonaktifkan staf, bukan menghapus permanen.
  Future<bool> deactivate(int index) async {
    if (index < 0 || index >= staff.length) return false;

    final target = staff[index];

    if (target.id == null) return false;

    errorMessage = null;
    infoMessage = null;

    try {
      await ApiService.put(
        'pengguna/${target.id}',
        {'aktif': false},
      );

      infoMessage = 'Staf berhasil dinonaktifkan.';
      staff.removeAt(index);

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal menonaktifkan staf: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> activate(int index) async {
    if (index < 0 || index >= staff.length) return false;

    final target = staff[index];

    if (target.id == null) return false;

    errorMessage = null;
    infoMessage = null;

    try {
      final res = await ApiService.put(
        'pengguna/${target.id}/aktifkan',
        {},
      );

      infoMessage = res['message']?.toString() ??
          'Staf berhasil diaktifkan kembali.';

      staff.removeAt(index);
      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal aktifkan staf: $e');
      notifyListeners();
      return false;
    }
  }
}
