import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

class Staff {
  final int? id;
  String name;
  final String? username;
  final String? photoPath;
  final Uint8List? photoBytes;
  final String? photoUrl; // BARU

  Staff({
    this.id,
    required this.name,
    this.username,
    this.photoPath,
    this.photoBytes,
    this.photoUrl, // BARU
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id_pengguna'] as int?,
      name: json['nama']?.toString() ?? '',
      username: json['username']?.toString(),
      photoUrl: json['foto_url']?.toString(), // BARU
    );
  }
}
/// Holds staff directory state and search/edit rules for the Owner screen.
class StaffDirectoryController extends ChangeNotifier {
  List<Staff> staff = [];
  String searchQuery = '';
  bool isLoading = false;
  String? errorMessage;

  List<Staff> get filteredStaff {
    final query = searchQuery.toLowerCase();
    return staff
        .where((member) =>
            member.name.toLowerCase().contains(query) ||
            (member.username?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  /// Mengambil daftar kasir dari backend Laravel
  Future<void> fetchStaff() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get('pengguna', query: {'role': 'kasir'});
      if (res['data'] is List) {
        staff = (res['data'] as List)
            .map((item) => Staff.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal fetch staf: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Helper untuk dipanggil oleh AddStaffCard
  Future<bool> addStaff(Staff member, {required String pin}) {
    return add(
      name: member.name,
      username: member.username,
      password: pin,
      photoPath: member.photoPath,
      photoBytes: member.photoBytes,
    );
  }

  /// Menambahkan akun kasir baru ke backend
  Future<bool> add({
    required String name,
    String? username,
    String? password,
    String? photoPath,
    Uint8List? photoBytes,
  }) async {
    try {
      // Jika username kosong, buat otomatis dari nama (huruf kecil tanpa spasi)
      var cleanUsername = (username != null && username.trim().isNotEmpty)
          ? username.trim().toLowerCase()
          : name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (cleanUsername.length < 4) {
        cleanUsername = '${cleanUsername}1234';
      }

      final cleanPassword = (password != null && password.trim().isNotEmpty)
          ? password.trim()
          : '123456'; // Default password jika tidak diisi

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

      // Muat ulang data terbaru dari backend
      await fetchStaff();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal tambah staf: $e');
      notifyListeners();
      return false;
    }
  }

  /// Mengubah nama kasir di backend
  Future<bool> rename(int index, String newName) async {
    if (index < 0 || index >= staff.length || newName.trim().isEmpty) {
      return false;
    }

    final target = staff[index];
    if (target.id == null) {
      target.name = newName.trim();
      notifyListeners();
      return true;
    }

    try {
      await ApiService.put('pengguna/${target.id}', {
        'nama': newName.trim(),
      });

      target.name = newName.trim();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal edit staf: $e');
      notifyListeners();
      return false;
    }
  }

  /// Menghapus kasir dari backend
  Future<bool> delete(int index) async {
    if (index < 0 || index >= staff.length) return false;

    final target = staff[index];
    if (target.id == null) {
      staff.removeAt(index);
      notifyListeners();
      return true;
    }

    try {
      await ApiService.delete('pengguna/${target.id}');
      staff.removeAt(index);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Gagal hapus staf: $e');
      notifyListeners();
      return false;
    }
  }
  
}
