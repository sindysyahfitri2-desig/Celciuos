import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class ApiService {
  static http.Client _client = http.Client();

  @visibleForTesting
  static set clientForTesting(http.Client client) => _client = client;

  @visibleForTesting
  static void resetClientForTesting() => _client = http.Client();

  // Alamat base URL backend Laravel:
  // - Bisa dioverride saat build: --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
  // - Saat dijalankan di Web lokal (localhost/127.0.0.1), langsung ke 127.0.0.1:8000 (< 0.2 detik!)
  // - Saat dijalankan di HP Android / domain publik, gunakan ngrok / domain hosting.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _remoteBaseUrl =
      'https://clatter-distant-sterling.ngrok-free.dev/api';

  static const Duration _getTimeout = Duration(seconds: 15);
  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 30);

  static String? _cachedToken;
  static bool _tokenLoaded = false;
  static Map<String, dynamic>? _cachedUser;
  static bool _userLoaded = false;

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://127.0.0.1:8000/api';
      }
    }
    return _remoteBaseUrl;
  }

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
    _cachedToken = token;
    _tokenLoaded = true;
    _cachedUser = Map<String, dynamic>.from(user);
    _userLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Ambil token yang tersimpan (di-cache di memori agar tidak baca disk berulang)
  static Future<String?> getToken() async {
    if (_tokenLoaded) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    _tokenLoaded = true;
    return _cachedToken;
  }

  /// Ambil data user yang sedang login (di-cache di memori)
  static Future<Map<String, dynamic>?> getUser() async {
    if (_userLoaded) {
      return _cachedUser == null
          ? null
          : Map<String, dynamic>.from(_cachedUser!);
    }
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    _userLoaded = true;
    if (userStr == null) {
      _cachedUser = null;
      return null;
    }
    _cachedUser = jsonDecode(userStr) as Map<String, dynamic>;
    return Map<String, dynamic>.from(_cachedUser!);
  }

  /// Hapus token dan data user saat logout
  static Future<void> clearAuth() async {
    _cachedToken = null;
    _tokenLoaded = true;
    _cachedUser = null;
    _userLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ============================================================
  // HEADER STANDAR (JSON + BEARER TOKEN)
  // ============================================================

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await getToken();
    final isNgrok = baseUrl.toLowerCase().contains('ngrok');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (!kIsWeb) 'Accept-Encoding': 'gzip',
      if (isNgrok) 'ngrok-skip-browser-warning': 'true',
    };
    if (json) headers['Content-Type'] = 'application/json';
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

    final response = await _client
        .get(uri, headers: await _headers(json: false))
        .timeout(_getTimeout);
    return _handleResponse(response);
  }

  /// POST Request (mengirim / membuat data baru)
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _client
        .post(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(_writeTimeout);
    return _handleResponse(response);
  }

  /// PUT Request (memperbarui data)
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _client
        .put(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(_writeTimeout);
    return _handleResponse(response);
  }

  /// PATCH
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _client
        .patch(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(_writeTimeout);
    return _handleResponse(response);
  }

  /// DELETE Request (menghapus data)
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await _client
        .delete(uri, headers: await _headers(json: false))
        .timeout(_getTimeout);
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

    final streamed = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }
  // ============================================================
  // PEMBAYARAN QRIS MIDTRANS
  // ============================================================

  static Future<Map<String, dynamic>> createQrisPayment({
    required String namaPelanggan,
    required String kode,
    required String tipePesanan,
    required double diskonInput,
    required String jenisDiskon,
    required List<Map<String, dynamic>> items,
  }) async {
    return post('transaksi/qris', {
      'nama_pelanggan': namaPelanggan,
      'kode': kode,
      'tipe_pesanan': tipePesanan,
      'diskon_input': diskonInput,
      'jenis_diskon': jenisDiskon,
      'items': items,
    });
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
      final errors = data['errors'];
      if (errors is Map) {
        final details = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toSet()
            .join(' ');
        if (details.isNotEmpty) {
          throw Exception('$message $details');
        }
      }
      throw Exception(message);
    }

    throw Exception('Error (${response.statusCode}): ${response.reasonPhrase}');
  }
}
