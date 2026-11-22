import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';

enum LoginSubmissionStatus { invalid, authenticated, failed, ignored }

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
        message: validation,
      );
    }

    isVerifying = true;
    notifyListeners();

    try {
      Map<String, dynamic>? result;
      final isKnownOwner =
          OwnerProfileStore.ownerUsername.value.isNotEmpty &&
          OwnerProfileStore.ownerUsername.value.toLowerCase() == username;
      OwnerPinResolution? resolution;

      if (isKnownOwner) {
        resolution = await OwnerProfileStore.resolveOwnerSecretForLogin(
          password,
        );
        if (!resolution.allowed) {
          return const LoginSubmission(
            status: LoginSubmissionStatus.failed,
            message: 'Username atau password salah.',
          );
        }
      }

      try {
        result = await _loginToBackend(username, password);
        if (result != null &&
            result['pengguna'] is Map &&
            (result['pengguna'] as Map)['role']?.toString().toLowerCase() ==
                'owner') {
          if (resolution?.fallbackBackendSecret != null) {
            await OwnerProfileStore.clearLocalPasswordOverride(password);
          } else {
            await OwnerProfileStore.recordAuthenticatedSecret(
              password,
              isBackendSecret: true,
            );
          }
        }
      } catch (e) {
        if (resolution != null &&
            resolution.fallbackBackendSecret != null &&
            resolution.fallbackBackendSecret!.isNotEmpty) {
          result = await _loginToBackend(
            username,
            resolution.fallbackBackendSecret!,
          );
          await OwnerProfileStore.recordAuthenticatedSecret(
            password,
            isBackendSecret: false,
          );
        } else {
          rethrow;
        }
      }

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
      await ApiService.saveAuth(
        token: _authToken!,
        user: user,
      );

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
        message:
            'Login gagal. Periksa username, password, dan koneksi backend.',
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
