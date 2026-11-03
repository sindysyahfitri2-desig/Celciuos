import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum LoginSubmissionStatus {
  invalid,
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

/// Owns login state and the backend authentication flow.
class LoginController extends ChangeNotifier {
  
LoginController({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _ownsHttpClient = httpClient == null,
      _baseUrl = baseUrl ?? 'http://192.168.110.252:8000';

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final String _baseUrl;

  bool isVerifying = false;
  String? _authToken;

  @override
  void dispose() {
    if (_ownsHttpClient) _httpClient.close();
    super.dispose();
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
      return LoginSubmission(
        status: LoginSubmissionStatus.failed,
        message: 'Login gagal. Periksa username, password, dan koneksi backend.',
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

  Future<Map<String, dynamic>?> _loginToBackend(
    String username,
    String password,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/login'),
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

}
