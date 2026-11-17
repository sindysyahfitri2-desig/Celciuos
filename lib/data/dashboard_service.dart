import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  // Isi dengan URL ngrok terbaru (pakai https, akhiri dengan /api)
  static const baseUrl = 'https://clatter-distant-sterling.ngrok-free.dev/api';

  Future<Map<String, dynamic>> ambilDashboard(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard'.trim()),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Gagal (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }
}