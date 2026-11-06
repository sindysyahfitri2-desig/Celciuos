import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class ApiService {
  // Alamat base URL backend Laravel kamu (default lokal)
  // Bisa disesuaikan jika memakai ngrok atau domain lain
  static const String baseUrl =
    'https://clatter-distant-sterling.ngrok-free.dev/api';

  static const String _tokenKey = 'celcious_auth_token';
  static const String _userKey = 'celcious_user_data';

  // ============================================================
  // PENGELOLAAN TOKEN & SESI LOGIN
  // ============================================================

  /// Simpan token dan data user ke SharedPreferences saat login berhasil
  static Future<void> saveAuth({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Ambil token yang tersimpan
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Ambil data user yang sedang login
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }

  /// Hapus token dan data user saat logout
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ============================================================
  // HEADER STANDAR (JSON + BEARER TOKEN)
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ============================================================
  // FUNGSI HTTP (GET, POST, PUT, DELETE)
  // ============================================================

  /// GET Request (mengambil data)
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? query,
  }) async {
    var uri = Uri.parse('$baseUrl/$endpoint');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// POST Request (mengirim / membuat data baru)
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// PUT Request (memperbarui data)
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// DELETE Request (menghapus data)
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// POST multipart (untuk upload file, misalnya foto)
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    Uint8List? fileBytes,
    String fileField = 'foto',
    String fileName = 'foto.jpg',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/$endpoint'),
    );

    final headers = await _headers();
    headers.remove('Content-Type'); // wajib dibuang untuk multipart
    request.headers.addAll(headers);

    request.fields.addAll(fields);

    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ============================================================
  // PENANGANAN RESPON SERVER
  // ============================================================

  static Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Format respon dari server tidak valid (${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'data': data};
    }

    // Jika terjadi error dari Laravel (misal validasi atau 401/403)
    if (data is Map<String, dynamic>) {
      final message =
          data['message']?.toString() ?? 'Terjadi kesalahan pada server.';
      throw Exception(message);
    }

    throw Exception('Error (${response.statusCode}): ${response.reasonPhrase}');
  }
}
