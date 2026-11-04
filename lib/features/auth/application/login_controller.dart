import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum LoginSubmissionStatus { invalid, authenticated, failed, ignored }

/// Field mana yang harus diberi tanda merah.
enum LoginErrorField { none, username, password, both }

class LoginSubmission {
  const LoginSubmission({
    required this.status,
    this.message,
    this.role,
    this.displayName,
    this.username,
    this.errorField = LoginErrorField.none,
  });

  final LoginSubmissionStatus status;
  final String? message;
  final String? role;
  final String? displayName;
  final String? username;
  final LoginErrorField errorField;

  bool get isError =>
      status == LoginSubmissionStatus.invalid ||
      status == LoginSubmissionStatus.failed;
}

class _LoginException implements Exception {
  _LoginException(this.message);
  final String message;
}

typedef _Validation = ({String message, LoginErrorField field});

/// Owns login state and the backend authentication flow.
class LoginController extends ChangeNotifier {
  LoginController({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _ownsHttpClient = httpClient == null,
      _baseUrl = baseUrl ?? 'https://clatter-distant-sterling.ngrok-free.dev';

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
        message: validation.message,
        errorField: validation.field,
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
    } on _LoginException catch (error) {
      // Salah username / password dari backend
      return LoginSubmission(
        status: LoginSubmissionStatus.failed,
        message: error.message,
        errorField: _detectField(error.message),
      );
    } catch (error) {
      // Masalah koneksi / lainnya: tidak menandai field
      debugPrint('Login gagal: $error');
      return const LoginSubmission(
        status: LoginSubmissionStatus.failed,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi backend.',
      );
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  /// Tebak field yang salah dari pesan backend.
  /// "Username tidak ditemukan" -> username
  /// "Password salah"           -> password
  /// "Username atau password salah" / lainnya -> keduanya
  LoginErrorField _detectField(String message) {
    final m = message.toLowerCase();
    final hasUser =
        m.contains('username') || m.contains('pengguna') || m.contains('user');
    final hasPass = m.contains('password') || m.contains('sandi');

    if (hasUser && !hasPass) return LoginErrorField.username;
    if (hasPass && !hasUser) return LoginErrorField.password;
    return LoginErrorField.both;
  }

  _Validation? _validate(String username, String password) {
    if (username.isEmpty && password.isEmpty) {
      return (
        message: 'Username dan password wajib diisi.',
        field: LoginErrorField.both,
      );
    }
    if (username.isEmpty) {
      return (
        message: 'Username wajib diisi.',
        field: LoginErrorField.username,
      );
    }
    if (password.isEmpty) {
      return (
        message: 'Password wajib diisi.',
        field: LoginErrorField.password,
      );
    }
    if (!RegExp(r'^[a-z0-9_]{4,20}$').hasMatch(username)) {
      return (
        message: 'Username 4–20 karakter: huruf, angka, atau underscore.',
        field: LoginErrorField.username,
      );
    }
    if (password.length < 6) {
      return (
        message: 'Password minimal 6 karakter.',
        field: LoginErrorField.password,
      );
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
      throw _LoginException(data['message']?.toString() ?? 'Login gagal.');
    }
    throw Exception('Respons dari server tidak valid.');
  }
}