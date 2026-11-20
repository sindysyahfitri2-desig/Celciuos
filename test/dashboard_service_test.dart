import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/dashboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dashboard summarizes today transactions from the kasir API', () async {
    SharedPreferences.setMockInitialValues({
      'celcious_auth_token': 'test-token',
    });
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    late http.Request capturedRequest;
    ApiService.clientForTesting = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'tanggal': today.add(const Duration(hours: 9)).toIso8601String(),
              'total': '100',
              'status_bayar': 'lunas',
              'metode_pembayaran': {'nama_metode': 'Tunai'},
            },
            {
              'tanggal': today.add(const Duration(hours: 10)).toIso8601String(),
              'total': 200,
              'status_bayar': 'lunas',
              'metode_pembayaran': {'nama_metode': 'QRIS'},
            },
            {
              'tanggal': today.add(const Duration(hours: 11)).toIso8601String(),
              'total': 50,
              'status_bayar': 'belum_lunas',
              'metode_pembayaran': null,
            },
            {
              'tanggal': yesterday
                  .add(const Duration(hours: 12))
                  .toIso8601String(),
              'total': 500,
              'status_bayar': 'lunas',
              'metode_pembayaran': {'nama_metode': 'Tunai'},
            },
          ],
        }),
        200,
      );
    });
    addTearDown(ApiService.resetClientForTesting);

    final dashboard = await DashboardService().ambilDashboard();

    expect(capturedRequest.url.path, '/api/transaksi');
    expect(capturedRequest.headers['authorization'], 'Bearer test-token');
    expect(dashboard['ringkasan'], {
      'omzet_hari_ini': 350.0,
      'total_transaksi': 3,
      'kas_laci': 100.0,
      'total_tunai': 100.0,
    });
    expect(dashboard['distribusi_metode'], [
      {'metode': 'QRIS', 'total_nominal': 200.0},
    ]);
    expect(dashboard['grafik_per_jam'], hasLength(24));
  });
}
