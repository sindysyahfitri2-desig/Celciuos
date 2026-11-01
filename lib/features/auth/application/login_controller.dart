import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum LoginSubmissionStatus {
  invalid,
  registered,
  authenticated,
  failed,
  ignored,
}

class LoginSubmission {
  const LoginSubmission({
    required this.status,
    this.message,
    this.role,
    this.displayName,
    this.username,
  });

  final LoginSubmissionStatus status;
  final String? message;
  final String? role;
  final String? displayName;
  final String? username;

  bool get isError =>
      status == LoginSubmissionStatus.invalid ||
      status == LoginSubmissionStatus.failed;
}

/// Owns login state, account registration, and the existing backend flow.
class LoginController extends ChangeNotifier {
  LoginController({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      _ownsHttpClient = httpClient == null;

  static const _storageKey = 'celcious_accounts';
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  static const List<Map<String, String>> _defaultAccounts = [
    {
      'username': 'danielowner',
      'password': 'daniel1109',
      'role': 'Owner',
      'displayName': 'Daniel',
    },
    {
      'username': 'kasircelcius',
      'password': 'kasir1116',
      'role': 'Kasir',
      'displayName': 'Kasir Celcius',
    },
  ];

  bool isLogin = true;
  bool isVerifying = false;
  String? _authToken;

  @override
  void dispose() {
    if (_ownsHttpClient) _httpClient.close();
    super.dispose();
  }

  void setLoginMode(bool value) {
    if (isVerifying || isLogin == value) return;
    isLogin = value;
    notifyListeners();
  }

  Future<LoginSubmission> submit(String rawUsername, String password) async {
    if (isVerifying) {
      return const LoginSubmission(status: LoginSubmissionStatus.ignored);
    }

    final username = rawUsername.trim().toLowerCase();
    final validation = _validate(username, password);
    if (validation != null) {
      return LoginSubmission(
        status: LoginSubmissionStatus.invalid,
        message: validation,
      );
    }

    isVerifying = true;
    notifyListeners();

    try {
      final accounts = await _loadAccounts();

      if (!isLogin) {
        final alreadyExists = accounts.any(
          (account) => account['username'] == username,
        );
        if (alreadyExists) {
          return const LoginSubmission(
            status: LoginSubmissionStatus.failed,
            message: 'Username sudah digunakan. Pilih username lain.',
          );
        }

        accounts.add({
          'username': username,
          'password': password,
          'role': 'Kasir',
          'displayName': 'Kasir $username',
        });
        await _saveAccounts(accounts);
        isLogin = true;
        notifyListeners();
        return const LoginSubmission(
          status: LoginSubmissionStatus.registered,
          message: 'Pendaftaran berhasil! Silakan login dengan akun baru.',
        );
      }

      final result = await _loginToBackend(username, password);
      if (result == null ||
          result['pengguna'] is! Map<String, dynamic> ||
          result['token'] == null) {
        return const LoginSubmission(
          status: LoginSubmissionStatus.failed,
          message: 'Respons login dari server tidak lengkap.',
        );
      }

      final user = result['pengguna'] as Map<String, dynamic>;
      _authToken = result['token'].toString();
      final profile = await _getFromBackend('user');
      debugPrint('HASIL TES TOKEN: $profile');

      final roleFromApi = user['role']?.toString().toLowerCase();
      if (roleFromApi != 'owner' && roleFromApi != 'kasir') {
        return const LoginSubmission(
          status: LoginSubmissionStatus.failed,
          message: 'Role akun tidak dikenali.',
        );
      }

      return LoginSubmission(
        status: LoginSubmissionStatus.authenticated,
        role: roleFromApi == 'owner' ? 'Owner' : 'Kasir',
        displayName: user['nama']?.toString() ?? username,
        username: username,
      );
    } catch (error) {
      debugPrint('Login gagal: $error');
      final message = isLogin
          ? 'Login gagal. Periksa username, password, dan koneksi backend.'
          : 'Terjadi kesalahan saat memproses akun.';
      return LoginSubmission(
        status: LoginSubmissionStatus.failed,
        message: message,
      );
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  String? _validate(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      return 'Username dan password wajib diisi.';
    }
    if (!RegExp(r'^[a-z0-9_]{4,20}$').hasMatch(username)) {
      return 'Username harus 4–20 karakter, hanya huruf, angka, atau underscore.';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    return null;
  }

  Future<List<Map<String, String>>> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);

    if (savedData == null) {
      final initialAccounts = _defaultAccounts
          .map((account) => Map<String, String>.from(account))
          .toList();
      await prefs.setString(_storageKey, jsonEncode(initialAccounts));
      return initialAccounts;
    }

    final decoded = jsonDecode(savedData);
    if (decoded is! List) {
      throw const FormatException('Format data akun lokal tidak valid.');
    }

    var migrated = false;
    final accounts = <Map<String, String>>[];
    for (final item in decoded) {
      if (item is! Map) {
        throw const FormatException('Data akun lokal tidak valid.');
      }

      final values = Map<String, dynamic>.from(item);
      final username = values['username']?.toString().trim().toLowerCase();
      final password = values['password']?.toString();
      final role = values['role']?.toString();
      final displayName =
          values['displayName']?.toString() ??
          values['Username']?.toString() ??
          username;

      if (username == null ||
          username.isEmpty ||
          password == null ||
          role == null ||
          (role != 'Owner' && role != 'Kasir') ||
          displayName == null ||
          displayName.isEmpty) {
        throw const FormatException(
          'Ada akun lokal yang tidak memiliki data lengkap.',
        );
      }

      if (values['displayName'] == null ||
          values['Username'] != null ||
          values['username'] != username) {
        migrated = true;
      }

      accounts.add({
        'username': username,
        'password': password,
        'role': role,
        'displayName': displayName,
      });
    }

    if (migrated) await _saveAccounts(accounts);
    return accounts;
  }

  Future<void> _saveAccounts(List<Map<String, String>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(accounts));
  }

  Future<Map<String, dynamic>?> _loginToBackend(
    String username,
    String password,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('http://127.0.0.1:8000/api/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      throw Exception(data['message']?.toString() ?? 'Login gagal.');
    }
    throw Exception('Respons dari server tidak valid.');
  }

  Future<Map<String, dynamic>> _getFromBackend(String endpoint) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Token login tidak tersedia.');
    }

    final response = await _httpClient.get(
      Uri.parse('http://127.0.0.1:8000/api/$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': '******'},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      throw Exception(data['message']?.toString() ?? 'Gagal mengambil data.');
    }
    throw Exception('Respons dari server tidak valid.');
  }
}
